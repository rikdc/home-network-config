.PHONY: lint lint-yaml lint-ansible fix-yaml secrets-generate-key secrets-encrypt secrets-decrypt secrets-create secrets-rotate

# Default target
all: lint

# Main lint target that runs all linting
lint: lint-yaml

# YAML linting
lint-yaml:
	@echo "Linting YAML files..."
	@find . \( -name "*.yml" -o -name "*.yaml" \) \
			! -path "./ansible/inventory/host_vars/*" \
			! -path "./ansible/inventory/group_vars/*" \
			-print0 | xargs -0 -r yamllint -f colored

# Ansible linting
lint-ansible:
	@echo "Linting Ansible files..."
	@ansible-lint ansible -c .ansible-lint --force-color || echo "Ansible linting issues found"

# Secrets Management

# Generate a new Age key pair
secrets-generate-key:
	@echo "Generating a new Age key pair..."
	@mkdir -p ~/.age
	@age-keygen -o ~/.age/key.txt
	@chmod 600 ~/.age/key.txt
	@echo "Age key pair generated at ~/.age/key.txt"
	@echo "Public key: $$(grep "public key" ~/.age/key.txt | cut -d ":" -f 2 | tr -d " ")"
	@echo "Update the .sops.yaml file with the public key"

# Encrypt a file using SOPS and Age
secrets-encrypt:
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE parameter is required"; \
		echo "Usage: make secrets-encrypt FILE=path/to/file.yaml"; \
		exit 1; \
	fi
	@echo "Encrypting $(FILE) with SOPS..."
	@./scripts/encrypt-secret.sh $(FILE) $${FILE%.yaml}.enc.yaml
	@echo "File encrypted to $${FILE%.yaml}.enc.yaml"

# Decrypt a file using SOPS and Age
secrets-decrypt:
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE parameter is required"; \
		echo "Usage: make secrets-decrypt FILE=path/to/file.enc.yaml"; \
		exit 1; \
	fi
	@echo "Decrypting $(FILE) with SOPS..."
	@SOPS_AGE_KEY_FILE=~/.age/key.txt sops --decrypt $(FILE) > $${FILE%.enc.yaml}.yaml
	@echo "File decrypted to $${FILE%.enc.yaml}.yaml"

# Create a new secret for an application
secrets-create:
	@if [ -z "$(APP)" ] || [ -z "$(NAMESPACE)" ]; then \
		echo "Error: APP and NAMESPACE parameters are required"; \
		echo "Usage: make secrets-create APP=app-name NAMESPACE=namespace KEY1=value1 KEY2=value2 ..."; \
		exit 1; \
	fi
	@echo "Creating secret for $(APP) in namespace $(NAMESPACE)..."
	@./scripts/create-secret.sh $(APP) $(NAMESPACE) $(filter-out APP=% NAMESPACE=%, $(MAKEFLAGS))
	@echo "Secret created for $(APP) in namespace $(NAMESPACE)"

# Rotate a secret value
secrets-rotate:
	@if [ -z "$(APP)" ] || [ -z "$(KEY)" ] || [ -z "$(VALUE)" ]; then \
		echo "Error: APP, KEY, and VALUE parameters are required"; \
		echo "Usage: make secrets-rotate APP=app-name KEY=key-name VALUE=new-value"; \
		exit 1; \
	fi
	@echo "Rotating secret $(KEY) for $(APP)..."
	@./scripts/rotate-secret.sh $(APP) $(KEY) "$(VALUE)"
	@echo "Secret $(KEY) rotated for $(APP)"
