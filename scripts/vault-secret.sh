#!/bin/bash
# scripts/vault-secret.sh

# Set Vault address and skip certificate verification for self-signed certificates
export VAULT_ADDR='https://192.168.88.43:8200'
export VAULT_SKIP_VERIFY=true

# Function to create or update a secret
create_secret() {
  if [ "$#" -lt 3 ]; then
    echo "Usage: $0 create <app-name> <key1=value1> [key2=value2 ...]"
    exit 1
  fi

  APP_NAME=$1
  shift

  # Build key-value pairs for Vault
  KV_PAIRS=""
  for pair in "$@"; do
    KEY=$(echo $pair | cut -d= -f1)
    VALUE=$(echo $pair | cut -d= -f2-)
    KV_PAIRS="$KV_PAIRS $KEY=\"$VALUE\""
  done

  # Create or update the secret in Vault
  vault kv put secrets/$APP_NAME $KV_PAIRS
}

# Function to read a secret
read_secret() {
  if [ "$#" -ne 2 ]; then
    echo "Usage: $0 read <app-name> <key>"
    exit 1
  fi

  APP_NAME=$1
  KEY=$2

  # Read the secret from Vault
  vault kv get -field=$KEY secrets/$APP_NAME
}

# Function to delete a secret
delete_secret() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 delete <app-name>"
    exit 1
  fi

  APP_NAME=$1

  # Delete the secret from Vault
  vault kv delete secrets/$APP_NAME
}

# Main function
main() {
  if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <command> [args...]"
    echo "Commands: create, read, delete"
    exit 1
  fi

  COMMAND=$1
  shift

  case $COMMAND in
    create)
      create_secret "$@"
      ;;
    read)
      read_secret "$@"
      ;;
    delete)
      delete_secret "$@"
      ;;
    *)
      echo "Unknown command: $COMMAND"
      echo "Commands: create, read, delete"
      exit 1
      ;;
  esac
}

# Run the script
main "$@"
