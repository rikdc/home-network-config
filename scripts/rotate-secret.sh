#!/bin/bash
# scripts/rotate-secret.sh

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <app-name> <key> <new-value>"
  exit 1
fi

APP_NAME=$1
KEY=$2
NEW_VALUE=$3

SECRET_FILE="k3s/secrets/apps/$APP_NAME/secrets.enc.yaml"

if [ ! -f "$SECRET_FILE" ]; then
  echo "Secret file not found: $SECRET_FILE"
  exit 1
fi

# Decrypt the file
TEMP_FILE=$(mktemp)
sops --decrypt $SECRET_FILE > $TEMP_FILE

# Check if yq is installed
if ! command -v yq &> /dev/null; then
  echo "Error: yq is not installed. Please install it first."
  echo "For macOS: brew install yq"
  echo "For Linux: snap install yq or download from https://github.com/mikefarah/yq/releases"
  rm $TEMP_FILE
  exit 1
fi

# Update the value using yq
yq e ".stringData.$KEY = \"$NEW_VALUE\"" -i $TEMP_FILE

# Get the Age public key from .sops.yaml
AGE_PUBLIC_KEY=$(grep "age:" .sops.yaml | awk '{print $2}')

# Encrypt the file again
sops --encrypt --age $AGE_PUBLIC_KEY $TEMP_FILE > $SECRET_FILE

# Clean up
rm $TEMP_FILE

echo "Rotated secret $KEY for $APP_NAME"
