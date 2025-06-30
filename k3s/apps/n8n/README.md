# n8n Helm Deployment

This directory contains configuration for deploying [n8n](https://n8n.io) using
the community Helm chart maintained by 8gears.

## Prerequisites

1. The NFS storage classes must be deployed:
   ```bash
   kubectl apply -f ../../nfs-storage-class.yaml
   ```
2. The namespaces must exist:
   ```bash
   kubectl apply -f ../../namespaces.yaml
   ```
3. The persistent volumes and claims must be created:
   ```bash
   kubectl apply -f ../../persistent-volumes/tools/n8n.yaml
   ```

## Deployment

Login to the 8gears OCI registry and deploy n8n:

```bash
helm registry login 8gears.container-registry.com
helm install n8n oci://8gears.container-registry.com/library/n8n \
  --version 1.0.0 \
  -f values.yaml \
  -n tools
```

### Upgrading

```bash
helm upgrade n8n oci://8gears.container-registry.com/library/n8n \
  --version 1.0.0 \
  -f values.yaml \
  -n tools
```

## Configuration

The `values.yaml` file configures storage, secrets and ingress. Important sections:

```yaml
n8n:
  main:
    persistence:
      existingClaim: n8n-config-pvc
    service:
      port: 5678
  ingress:
    hosts:
      - host: n8n.home.lan
        paths:
          - path: /
            pathType: Prefix
```

Secrets are provided by an `ExternalSecret` named `n8n-external-secret` which
populates the `n8n-secrets` secret used by the chart.
