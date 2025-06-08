# k3s_argocd_setup

This Ansible role installs and configures ArgoCD on a k3s cluster with proper TLS integration using Vault and cert-manager.

## Overview

The role performs the following tasks:
- Creates the ArgoCD namespace
- Downloads and installs the ArgoCD Helm chart
- Configures ArgoCD with Traefik ingress
- Sets up TLS certificates using cert-manager and Vault
- Configures ArgoCD to sync applications from a Git repository

## Prerequisites

Before using this role, ensure the following components are installed and configured:

1. **k3s Cluster**: A functioning k3s cluster must be available
2. **cert-manager**: Must be installed and configured in the cluster
3. **Vault**: Must be configured and integrated with cert-manager
4. **vault-selfsigned-issuer**: A ClusterIssuer must be configured to use Vault for certificate issuance
5. **Traefik**: Should be configured as the ingress controller

## Role Variables

The following variables can be customized in your playbook:

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `argocd_release_name` | Name of the ArgoCD release | `argocd` |
| `argocd_namespace` | Namespace where ArgoCD will be installed | `argocd` |
| `argocd_chart_version` | Version of the ArgoCD Helm chart | `7.8.20` |
| `argocd_domain` | Domain name for ArgoCD ingress | `argocd.home.lan` |
| `argocd_repo_url` | Git repository URL for ArgoCD to sync from | `https://github.com/rikdc/home-network-config` |
| `argocd_repo_revision` | Git branch or tag to sync from | `main` |
| `argocd_tls_enabled` | Whether to enable TLS for ArgoCD | `true` |
| `argocd_tls_secret_name` | Name of the TLS secret | `argocd-tls` |

## TLS Configuration

This role configures ArgoCD with TLS using the following components:

1. **cert-manager**: Used to manage TLS certificates
2. **vault-selfsigned-issuer**: A ClusterIssuer that integrates with Vault for certificate issuance
3. **Traefik**: Configured to use the `websecure` entrypoint for TLS termination

The ingress is configured with the following annotations:
- `kubernetes.io/ingress.class: traefik`
- `traefik.ingress.kubernetes.io/router.entrypoints: websecure`
- `traefik.ingress.kubernetes.io/router.tls: "true"`
- `cert-manager.io/cluster-issuer: vault-selfsigned-issuer`

## Usage

Include this role in your playbook:

```yaml
- hosts: k3s_controller
  become: true
  roles:
    - role: k3s_argocd_setup
      vars:
        argocd_domain: argocd.example.com
        argocd_repo_url: https://github.com/yourusername/your-repo
        argocd_repo_revision: main
```

## Troubleshooting

### Certificate Issues

If you encounter certificate issues:

1. Check if the `vault-selfsigned-issuer` ClusterIssuer is properly configured:
   ```bash
   kubectl get clusterissuer vault-selfsigned-issuer -o yaml
   ```

2. Verify the Certificate resource was created:
   ```bash
   kubectl get certificate -n argocd
   ```

3. Check certificate events:
   ```bash
   kubectl describe certificate argocd-tls -n argocd
   ```

### ArgoCD Not Accessible

If ArgoCD is not accessible:

1. Check if the ArgoCD pods are running:
   ```bash
   kubectl get pods -n argocd
   ```

2. Verify the ingress is properly configured:
   ```bash
   kubectl get ingress -n argocd
   kubectl describe ingress -n argocd
   ```

3. Check if the TLS secret exists:
   ```bash
   kubectl get secret argocd-tls -n argocd
   ```

4. Examine the Traefik logs:
   ```bash
   kubectl logs -n kube-system -l app.kubernetes.io/name=traefik
   ```

### Sync Issues

If ArgoCD is not syncing applications:

1. Check the ArgoCD application status:
   ```bash
   kubectl get applications -n argocd
   ```

2. Verify the Git repository is accessible:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server
