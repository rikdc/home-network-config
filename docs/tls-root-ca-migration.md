# Migrating Vault TLS Trust to the Home Lab Root CA

This guide explains how to move the cluster from trusting the self-signed Vault server certificate to trusting the **Home Lab Root CA**. It assumes you already have External Secrets Operator (ESO) deployed and the `vault-kv`/`vault-k8s-auth` stores working.

## Why migrate?

- **Self-signed leaf (current state)**: every TLS client must be updated whenever the Vault server certificate rotates.
- **Root CA (target state)**: clients trust the long-lived root. Vault can rotate its leaf certificates without touching Kubernetes.

## High-level flow

1. Export the Home Lab Root CA from Vault.
2. Store that root certificate in Vault KV (GitOps-controlled path).
3. Update ExternalSecret manifests so every namespace receives the root CA (`vault-ca` Secret).
4. Re-issue the Vault HTTPS certificate from the PKI backend so it chains to the root, and restart Vault with the new cert/key.
5. Refresh ESO and workload secrets; verify TLS trust and certificate chains.

## Prerequisites

- Access to Vault CLI with a token that can read `pki_homelab` and write to `secrets/platform`.
- Access to the Vault server filesystem (or automation) to install a new TLS certificate.
- `kubectl` access to the cluster running ESO.

## Step-by-step

### 1. Export the Home Lab Root CA

```bash
VAULT_ADDR=https://vault.home.lan:8200
vault read -field=certificate pki_homelab/cert/ca > /tmp/home-lab-root-ca.pem
openssl x509 -in /tmp/home-lab-root-ca.pem -noout -subject -issuer
```

Keep the PEM file around for later validation.

### 2. Store the root in Vault KV for GitOps

```bash
vault kv put secrets/platform/vault-root-ca ca_crt=@/tmp/home-lab-root-ca.pem
```

The GitOps manifests (`k3s/platform/ssl-certificates/05-ca-configmap.yaml`) will read this secret and create `vault-ca` Secrets in every namespace.

### 3. Update GitOps manifests

1. In `k3s/platform/ssl-certificates/05-ca-configmap.yaml`, ensure each ExternalSecret pulls `platform/vault-root-ca` instead of the self-signed leaf.
2. In `k3s/platform/external-secrets/values.yaml`, keep the `vault-ca` Secret mounted (`extraVolumes`), pointing `VAULT_CACERT` to `/etc/vault/tls/ca.crt`.
3. Commit and deploy via ArgoCD (or `kubectl apply`) once Vault runs with the new cert (next step).

### 4. Re-issue the Vault HTTPS certificate

1. Issue a new leaf signed by the root:
   ```bash
   vault write pki_homelab/issue/home-claydon-co      common_name="vault.home.lan"      alt_names="vault.home.lan,api.internal.home.lan"      ip_sans="192.168.88.6"      ttl="2160h" > /tmp/vault-leaf.json
   jq -r '.data.certificate' /tmp/vault-leaf.json > /tmp/vault.crt
   jq -r '.data.issuing_ca' /tmp/vault-leaf.json > /tmp/vault_issuing_ca.pem
   jq -r '.data.private_key' /tmp/vault-leaf.json > /tmp/vault.key
   cat /tmp/vault.crt /tmp/vault_issuing_ca.pem > /tmp/vault-fullchain.pem
   ```
2. Install the cert/key on the Vault host (paths depend on your deployment, e.g. `/etc/vault.d/tls/vault.crt` & `/etc/vault.d/tls/vault.key`).
3. Restart Vault so the new certificate takes effect.

### 5. Refresh Kubernetes Secrets

```bash
for ns in external-secrets kube-system tools networking argocd ssl-certificates; do
  kubectl annotate externalsecret vault-ca -n "$ns"     external-secrets.io/refresh="$(date +%s)" --overwrite || true
done
for ns in ssl-certificates kube-system tools networking argocd; do
  kubectl annotate externalsecret wildcard-home-claydon-co-tls${ns:+-$(basename "$ns")}     -n "$ns" external-secrets.io/refresh="$(date +%s)" --overwrite || true
done
```

### 6. Validate

- `kubectl get externalsecret -A` → all `Ready=True`.
- `kubectl logs -n external-secrets deploy/external-secrets` → no TLS errors.
- Verify the Vault cert chain:
  ```bash
  openssl s_client -connect vault.home.lan:8200 -servername vault.home.lan </dev/null     | openssl x509 -noout -subject -issuer
  ```
  Issuer should be `Home Lab Root CA`.
- Spot-check workloads (Traefik, docmost) to confirm they receive the new wildcard certificate.

### 7. Clean-up & future rotations

- Rotate the Vault server certificate by issuing a new leaf from `pki_homelab` and replacing the TLS files—no Kubernetes changes required.
- Keep the root key/cert safe (offline backup).

## Troubleshooting

- **"tls: failed to verify certificate"** — ensure the root CA Secret (`vault-ca`) contains the correct PEM and ESO pod has restarted with the mount.
- **SAN not allowed** — update the Vault role (`vault write pki_homelab/roles/home-claydon-co ... allowed_domains+=...`).
- **403 permission denied** — the `vault-k8s-auth` role must be bound to the namespace/service account requesting secrets.

## Change control

When ready, submit a PR with:
- Updated `k3s/platform/ssl-certificates/05-ca-configmap.yaml`
- Any related Helm value tweaks
- This guide documenting the migration

Deploy via ArgoCD, then follow the rollout steps above.
