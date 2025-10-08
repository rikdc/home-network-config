# Makefile for managing the private/public branching workflow

.PHONY: help sync-public validate-public clean-public setup-hooks

help:
	@echo "Makefile for managing private/public branching workflow"
	@echo ""
	@echo "Usage:"
	@echo "  make sync-public     Sync latest changes from main to public branch"
	@echo "  make validate-public Validate public branch for sensitive content"
	@echo "  make clean-public    Clean public branch (remove all files)"
	@echo "  make setup-hooks     Install git hooks"
	@echo "  make help            Show this help message"

sync-public:
	@echo "Syncing main branch changes to public branch..."
	git checkout public
	git merge main --no-commit --no-ff || true
	@echo "Manual sanitization required. Please:"
	@echo "1. Remove sensitive files (vault/, *.secret.*, etc.)"
	@echo "2. Replace sensitive values with placeholders"
	@echo "3. Run 'make validate-public' to check"
	@echo "4. Commit and push to public branch"

validate-public:
	@echo "Validating public branch..."
	./.github/scripts/validate-public.sh

clean-public:
	@echo "Cleaning public branch..."
	git checkout public
	git rm -rf .
	git commit -m "Clean public branch"
	@echo "Public branch cleaned. Ready for new template content."

setup-hooks:
	@echo "Installing git hooks..."
	chmod +x .git/hooks/pre-push
	chmod +x .github/scripts/validate-public.sh
	@echo "Git hooks installed successfully."

# Convenience targets for common operations
public-diff:
	git diff main..public

public-log:
	git log --oneline --graph main public