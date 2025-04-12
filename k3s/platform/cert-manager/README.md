# Cert-Manager Setup

This directory contains the Helm chart configuration for cert-manager deployment in the k3s cluster, integrated with HashiCorp Vault for certificate management.

## Components

- **cert-manager**: Certificate management controller
- **ClusterIssuer**: Uses Vault PKI for certificate issuance
- **Default Certificate**: Wildcard certificate for *.home.lan
- **Monitoring**: Prometheus ServiceMonitor and alerts

## Vault PKI Setup

### 1. Enable and Configure PKI Engine

```bash
# Enable PKI secrets engine
vault secrets enable -path=pki_homelab pki

# Configure max lease TTL to 10 years
vault secrets tune -max-lease-ttl=87600h pki_homelab

# Create root CA
vault write -field=certificate pki_homelab/root/generate/internal \
    common_name="Home Lab Root CA" \
    ttl=87600h \
    key_bits=4096 \
    > root_ca.crt

# Configure CA and CRL URLs
vault write pki_homelab/config/urls \
    issuing_certificates="https://vault.home.lan:8200/v1/pki_homelab/ca" \
    crl_distribution_points="https://vault.home.lan:8200/v1/pki_homelab/crl"

# Generate intermediate CSR
vault write -format=json pki_homelab/intermediate/generate/internal \
    common_name="Home Lab Intermediate CA" \
    ttl=43800h \
    key_bits=4096 \
    | jq -r '.data.csr' > intermediate.csr

# Sign intermediate with root CA
vault write -format=json pki_homelab/root/sign-intermediate \
    csr=@intermediate.csr \
    format=pem_bundle \
    ttl=43800h \
    | jq -r '.data.certificate' > intermediate.cert.pem

# Import signed certificate
vault write pki_homelab/intermediate/set-signed \
    certificate=@intermediate.cert.pem
```

### 2. Create Role for cert-manager

```bash
# Create role for issuing certificates
vault write pki_homelab/roles/cert-manager \
    allowed_domains="home.lan" \
    allow_subdomains=true \
    allow_glob_domains=true \
    max_ttl="2160h" \
    require_cn=false \
    allow_any_name=true \
    enforce_hostnames=false
```

### 3. Configure Vault Policy

```hcl
# cert-manager-policy.hcl
path "pki_homelab/sign/cert-manager" {
    capabilities = ["create", "update"]
}

path "pki_homelab/issue/cert-manager" {
    capabilities = ["create"]
}

path "pki_homelab/cert/ca" {
    capabilities = ["read"]
}

path "pki_homelab/ca_chain" {
    capabilities = ["read"]
}
```

Apply the policy:
```bash
vault policy write cert-manager-policy cert-manager-policy.hcl
```

### 4. Configure Authentication

Since Vault is running on a separate machine from K3s, follow these steps:

1. On your K3s cluster, create the necessary resources:
```bash
# Create namespace
kubectl create namespace cert-manager

# Create service account and role binding
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth
  namespace: cert-manager
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: cert-manager
EOF

# Get the K3s controller's actual IP or hostname
# DO NOT use 127.0.0.1 or localhost as Vault needs to reach the API server
# Replace this with your actual K3s controller IP or hostname
K3S_URL="https://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):6443"

# Verify the K3s URL is not using localhost
if [[ "$K3S_URL" == *"127.0.0.1"* ]] || [[ "$K3S_URL" == *"localhost"* ]]; then
    echo "Error: K3s URL ($K3S_URL) is using localhost. Please use the actual IP or hostname."
    exit 1
fi

# Get the service account token
TOKEN=$(kubectl create token vault-auth -n cert-manager)

# Get the K3s CA certificate
# Note: The certificate will be in PEM format after base64 decode
CA_CERT=$(kubectl config view --raw --minify --flatten \
    --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 -d)

# Verify the CA certificate format
if ! echo "$CA_CERT" | grep -q "BEGIN CERTIFICATE"; then
    echo "Error: CA certificate is not in PEM format"
    exit 1
fi

# Save these to files (optional, for reference)
echo "$K3S_URL" > k3s-api-url.txt
echo "$TOKEN" > vault-auth-token.txt
echo "$CA_CERT" > k3s-ca.crt

# Display certificate information (optional)
echo "CA Certificate details:"
echo "$CA_CERT" | openssl x509 -noout -text | grep "Subject:"

# Display the K3s URL for verification
echo "K3s URL for Vault configuration: $K3S_URL"
```

2. On the Vault server, configure Kubernetes authentication:
```bash
# Enable kubernetes auth if not already enabled
vault auth enable kubernetes
# Save CA cert to a temporary file
echo "$CA_CERT" > /tmp/k3s-ca.crt

# Configure Kubernetes auth using the temporary file
vault write auth/kubernetes/config \
    kubernetes_host="$K3S_URL" \
    kubernetes_ca_cert=@/tmp/k3s-ca.crt \
    token_reviewer_jwt="$TOKEN"

# Clean up temporary file
rm /tmp/k3s-ca.crt


# Verify Vault can reach K3s API
echo "Testing connection to K3s API from Vault server..."
curl -k "$K3S_URL/version"

# Create role for cert-manager
vault write auth/kubernetes/role/cert-manager \
    bound_service_account_names=cert-manager \
    bound_service_account_namespaces=cert-manager \
    policies=cert-manager-policy \
    ttl=1h
```

3. Verify the authentication setup:
```bash
# Verify the kubernetes auth configuration
vault read auth/kubernetes/config

# Verify the role
vault read auth/kubernetes/role/cert-manager
```

