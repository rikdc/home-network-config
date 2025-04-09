#!/bin/bash
# scripts/rotate-vault-cert.sh

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path-to-vault-config-dir>"
  exit 1
fi

CONFIG_DIR=$1

# Check if the config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
  echo "Config directory not found: $CONFIG_DIR"
  exit 1
fi

# Create directory for certificates if it doesn't exist
mkdir -p $CONFIG_DIR/certs

# Generate new private key
openssl genrsa -out $CONFIG_DIR/certs/vault-key-new.pem 2048

# Generate certificate signing request
openssl req -new -key $CONFIG_DIR/certs/vault-key-new.pem -out $CONFIG_DIR/certs/vault-csr.pem -subj "/CN=vault.local" -addext "subjectAltName = IP:192.168.88.43"

# Generate self-signed certificate
openssl x509 -req -in $CONFIG_DIR/certs/vault-csr.pem -signkey $CONFIG_DIR/certs/vault-key-new.pem -out $CONFIG_DIR/certs/vault-cert-new.pem -days 3650

# Backup old certificates
cp $CONFIG_DIR/certs/vault-cert.pem $CONFIG_DIR/certs/vault-cert.pem.bak
cp $CONFIG_DIR/certs/vault-key.pem $CONFIG_DIR/certs/vault-key.pem.bak

# Replace certificates
mv $CONFIG_DIR/certs/vault-cert-new.pem $CONFIG_DIR/certs/vault-cert.pem
mv $CONFIG_DIR/certs/vault-key-new.pem $CONFIG_DIR/certs/vault-key.pem

# Clean up
rm $CONFIG_DIR/certs/vault-csr.pem

# Update ConfigMap
./scripts/create-vault-ca-configmap.sh $CONFIG_DIR/certs/vault-cert.pem

echo "Vault certificate rotated and ConfigMap updated"
echo "You need to restart Vault for the changes to take effect:"
echo "sudo systemctl restart vault"
