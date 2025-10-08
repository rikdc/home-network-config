# Application Templates

This directory contains sanitized templates for applications that can be shared publicly. These templates are derived from the private configurations in the main branch but have been sanitized to remove all sensitive data.

## Usage

To use these templates in your own environment:

1. Copy the desired template directory to your k3s/apps/ directory
2. Modify the values to match your environment
3. Replace placeholder values with your actual configuration
4. Configure external secrets according to your secrets management system

## Template Structure

Each template follows the standard Helm chart structure:
```
app-name/
├── Chart.yaml     # Chart metadata
├── values.yaml    # Sanitized configuration with placeholders
└── templates/     # Kubernetes manifests with external secret references
```

## Contributing

These templates are automatically synchronized from the main branch. To contribute improvements:

1. Make changes in the main branch first
2. Extract and sanitize the changes to the public branch
3. Ensure no sensitive data is included
4. Run validation scripts before pushing

## Important Notes

- All secrets are referenced via ExternalSecrets pattern
- IP addresses and hostnames use generic placeholders
- Vault paths are generic and need to be customized
- Resource requirements are set to reasonable defaults