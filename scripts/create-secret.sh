#!/bin/bash
# scripts/create-secret.sh

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <app-name> <namespace> <key1=value1> [key2=value2 ...]"
  exit 1
fi

APP_NAME=$1
NAMESPACE=$2
shift 2

# Create temporary file
TEMP_FILE=$(mktemp)

# Create YAML structure
cat > $TEMP_FILE << EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${APP_NAME}-secrets
  namespace: ${NAMESPACE}
type: Opaque
stringData:
EOF

# Add key-value pairs
for pair in "$@"; do
  KEY=$(echo $pair | cut -d= -f1)
  VALUE=$(echo $pair | cut -d= -f2-)
  echo "  $KEY: $VALUE" >> $TEMP_FILE
done

# Create directory if it doesn't exist
mkdir -p k3s/secrets/apps/$APP_NAME

# Get the Age public key from .sops.yaml
AGE_PUBLIC_KEY=$(grep "age:" .sops.yaml | awk '{print $2}')

# Encrypt the file
sops --encrypt --age $AGE_PUBLIC_KEY $TEMP_FILE > k3s/secrets/apps/$APP_NAME/secrets.enc.yaml

# Create ExternalSecret resource
mkdir -p k3s/apps/$APP_NAME
cat > k3s/apps/$APP_NAME/external-secret.yaml << EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ${APP_NAME}-external-secret
  namespace: ${NAMESPACE}
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: sops-secret-store
    kind: ClusterSecretStore
  target:
    name: ${APP_NAME}-secrets
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: k3s/secrets/apps/${APP_NAME}/secrets.enc.yaml
EOF

# Clean up
rm $TEMP_FILE

echo "Created encrypted secret for $APP_NAME in namespace $NAMESPACE"
echo "Created ExternalSecret resource in k3s/apps/$APP_NAME/external-secret.yaml"
