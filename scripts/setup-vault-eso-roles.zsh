#!/usr/bin/env zsh
set -euo pipefail

# Purpose: Create/refresh Vault policies and Kubernetes auth roles for ESO.
# - Creates KV policy/role (eso-kv) for KV v2 at mount `secrets` (default)
# - Creates PKI policy/role (eso-pki) for PKI at mount `pki_homelab` (default)
# - Binds roles to the ESO ServiceAccount in the ESO namespace
# Idempotent: safe to re-run.

# Configurable via env vars
: ${VAULT_ADDR:="https://vault.home.lan:8200"}
: ${VAULT_TOKEN:=""}

# Kubernetes auth mount path in Vault
: ${K8S_AUTH_MOUNT:="kubernetes"}

# ESO ServiceAccount and namespace bounds
: ${ESO_NS:="external-secrets"}
: ${ESO_SA:="external-secrets"}

# KV v2 settings
: ${KV_MOUNT:="secrets"}
: ${KV_POLICY:="eso-kv-policy"}
: ${KV_ROLE:="eso-kv"}

# PKI settings
: ${PKI_MOUNT:="pki_homelab"}
: ${PKI_POLICY:="eso-pki-policy"}
: ${PKI_ROLE:="eso-pki"}

err() { echo "[ERROR] $*" >&2; }
log() { echo "[INFO] $*"; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || { err "Missing required command: $1"; exit 1; }; }

require_cmd vault

if [[ -z "${VAULT_TOKEN}" ]]; then
  err "VAULT_TOKEN is not set. Export an admin token before running."
  exit 1
fi

export VAULT_ADDR
export VAULT_TOKEN

log "Using Vault at: $VAULT_ADDR"
log "ESO bounds: SA='$ESO_SA' NS='$ESO_NS' via auth mount '$K8S_AUTH_MOUNT'"

# Ensure auth mount exists
if ! vault auth list -format=json | grep -q '"'${K8S_AUTH_MOUNT}'/"'; then
  log "Enabling Kubernetes auth at '${K8S_AUTH_MOUNT}'..."
  vault auth enable -path="$K8S_AUTH_MOUNT" kubernetes
else
  log "Kubernetes auth mount '${K8S_AUTH_MOUNT}' already enabled."
fi

log "Writing KV policy '$KV_POLICY' for mount '$KV_MOUNT'..."
vault policy write "$KV_POLICY" - <<EOF
path "${KV_MOUNT}/data/*" {
  capabilities = ["read"]
}
path "${KV_MOUNT}/metadata/*" {
  capabilities = ["read", "list"]
}
EOF

log "Writing PKI policy '$PKI_POLICY' for mount '$PKI_MOUNT'..."
vault policy write "$PKI_POLICY" - <<EOF
path "${PKI_MOUNT}/issue/*" {
  capabilities = ["create", "update"]
}
path "${PKI_MOUNT}/cert/ca" {
  capabilities = ["read"]
}
EOF

log "Creating/Updating KV role '$KV_ROLE'..."
vault write "auth/${K8S_AUTH_MOUNT}/role/${KV_ROLE}" \
  bound_service_account_names="${ESO_SA}" \
  bound_service_account_namespaces="${ESO_NS}" \
  policies="${KV_POLICY}" \
  ttl=24h

log "Creating/Updating PKI role '$PKI_ROLE'..."
vault write "auth/${K8S_AUTH_MOUNT}/role/${PKI_ROLE}" \
  bound_service_account_names="${ESO_SA}" \
  bound_service_account_namespaces="${ESO_NS}" \
  policies="${PKI_POLICY}" \
  ttl=24h

log "Verifying roles/policies..."
vault policy read "$KV_POLICY" >/dev/null
vault policy read "$PKI_POLICY" >/dev/null
vault read -format=json "auth/${K8S_AUTH_MOUNT}/role/${KV_ROLE}" >/dev/null
vault read -format=json "auth/${K8S_AUTH_MOUNT}/role/${PKI_ROLE}" >/dev/null

log "All set: policies and roles are in place."

