# Git Branching Strategy for Private/Public Configuration Management

## ADR-001: Single Repository with Branch-Based Privacy Control

### Status
Accepted

### Context
We need to maintain a private home network configuration repository while selectively sharing sanitized templates publicly. The challenge is to prevent accidental exposure of sensitive data while maintaining a simple workflow.

### Decision
Adopt a single repository with branch-based privacy control using:
1. `main` branch for full private configuration
2. `public` branch for sanitized templates in `k3s/templates/`
3. Git hooks and validation scripts to prevent accidental exposure
4. Makefile for workflow automation

### Consequences
- Simpler workflow than multi-repo approaches
- Strong safeguards against data leakage
- Clear separation of concerns
- Requires discipline in manual sanitization
- Templates available in standardized format

---

# How to Manage Private/Public Branches

## Initial Setup

1. **Create the public branch:**
```bash
git checkout -b public
git push origin public
```

2. **Set up template directory structure:**
```bash
mkdir -p k3s/templates
echo "# Application Templates" > k3s/templates/README.md
git add k3s/templates/
git commit -m "Initialize templates directory"
git push origin public
```

3. **Use Makefile for management:**
```bash
# Install git hooks
make setup-hooks
```

## Daily Workflow

### Working on Private Features
```bash
# Always work on main branch for private config
git checkout main
# Make your changes...
git add . && git commit -m "Add new private configuration"
git push origin main
```

### Sharing Templates Publicly
```bash
# Switch to public branch
git checkout public

# Method 1: Use Makefile to sync (requires manual sanitization)
make sync-public

# Method 2: Manually copy and sanitize files
cp -r ../main/k3s/apps/myapp/* k3s/templates/myapp/
# IMPORTANT: Manually sanitize copied files!
# - Remove secrets
# - Replace IPs/hostnames with placeholders
# - Remove vault references
# - Use externalSecret placeholders
# - Convert to Helm template format

# Validate before committing
make validate-public

git add . && git commit -m "Add myapp template"
git push origin public
```

## Safety Measures

### Git Hooks
The repository includes a pre-push hook that automatically:
- Prevents pushing the `main` branch
- Validates the `public` branch for sensitive content

### Manual Validation
Before pushing the public branch, always run:
```bash
.github/scripts/validate-public.sh
```

### What Gets Validated
The validation script checks for:
- Vault directory references
- Secret file extensions (*.key, *.pem, *.secret.*, *.enc)
- Common sensitive patterns (private keys, passwords, tokens)
- IP address warnings (manual verification needed)

## Consumer Workflow

Users who want to use your templates:
```bash
# Clone the public branch only
git clone --branch public https://github.com/yourname/home-network-config.git

# Or download specific templates
curl -O https://raw.githubusercontent.com/yourname/home-network-config/public/k3s/templates/frigate/values.yaml
```

## Best Practices

1. **Never merge public → main** - This could contaminate your private config
2. **Always sanitize manually** when copying from main → public
3. **Regular audits** of the public branch for accidental exposure
4. **Use placeholders** instead of real values in templates
5. **Document the sanitization process** for complex configurations
6. **Test templates** in isolation before sharing
7. **Follow Helm chart best practices** for template structure
8. **Use Makefile commands** for consistent workflow

## Troubleshooting

### Hook Installation
If the pre-push hook isn't working:
```bash
chmod +x .git/hooks/pre-push
```

### Bypassing Hooks (Emergency Only)
```bash
git push --no-verify origin public  # Use only when absolutely necessary
```

### Recovering from Accidental Sensitive Commits
If you accidentally commit sensitive data to the public branch:
1. Immediately remove the commit:
```bash
git reset --hard HEAD~1
```
2. If already pushed, use git-filter-branch or BFG Repo-Cleaner
3. Rotate any exposed credentials immediately

## Security Notes

- The validation script is a safeguard, not a guarantee
- Always manually review changes before pushing to public branch
- Consider using git-secrets for additional protection
- Regularly audit the public branch history