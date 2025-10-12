# SSL Certificate Setup with HashiCorp Vault PKI

This document covers the implementation of SSL certificates for the home.claydon.co domain using HashiCorp Vault PKI and Traefik ingress controller.

## Overview

The SSL certificate setup provides HTTPS access to services using:
- HashiCorp Vault PKI for certificate generation
- Wildcard certificates for *.home.claydon.co and home.claydon.co
- Traefik as the ingress controller with TLS termination
- Self-signed root CA for internal use

## Architecture

```
Browser → DNS → Traefik (SSL termination) → K8s Service → Pod
                    ↓
            Vault PKI Certificate
            (*.home.claydon.co)
```

## Implementation Steps Completed

### 1. Vault PKI Configuration Verification

The Vault PKI backend was already configured with:
- Root CA: "Home Lab Root CA"
- PKI role: "home-claydon-co"
- Certificate validity: 8760h (1 year)
- Allowed domains: home.claydon.co, *.home.claydon.co

### 2. External Secrets Operator Issues Resolved

**Problem**: External Secrets were failing with certificate verification errors.

**Root Cause**: External Secrets configured to connect to 192.168.88.6:8200 but Vault certificate only valid for 192.168.88.43 and 192.168.88.1.

**Solution**: Updated External Secrets to use hostname `vault.home.lan` instead of IP address.

### 3. Manual Certificate Generation Approach

Due to persistent Kubernetes authentication issues with Vault, implemented manual certificate generation:

```bash
# Generate certificate from Vault PKI
curl -k -H "X-Vault-Token: $VAULT_TOKEN" \
  -X POST https://vault.home.lan:8200/v1/pki_homelab/issue/home-claydon-co \
  -d '{"common_name": "*.home.claydon.co", "alt_names": "home.claydon.co", "ttl": "8760h"}'
```

### 4. Kubernetes TLS Secret Creation

Created TLS secrets in multiple namespaces:

```bash
# Create TLS secret from certificate files
kubectl create secret tls wildcard-home-claydon-co-tls \
  --cert=fullchain.pem \
  --key=private.key \
  -n tools

kubectl create secret tls wildcard-home-claydon-co-tls \
  --cert=fullchain.pem \
  --key=private.key \
  -n kube-system
```

### 5. Traefik TLS Configuration

Configured Traefik TLSStore for default certificate:

```yaml
apiVersion: traefik.io/v1alpha1
kind: TLSStore
metadata:
  name: default
  namespace: kube-system
spec:
  defaultCertificate:
    secretName: wildcard-home-claydon-co-tls
```

### 6. Ingress Configuration

Example SSL-enabled ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: open-webui-ssl-test
  namespace: tools
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  rules:
  - host: chat.home.claydon.co
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: open-webui
            port:
              name: http
  tls:
  - hosts:
    - chat.home.claydon.co
    secretName: wildcard-home-claydon-co-tls
```

## Troubleshooting Issues Encountered

### Certificate Format Issues

**Problem**: Traefik logs showing "failed to find any PEM data in certificate input"

**Cause**: Malformed certificate chain with missing newlines between certificates

**Solution**: Recreated certificate with proper PEM formatting:
```
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
```

### Certificate/Key Mismatch

**Problem**: "private key does not match public key" error

**Cause**: Certificate and private key generated in separate API calls

**Solution**: Generated certificate and key in single Vault API call to ensure matching pair

### SSL Name Recognition Error

**Problem**: Browser showing "SSL_ERROR_UNRECOGNIZED_NAME_ALERT"

**Cause**: Certificate missing required Subject Alternative Names

**Solution**: Included both `*.home.claydon.co` and `home.claydon.co` in certificate:
```json
{
  "common_name": "*.home.claydon.co",
  "alt_names": "home.claydon.co",
  "ttl": "8760h"
}
```

## Certificate Details

The current certificate includes:
- **Common Name**: *.home.claydon.co
- **Subject Alternative Names**:
  - DNS: *.home.claydon.co
  - DNS: home.claydon.co
- **Validity**: 1 year
- **Key Type**: EC (Elliptic Curve)
- **Issuer**: Home Lab Root CA

## Verification Commands

```bash
# Test HTTPS connection
curl -k -I https://chat.home.claydon.co

