# Vault TLS & PKI Bootstrap Guide

This document describes how we configure HashiCorp Vault end-to-end with Ansible—covering TLS, PKI, and the bridge into Kubernetes/External Secrets. Everything assumes secrets ultimately live in `ansible/secrets.enc` (encrypted with Ansible Vault). During authoring we keep a plaintext `ansible/secrets.noenc` that mirrors the structure below.

## Secret layout

```yaml
vault_tls:
  root_ca_pem: |
    -----BEGIN CERTIFICATE-----
    ...
  server_fullchain_pem: |
    -----BEGIN CERTIFICATE-----
    ...
  server_key_pem: |
    -----BEGIN PRIVATE KEY-----
    ...

vault_bootstrap:
  root_token: hvs.xxx
  unseal_keys: ["key1", "key2", "key3"]  # optional for auto-unseal later

vault_pki:
  role_allowed_domains:
    - home.claydon.co
    - vault.home.lan
  allow_bare_domains: true
  allow_subdomains: true
  allow_wildcard_certificates: true
  k8s_service_account_namespaces:
    - external-secrets
```

Encrypt `secrets.noenc` → `ansible-vault encrypt ansible/secrets.noenc` → becomes `secrets.enc` in production.

## Playbook structure

### `ansible/playbooks/vault.yml`

1. Provision the Proxmox container (already handled).
2. Install Vault and drop TLS material from `vault_tls` onto the host before the service starts:
   - Copy `vault.key` and `vault.crt` (`server_fullchain_pem`) to `/etc/vault.d/tls/`.
   - Save `root_ca_pem` for reference.
   - Ensure the systemd unit uses those paths and notify a handler to restart Vault if they change.

### `ansible/playbooks/vault-pki-setup.yml`

Split into two modes:

#### Bootstrap mode (first run)
- Enable `pki_homelab` if not present.
- Upload the existing root CA:
  ```yaml
  vault write pki_homelab/config/ca pem_bundle="{{ vault_tls.root_ca_pem }}"
  ```
- Issue the Vault HTTPS cert from Ansible vars (optional) and install it on the host.
- Seed Vault KV for GitOps:
  ```yaml
  vault kv put secrets/platform/vault-root-ca ca_crt="{{ vault_tls.root_ca_pem }}"
  vault kv put secrets/platform/vault-server-ca ca_crt="{{ vault_tls.server_fullchain_pem }}"
  ```
- Template the ClusterSecretStore manifest using the new root CA.

#### Maintenance mode (subsequent runs)
- Skip root generation if `vault_tls.root_ca_pem` is defined.
- Rotate the server cert if `vault_tls.server_fullchain_pem` changes—overwrite `/etc/vault.d/tls` and restart Vault.

### Kubernetes integration

Use the same playbook to:
- Update the PKI role with values from `vault_pki`.
- Configure Kubernetes auth (`vault write auth/kubernetes/config ...`).
- Create the ESO policy/role per namespace in `vault_pki.k8s_service_account_namespaces`.

### GitOps alignment

- `k3s/platform/ssl-certificates/05-ca-configmap.yaml` reads the root CA from Vault KV (`platform/vault-root-ca`) and produces `vault-ca` Secrets in each namespace.
- ClusterSecretStores (`vault-kv`, `vault-pki`, `vault-k8s-auth`) expect `caProvider.type: Secret`.
- External Secrets Operator chart mounts that Secret and exports `VAULT_CACERT`—no more manual patches.

## Bootstrap workflow

1. Populate `ansible/secrets.noenc`; encrypt to `secrets.enc` when ready.
2. Run `ansible-playbook ansible/playbooks/vault.yml` (provision + TLS install).
3. Run `ansible-playbook ansible/playbooks/vault-pki-setup.yml` (PKI bootstrap, Vault policies, templated ClusterSecretStore).
4. Commit the updated manifests and sync Argo.
5. Annotate ExternalSecrets to refresh.

## Maintenance / rotation

- Update certs in `secrets.enc` and re-run the playbooks. Vault restarts with the new TLS bundle; `vault-root-ca` Secret propagates through GitOps automatically.
- Periodically check ESO logs and `kubectl get externalsecret -A` to confirm everything stays healthy.

