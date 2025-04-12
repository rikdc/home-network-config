# Docmost Helm Chart

This Helm chart deploys [Docmost](https://github.com/docmost/docmost), an open-source collaborative wiki and documentation platform, on Kubernetes.

## Prerequisites

- Kubernetes cluster
- Helm 3.0+
- External PostgreSQL database
- Vault for secrets management

## Installation

1. Add the repository:
```bash
helm repo add docmost https://charts.home.lan
helm repo update
```

2. Install the chart:
```bash
helm install docmost . -n tools
```

## Configuration

The following table lists the configurable parameters of the Docmost chart and their default values.

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of Docmost replicas | `1` |
| `nameOverride` | Override the name of the chart | `""` |
| `fullnameOverride` | Override the full name of the chart | `""` |

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Docmost image repository | `docmost/docmost` |
| `image.tag` | Docmost image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `3000` |
| `service.targetPort` | Container port | `3000` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `traefik` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts configuration | `[{host: wiki.home.lan, paths: [{path: /, pathType: Prefix}]}]` |
| `ingress.tls` | Ingress TLS configuration | See values.yaml |

### Resources Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `1000m` |
| `resources.limits.memory` | Memory limit | `1Gi` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `500Mi` |

### Persistence Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistence | `true` |
| `persistence.existingClaim` | Use existing PVC | `docmost-data-pv-pvc` |
| `persistence.size` | Storage size | `10Gi` |
| `persistence.storageClass` | Storage class | `nfs-client` |

### Redis Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `redis.enabled` | Enable Redis sidecar | `true` |
| `redis.image.repository` | Redis image repository | `redis` |
| `redis.image.tag` | Redis image tag | `7-alpine` |
| `redis.resources` | Redis resource requirements | See values.yaml |

### External Secrets Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `externalSecrets.enabled` | Enable external secrets | `true` |
| `externalSecrets.secretStore.name` | Secret store name | `vault-backend` |
| `externalSecrets.secretStore.kind` | Secret store kind | `ClusterSecretStore` |
| `externalSecrets.target.name` | Target secret name | `app-secrets` |
| `externalSecrets.data` | Secret data configuration | See values.yaml |

## Usage

1. Configure your values in a custom values.yaml file:
```yaml
ingress:
  hosts:
    - host: your-wiki.domain.com
      paths:
        - path: /
          pathType: Prefix
```

2. Install the chart with custom values:
```bash
helm install docmost . -f custom-values.yaml -n tools
```

## Upgrading

To upgrade the chart:
```bash
helm upgrade docmost . -n tools
```

## Uninstalling

To uninstall/delete the deployment:
```bash
helm uninstall docmost -n tools
```

## Troubleshooting

1. Check the pod status:
```bash
kubectl get pods -n tools -l app.kubernetes.io/name=docmost
```

2. View the logs:
```bash
kubectl logs -n tools -l app.kubernetes.io/name=docmost
```

3. Check the ingress configuration:
```bash
kubectl get ingress -n tools
```

4. Verify external secrets:
```bash
kubectl get externalsecret -n tools
