# Homepage

## Overview
This Helm chart deploys the [Homepage](https://github.com/gethomepage/homepage) application, a modern dashboard for your homelab that organizes your services, bookmarks, and widgets.

## Vault Integration for Sensitive Link Information

### Overview
This chart includes integration with HashiCorp Vault to securely store sensitive link information, such as URLs, usernames, and passwords. This allows you to:

1. Keep sensitive information out of your Git repository
2. Centrally manage and rotate credentials
3. Control access to sensitive information using Vault's access control mechanisms

### Vault Structure
The recommended structure for storing homepage link information in Vault is:

```
secrets/
└── homepage/
    ├── links/
    │   ├── matrix/
    │   │   ├── url
    │   │   ├── username (if needed)
    │   │   └── password (if needed)
    │   ├── jellyfin/
    │   │   ├── url
    │   │   ├── username (if needed)
    │   │   └── password (if needed)
    │   └── ... (other services)
    └── widgets/
        ├── mikrotik/
        │   ├── url
        │   ├── username
        │   └── password
        └── ... (other widgets)
```

### How to Use

#### 1. Store Secrets in Vault
Store your sensitive link information in Vault using the recommended structure. For example:

```bash
# Store Matrix URL
vault kv put secrets/homepage/links/matrix url="https://chat.home.lan"

# Store Jellyfin URL
vault kv put secrets/homepage/links/jellyfin url="https://jellyfin.home.lan"

# Store MikroTik widget credentials
vault kv put secrets/homepage/widgets/mikrotik \
  url="https://router.home.lan" \
  username="admin" \
  password="your-secure-password"
```

#### 2. Configure External Secrets
Update the `values.yaml` file to include the secrets you want to fetch from Vault:

```yaml
externalSecrets:
  enabled: true
  secretStore:
    name: vault-k8s-auth
    kind: ClusterSecretStore
  data:
    - secretKey: HOMEPAGE_VAR_SERVICE_URL
      remoteRef:
        key: secrets/homepage/links/service
        property: url
    - secretKey: HOMEPAGE_VAR_SERVICE_USERNAME
      remoteRef:
        key: secrets/homepage/links/service
        property: username
    - secretKey: HOMEPAGE_VAR_SERVICE_PASSWORD
      remoteRef:
        key: secrets/homepage/links/service
        property: password
```

#### 3. Use Environment Variables in ConfigMap
Update the `configmap.yaml` template to use the environment variables:

```yaml
services.yaml: |
  - Services:
    - Service:
        href: '{{`{{HOMEPAGE_VAR_SERVICE_URL}}`}}'
        description: Service Description
        icon: service-icon.svg
        widget:
            type: widget-type
            url: '{{`{{HOMEPAGE_VAR_SERVICE_URL}}`}}'
            username: '{{`{{HOMEPAGE_VAR_SERVICE_USERNAME}}`}}'
            password: '{{`{{HOMEPAGE_VAR_SERVICE_PASSWORD}}`}}'
```

### Fallback to Default Values
You can provide default values in the ConfigMap for development or testing purposes:

```yaml
services.yaml: |
  - Services:
    - Service:
        href: '{{ .Values.service.url | default "https://default-service-url.com" }}'
        description: Service Description
        icon: service-icon.svg
```

### Security Considerations
- Ensure that the Vault policy for the service account has the minimum required permissions
- Regularly rotate credentials stored in Vault
- Use Vault's audit logging to track access to sensitive information
