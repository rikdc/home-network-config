#!/bin/bash
# scripts/test-vault-connection.sh

# Set Vault address and skip certificate verification for self-signed certificates
export VAULT_ADDR='https://192.168.88.43:8200'
export VAULT_SKIP_VERIFY=true

# Check if token is provided
if [ "$#" -eq 1 ]; then
  TOKEN=$1
  echo "Using provided token"
  vault login $TOKEN
fi

# Test connection
echo "Testing connection to Vault at $VAULT_ADDR"
vault status

if [ $? -eq 0 ]; then
  echo "Connection successful"
else
  echo "Connection failed"
  exit 1
fi

# List secrets engines
echo "Listing secrets engines"
vault secrets list

# List KV secrets if KV engine is enabled
if vault secrets list | grep -q "secrets/"; then
  echo "Listing secrets in 'secrets/' path"
  vault kv list secrets/ || echo "No secrets found or access denied"
fi
