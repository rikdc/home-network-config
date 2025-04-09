#!/bin/bash
# scripts/create-vault-ca-configmap.sh

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path-to-vault-cert>"
  exit 1
fi

CERT_PATH=$1

# Check if the certificate file exists
if [ ! -f "$CERT_PATH" ]; then
  echo "Certificate file not found: $CERT_PATH"
  exit 1
fi

# Create namespace if it doesn't exist
kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -

# Create ConfigMap
kubectl create configmap vault-ca --from-file=ca.crt=$CERT_PATH -n external-secrets --dry-run=client -o yaml | kubectl apply -f -

echo "Created ConfigMap 'vault-ca' in namespace 'external-secrets'"
```

## Script: create-vault-token-secret.sh

This script creates a Kubernetes Secret with the Vault token.

```bash
#!/bin/bash
# scripts/create-vault-token-secret.sh

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <vault-token>"
  exit 1
fi

TOKEN=$1

# Create namespace if it doesn't exist
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Create Secret
kubectl create secret generic vault-token --from-literal=token=$TOKEN -n argocd --dry-run=client -o yaml | kubectl apply -f -

echo "Created Secret 'vault-token' in namespace 'argocd'"
