.PHONY: lint lint-yaml lint-ansible fix-yaml

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