### 5. External Secrets Integration

The SecretStore configuration for Vault integration is included in the Helm chart's templates (`templates/secret-store.yaml`) and will be automatically deployed by ArgoCD. Configure the Vault integration in your values.yaml:

```yaml
# External Secrets configuration
externalSecrets:
  vault:
    # Vault server URL
    server: "https://vault.home.lan:8200"
    # Path in Vault where PKI is mounted
    pkiPath: "pki_homelab"
    # Authentication configuration
    auth:
      kubernetes:
        mountPath: "kubernetes"
        role: "cert-manager"
```

You can override these values in your ArgoCD application configuration or through a values file:

```yaml
# values.production.yaml example
externalSecrets:
  vault:
    server: "https://vault.production.internal:8200"
    pkiPath: "pki_production"
```

To verify the SecretStore deployment:
```bash
# Check SecretStore status
kubectl get secretstore -n cert-manager vault-backend

# Verify Vault connectivity
kubectl describe secretstore -n cert-manager vault-backend

# Validate configuration
kubectl get secretstore vault-backend -n cert-manager -o jsonpath='{.spec.provider.vault.server}'
```

Common verification checks:
1. Ensure the SecretStore is in "Ready" state
2. Verify Vault connection is successful
3. Check service account permissions
4. Validate Vault role access

### 6. Verify Setup

```bash
# List roles
vault list pki_homelab/roles

# View role configuration
vault read pki_homelab/roles/cert-manager

# Verify policy
vault policy read cert-manager-policy

# Test certificate issuance
vault write pki_homelab/issue/cert-manager \
    common_name=test.home.lan \
    ttl=720h
```

## Prerequisites

1. HashiCorp Vault must be:
   - Running and accessible
   - PKI engine configured as above
   - Appropriate policies and roles created

2. External Secrets Operator must be:
   - Installed and configured
   - Connected to Vault
   - ClusterSecretStore `vault-backend` available

## Installation

```bash
# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install the chart
helm upgrade --install cert-manager . \
  --namespace cert-manager \
  --create-namespace
```

## Monitoring Configuration

The chart includes comprehensive monitoring with Prometheus ServiceMonitor and alerts. Configure monitoring in your values.yaml:

```yaml
monitoring:
  # Enable monitoring resources
  enabled: true
  # Metrics scrape interval
  interval: "30s"
  # ServiceMonitor configuration
  serviceMonitor:
    enabled: true
    namespace: monitoring
  # Alert configuration
  alerts:
    # Certificate expiration thresholds (in days)
    criticalExpiry: 7    # Critical alert when certificate expires in 7 days
    warningExpiry: 21    # Warning alert when certificate expires in 21 days
    # Error rate threshold
    errorRateThreshold: 0.1  # Alert when error rate exceeds 10%
```

Example of customizing monitoring thresholds:
```yaml
monitoring:
  enabled: true
  interval: "1m"
  alerts:
    criticalExpiry: 14    # More aggressive critical alert
    warningExpiry: 30     # Earlier warning
    errorRateThreshold: 0.05  # Lower error threshold
```

Available alerts:
1. **CertificateExpirationCritical**: Certificate expiring in less than criticalExpiry days
2. **CertificateExpirationWarning**: Certificate expiring in less than warningExpiry days
3. **CertificateRenewalFailure**: Certificate renewal has failed
4. **ExternalSecretSyncFailure**: External Secret failed to sync with Vault
5. **CertManagerControllerDown**: cert-manager controller is not running
6. **CertManagerHighErrorRate**: Error rate exceeds errorRateThreshold

## Network Requirements and Troubleshooting

### Network Prerequisites

1. **Network Connectivity**
   - Vault server must have network access to K3s API server (TCP/6443)
   - K3s nodes must have network access to Vault server (TCP/8200)
   - All nodes must be able to resolve each other's hostnames if using DNS

2. **Firewall Requirements**
   - Allow inbound TCP/6443 to K3s API server from Vault server
   - Allow inbound TCP/8200 to Vault server from K3s nodes
   - Consider using internal network for all communication

3. **DNS Configuration**
   - If using hostnames, ensure proper DNS resolution
   - Consider adding entries to /etc/hosts if DNS is not available
   - Avoid using localhost or 127.0.0.1 in any configuration

### Common Authentication Issues

1. **Invalid CA Certificate**
   - Ensure the CA certificate is correctly extracted from the K3s cluster
   - Verify the certificate is properly formatted
   - Check Vault server logs for TLS errors

2. **Token Issues**
   - Verify the service account exists
   - Check the ClusterRoleBinding is correct
   - Ensure the token has not expired

3. **Connection Issues**
   - Verify the K3s API server URL is accessible from Vault
   - Check network connectivity between Vault and K3s
   - Verify firewall rules allow communication
   - Test connection using: curl -k https://<k3s-ip>:6443/version

### Verification Steps

After setting up authentication:

1. Test service account:
```bash
kubectl get sa vault-auth -n cert-manager
kubectl get clusterrolebinding vault-auth-delegator
```

2. Test Vault connectivity:
```bash
# From Vault server
curl -k $APISERVER/version
```

3. Test authentication:
```bash
# Create a test pod with the cert-manager service account
kubectl run vault-test \
  --image=vault \
  --serviceaccount=cert-manager \
  --namespace=cert-manager \
  -- sleep infinity

# Test authentication from pod
kubectl exec -it vault-test -n cert-manager -- \
  vault write auth/kubernetes/login role=cert-manager