# Check certificate details
echo | openssl s_client -connect chat.home.claydon.co:443 \
  -servername chat.home.claydon.co 2>/dev/null | \
  openssl x509 -noout -text | grep -A 2 "Subject Alternative Name"

# Verify certificate chain
kubectl get secret wildcard-home-claydon-co-tls -n tools \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | \
  openssl x509 -noout -subject -issuer
```

## Security Considerations

1. **Self-Signed CA**: The root CA is self-signed and must be installed on client devices for full trust
2. **Certificate Rotation**: Certificates expire after 1 year and require manual renewal
3. **Private Key Security**: Private keys are stored in Kubernetes secrets
4. **Vault Token Management**: Vault tokens used for certificate generation should be rotated regularly

## Current Status

✅ **Completed**:
- SSL certificate generation from Vault PKI
- Traefik TLS termination configuration
- Wildcard certificate with proper SANs
- HTTPS access to chat.home.claydon.co working

⏳ **Pending**:
- DNS configuration for home.claydon.co domain
- Root CA installation on client devices
- Automated certificate renewal process
- Update remaining ingresses to use new SSL domain

## Files Modified

- Created: `/tmp/traefik-tls-store.yaml` - Traefik TLSStore configuration
- Created: `/tmp/test-ssl-ingress.yaml` - Test ingress for SSL verification
- Updated: External Secrets configurations to use vault.home.lan hostname
- Created: TLS secrets in `tools` and `kube-system` namespaces

## Infrastructure as Code Deployment

The SSL certificate configuration has been fully automated using Infrastructure as Code principles:

### Prerequisites

1. **Vault Setup**: Ensure HashiCorp Vault is running and accessible
2. **Kubernetes Cluster**: k3s cluster with External Secrets Operator installed
3. **Ansible**: Ansible with required collections installed
4. **ArgoCD**: ArgoCD installed for GitOps deployment (recommended)

### Deployment Steps

#### 1. Configure Vault PKI (One-time setup)

```bash
# Run Ansible playbook to configure Vault PKI
ansible-playbook ansible/playbooks/vault-pki-setup.yml

# With custom variables
ansible-playbook ansible/playbooks/vault-pki-setup.yml \
  -e ssl_domain=example.com \
  -e ssl_subdomain=home.example.com \
  -e k8s_api_server=https://10.0.0.100:6443
```

This playbook will:
- Configure Vault PKI secrets engine
- Create certificate role for your domain
- Set up Kubernetes authentication
- Generate ClusterSecretStore with secure CA bundle
- Save root CA certificate (not committed to git)

#### 2. Deploy SSL Certificate Platform

**Option A: Manual kubectl deployment**
```bash
# Apply in order (respects ArgoCD sync waves)
kubectl apply -f k3s/platform/ssl-certificates/00-namespace.yaml
kubectl apply -f k3s/platform/ssl-certificates/01-cluster-secret-store.yaml
kubectl apply -f k3s/platform/ssl-certificates/02-vault-dynamic-secret.yaml
kubectl apply -f k3s/platform/ssl-certificates/03-external-secret.yaml
kubectl apply -f k3s/platform/ssl-certificates/04-tls-secrets-distribution.yaml
kubectl apply -f k3s/platform/ssl-certificates/05-ca-configmap.yaml
```

**Option B: ArgoCD deployment (recommended)**
```bash
# Update the repo URL in argocd-app.yaml first
kubectl apply -f k3s/platform/ssl-certificates/argocd-app.yaml
```

#### 3. Update DNS Configuration

```bash
# Apply CoreDNS custom configuration
kubectl apply -f k3s/platform/coredns/05-dns-home-claydon-co.yaml

