# n8n Helm Deployment

This directory contains configuration for deploying [n8n](https://n8n.io) using the community maintained chart from [8gears/n8n-helm-chart](https://github.com/8gears/n8n-helm-chart).

## Prerequisites

1. Deploy the NFS storage classes:
   ```bash
   kubectl apply -f ../../nfs-storage-class.yaml
   ```
2. Ensure the required namespaces exist:
   ```bash
   kubectl apply -f ../../namespaces.yaml
   ```
3. Create the persistent volume and claim:
   ```bash
   kubectl apply -f ../../persistent-volumes/tools/n8n.yaml
   ```

## Deployment

Install the chart from the 8gears OCI registry:

```bash
helm install n8n oci://8gears.container-registry.com/library/n8n \
  --version 1.0.10 \
  -f values.yaml \
  -n tools
```

### Upgrading

```bash
helm upgrade n8n oci://8gears.container-registry.com/library/n8n \
  --version 1.0.10 \
  -f values.yaml \
  -n tools
```

## Configuration

The `values.yaml` file configures storage, secrets and n8n chart settings. Key sections:

```yaml
n8n:
  main:
    service:
      port: 5678
    ingress:
      enabled: true
      hosts:
        - host: n8n.home.lan
          paths:
            - /
```

Secrets are provided by an `ExternalSecret` named `n8n-external-secret` which populates the `n8n-secrets` secret used by the chart.
