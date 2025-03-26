# Home Network Configuration

This repository contains the configuration for my homelab network infrastructure, primarily using Ansible for automation.

## Quality Checks

This repository includes several tools to maintain code quality:

### YAML Linting and Formatting

YAML files are linted using yamllint and formatted using Prettier. The configuration files are:

- `.yamllint` - Configuration for yamllint
- `.prettierrc.yml` - Configuration for Prettier

### Using the Makefile

A Makefile is provided for easy linting and formatting:

```bash
# Run all linters
make lint

# Run specific linters
make lint-yaml
make lint-markdown
make lint-ansible

# Fix formatting issues
make fix-yaml
make fix-markdown
make fix

# Show all available targets
make help
```

### Pre-commit Hooks

Pre-commit hooks are configured to run quality checks before committing changes. To use pre-commit:

1. Install pre-commit:
   ```bash
   pip install pre-commit
   ```

2. Install the git hooks:
   ```bash
   pre-commit install
   ```

3. The hooks will now run automatically on `git commit`. You can also run them manually:
   ```bash
   pre-commit run --all-files
   ```

### CI/CD Workflows

GitHub Actions workflows are configured to run quality checks on push and pull requests:

- YAML linting and formatting
- Ansible linting
- Secrets scanning

#### Auto-fixing Issues

You can fix formatting issues in two ways:

**Locally using the Makefile:**

```bash
# Fix all formatting issues
make fix

# Fix specific issues
make fix-yaml
make fix-markdown
```

**Via GitHub Actions:**

When creating a pull request, you can enable auto-fixing of formatting issues by:

1. Going to the "Actions" tab in GitHub
2. Selecting the "CI" workflow
3. Clicking "Run workflow"
4. Setting "Automatically fix formatting issues" to true
5. Running the workflow

This will automatically fix formatting issues and commit the changes to your pull request.