# Or update Blocky DNS configuration via Ansible
ansible-playbook ansible/playbooks/dns.yml
```

#### 4. Update Application Ingresses

Applications have been updated to use SSL:
- **OpenWebUI**: https://chat.home.claydon.co
- **Docmost**: https://docs.home.claydon.co
- **n8n**: https://n8n.home.claydon.co
- **CA Site**: https://ca.home.claydon.co

#### 5. Enable Monitoring

```bash
# Deploy certificate monitoring
kubectl apply -f k3s/system/ssl-monitoring/cert-expiry-monitor.yaml
```

### Security Features

✅ **Secure CA Bundle**: Not committed to git, generated dynamically
✅ **Template-based Configuration**: Variables for different environments
✅ **Multi-namespace Distribution**: Certificates available where needed
✅ **Automated Renewal**: External Secrets handles certificate lifecycle
✅ **Monitoring**: Daily certificate expiry checks
✅ **GitOps Ready**: Full ArgoCD integration with sync waves

### File Structure

```
k3s/platform/ssl-certificates/
├── 00-namespace.yaml               # Namespaces
├── 01-cluster-secret-store.yaml    # Generated with CA bundle
├── 02-vault-dynamic-secret.yaml    # Certificate generation
├── 03-external-secret.yaml         # TLS secret creation
├── 04-tls-secrets-distribution.yaml # Multi-namespace distribution
├── 05-ca-configmap.yaml            # CA certificate distribution
├── argocd-app.yaml                 # ArgoCD application
├── templates/
│   ├── cluster-secret-store.yaml.j2 # Ansible template
│   └── ingress-ssl-template.yaml   # SSL ingress template
└── README.md                       # Detailed documentation

ansible/
├── playbooks/vault-pki-setup.yml   # Vault PKI configuration
└── inventory/group_vars/vault_pki.yml # PKI variables
```

### Troubleshooting

#### Certificate Generation Issues
```bash
# Check External Secrets status
kubectl get externalsecret -A
kubectl describe externalsecret wildcard-home-claydon-co-tls -n ssl-certificates

# Check ClusterSecretStore
kubectl describe clustersecretstore vault-k8s-auth

# Check External Secrets logs
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets
```

#### SSL Connection Issues
```bash
# Test certificate endpoints
curl -k -I https://chat.home.claydon.co
openssl s_client -connect chat.home.claydon.co:443 -servername chat.home.claydon.co

# Check certificate expiry
kubectl run cert-check --rm -i --tty --image=alpine/k8s:1.28.2 -- \
  /bin/sh /scripts/check-certs.sh
```

### Variables Reference

**Ansible Variables** (in `ansible/inventory/group_vars/vault_pki.yml`):
- `vault_server_url`: Vault server URL
- `k8s_api_server`: Kubernetes API server URL
- `ssl_domain`: Primary domain (e.g., claydon.co)
- `ssl_subdomain`: Subdomain (e.g., home.claydon.co)
- `certificate_ttl`: Certificate validity period
- `ca_certificate_ttl`: Root CA validity period

## Next Steps

1. ✅ **Deployment**: Follow IaC deployment steps above
2. ✅ **DNS**: Configure DNS for home.claydon.co domain
3. ✅ **Applications**: Update remaining app ingresses for SSL
4. ✅ **Monitoring**: Certificate expiry monitoring enabled
5. 🔄 **CA Installation**: Install root CA on client devices for full trust
6. 🔄 **Documentation**: Update runbooks and operational procedures

## Reference

- Vault PKI Secrets Engine: https://developer.hashicorp.com/vault/docs/secrets/pki
- Traefik TLS Configuration: https://doc.traefik.io/traefik/https/tls/
- Kubernetes TLS Secrets: https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets
