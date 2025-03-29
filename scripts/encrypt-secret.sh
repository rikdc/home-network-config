#!/bin/bash
# scripts/encrypt-secret.sh

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input-file> <output-file>"
  exit 1
fi

INPUT_FILE=$1
OUTPUT_FILE=$2

# Get the Age public key from .sops.yaml
AGE_PUBLIC_KEY=$(grep "age:" .sops.yaml | awk '{print $2}')

# Encrypt the file
sops --encrypt --age $AGE_PUBLIC_KEY $INPUT_FILE > $OUTPUT_FILE

echo "Encrypted $INPUT_FILE to $OUTPUT_FILE"
