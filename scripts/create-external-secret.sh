#!/bin/bash
# scripts/create-external-secret.sh

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <app-name> <namespace> <key1> [key2 ...]"
  exit 1
fi

APP_NAME=$1
NAMESPACE=$2
shift 2

# Create directory if it doesn't exist
mkdir -p k3s/apps/$APP_NAME

# Create ExternalSecret manifest
cat > k3s/apps/$APP_NAME/external-secret.yaml << EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ${APP_NAME}-external-secret
  namespace: ${NAMESPACE}
spec:
  refreshInterval: "15s"
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: app-secrets
  data:
EOF

# Add data items
for key in "$@"; do
  cat >> k3s/apps/$APP_NAME/external-secret.yaml << EOF
  - secretKey: ${key}
    remoteRef:
      key: secrets/data/${APP_NAME}
      property: ${key}
EOF
done

echo "Created ExternalSecret manifest in k3s/apps/$APP_NAME/external-secret.yaml"
