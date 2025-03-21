.PHONY: lint lint-yaml lint-markdown lint-ansible fix-yaml fix-markdown

# Default target
all: lint

# Main lint target that runs all linting
lint: lint-yaml lint-markdown lint-ansible

# YAML linting
lint-yaml:
	@echo "Linting YAML files..."
	@find . \( -name "*.yml" -o -name "*.yaml" \) \
			! -path "./ansible/inventory/host_vars/*" \
			! -path "./ansible/inventory/group_vars/*" \
			-print0 | xargs -0 -r yamllint -f colored
	@find . \( -name "*.yml" -o -name "*.yaml" \) \
			! -path "./ansible/inventory/host_vars/*" \
			! -path "./ansible/inventory/group_vars/*" \
			-print0 | xargs -0 -r prettier --check --parser yaml || echo "YAML formatting issues found"

# Markdown linting
lint-markdown:
	@echo "Linting Markdown files..."
	@markdownlint-cli2 "**/*.md" --config markdownlint-config.json || echo "Markdown formatting issues found"

# Ansible linting
lint-ansible:
	@echo "Linting Ansible files..."
	@cd ansible
	@ansible-lint . --force-color || echo "Ansible linting issues found"
	@cd ../
