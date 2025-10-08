#!/usr/bin/env zsh
set -euo pipefail

# Purpose: Configure Vault Kubernetes auth for External Secrets Operator (ESO)
# Safe, idempotent, and uses current kubeconfig API server URL.
#
# Defaults can be overridden via environment variables before running, e.g.:
#   VAULT_ADDR=https://vault.home.lan:8200 VAULT_TOKEN=s.xxxx ./scripts/setup-vault-eso-k8s-auth.zsh
#   ESO_NS=external-secrets ESO_SA=external-secrets ./scripts/setup-vault-eso-k8s-auth.zsh
#   ALLOWED_NAMESPACES="external-secrets,external-secrets-system" ./scripts/setup-vault-eso-k8s-auth.zsh

### Configurable vars (env overrides)
: ${VAULT_ADDR="https://vault.home.lan:8200"}
: ${VAULT_TOKEN=""}
: ${ESO_NS="external-secrets"}
: ${ESO_SA="external-secrets"}
: ${ROLE_NAME="eso"}
: ${POLICY_NAME="eso-pki-policy"}
# Comma-separated namespaces for role binding. Default to ESO_NS only.
: ${ALLOWED_NAMESPACES="$ESO_NS"}

# When set to 1, curl will use -k for the manual login test (ignores Vault cert trust issues on the client machine)
: ${CURL_INSECURE:=1}

### Helpers
err() { echo "[ERROR] $*" >&2; }
log() { echo "[INFO] $*"; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || { err "Missing required command: $1"; exit 1; }; }

### Pre-flight checks
require_cmd kubectl
require_cmd vault
require_cmd sed
if [[ ${CURL_INSECURE} -eq 1 ]]; then require_cmd curl; fi

if [[ -z "${VAULT_TOKEN}" ]]; then
  err "VAULT_TOKEN is not set. Export an admin/root token before running."
  exit 1
fi

log "Using Vault at: ${VAULT_ADDR}"
log "Configuring ESO role '${ROLE_NAME}' for SA '${ESO_SA}' in namespace(s): ${ALLOWED_NAMESPACES}"

### Create temp workspace
WORKDIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'vault-eso')
cleanup() { rm -rf "$WORKDIR" || true; }
trap cleanup EXIT

### Derive Kubernetes API server and CA from current kubeconfig
log "Discovering Kubernetes API server from kubeconfig..."
K8S_API=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null || true)
if [[ -z "${K8S_API}" ]]; then
  err "Unable to determine Kubernetes API server URL from kubeconfig."
  exit 1
fi
echo -n "$K8S_API" > "$WORKDIR/k8s-api.txt"
log "Kubernetes API: $K8S_API"

log "Fetching Kubernetes cluster CA..."
kubectl -n kube-system get cm kube-root-ca.crt -o jsonpath='{.data.ca\.crt}' > "$WORKDIR/k8s-ca.crt"

### Prepare token reviewer SA + binding (idempotent)
log "Ensuring token reviewer ServiceAccount exists..."
if ! kubectl -n kube-system get sa vault-auth >/dev/null 2>&1; then
  kubectl -n kube-system create sa vault-auth
else
  log "ServiceAccount kube-system/vault-auth already exists."
fi

log "Ensuring clusterrolebinding for token review exists..."
if ! kubectl get clusterrolebinding vault-auth-delegator >/dev/null 2>&1; then
  kubectl create clusterrolebinding vault-auth-delegator \
    --clusterrole=system:auth-delegator \
    --serviceaccount=kube-system:vault-auth
else
  log "ClusterRoleBinding vault-auth-delegator already exists."
fi

log "Minting a token for the token reviewer SA..."
kubectl -n kube-system create token vault-auth > "$WORKDIR/vault-reviewer.jwt"

### Enable and configure Vault Kubernetes auth
export VAULT_ADDR
export VAULT_TOKEN

log "Ensuring Vault Kubernetes auth method is enabled..."
if ! vault auth list -format=json | sed -n '1,200p' >/dev/null 2>&1; then
  err "Unable to list Vault auth methods. Check VAULT_ADDR/VAULT_TOKEN and network connectivity."
  exit 1
fi

if ! vault auth list -format=json | grep -q '"kubernetes/"'; then
  vault auth enable kubernetes
  log "Enabled kubernetes auth method."
else
  log "Kubernetes auth method already enabled."
fi

log "Configuring Vault auth/kubernetes/config..."
vault write auth/kubernetes/config \
  kubernetes_host="$(cat "$WORKDIR/k8s-api.txt")" \
  kubernetes_ca_cert=@"$WORKDIR/k8s-ca.crt" \
  token_reviewer_jwt=@"$WORKDIR/vault-reviewer.jwt"

log "Writing ESO policy '${POLICY_NAME}' (PKI access)..."
vault policy write "$POLICY_NAME" - <<'EOF'
path "pki_homelab/issue/*" {
  capabilities = ["create", "update"]
}
path "pki_homelab/cert/ca" {
  capabilities = ["read"]
}
EOF

log "Creating/Updating role '${ROLE_NAME}' bound to SA '${ESO_SA}' in namespaces '${ALLOWED_NAMESPACES}'..."
vault write auth/kubernetes/role/"${ROLE_NAME}" \
  bound_service_account_names="${ESO_SA}" \
  bound_service_account_namespaces="${ALLOWED_NAMESPACES}" \
  policies="${POLICY_NAME}" \
  ttl=24h

log "Verifying Vault configuration..."
vault read -format=json auth/kubernetes/config >/dev/null
vault read -format=json auth/kubernetes/role/"${ROLE_NAME}" >/dev/null
log "Vault Kubernetes auth configured successfully."

### Optional end-to-end login test using a minted SA token
log "Testing login flow with a minted ServiceAccount token for ${ESO_NS}/${ESO_SA}..."
ESO_JWT_FILE="${WORKDIR}/eso.jwt"
if kubectl -n "${ESO_NS}" get sa "${ESO_SA}" >/dev/null 2>&1; then
  kubectl -n "${ESO_NS}" create token "${ESO_SA}" > "${ESO_JWT_FILE}"
  if [[ -s "${ESO_JWT_FILE}" ]]; then
    CURL_FLAGS=(--silent --show-error --fail)
    if [[ ${CURL_INSECURE} -eq 1 ]]; then CURL_FLAGS=(-k ${CURL_FLAGS[@]}); fi
    LOGIN_RESP=$(curl ${CURL_FLAGS[@]} -X POST "${VAULT_ADDR}/v1/auth/kubernetes/login" \
      -H 'Content-Type: application/json' \
      -d "{ \"role\": \"${ROLE_NAME}\", \"jwt\": \"$(sed -e 's/\n//g' < "${ESO_JWT_FILE}")\" }" || true)
    if echo "$LOGIN_RESP" | grep -q '"auth"'; then
      log "Login successful. ESO should authenticate successfully."
    else
      err "Login test failed. Response: ${LOGIN_RESP}"
      err "Common causes: namespace/SA mismatch, wrong API host/CA, or Vault cert trust if CURL_INSECURE=0."
      exit 1
    fi
  else
    err "Failed to mint a token for ${ESO_NS}/${ESO_SA}. Check Kubernetes version/permissions."
    exit 1
  fi
else
  err "ServiceAccount ${ESO_NS}/${ESO_SA} not found. Ensure External Secrets Operator is installed and using this SA."
  exit 1
fi

log "All done. Verify ClusterSecretStore status and ESO logs next:"
echo "  kubectl describe clustersecretstore vault-k8s-auth"
echo "  kubectl -n ${ESO_NS} logs -l app.kubernetes.io/name=external-secrets"
