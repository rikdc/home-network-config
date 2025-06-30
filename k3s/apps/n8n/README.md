# n8n Helm Deployment

This directory contains configuration for deploying [n8n](https://n8n.io) using the [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts) chart.

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

Add the bjw-s Helm repository and install the chart:

```bash
helm repo add bjw-s https://bjw-s-labs.github.io/helm-charts/
helm repo update
helm install n8n bjw-s/app-template \
  --version 4.1.2 \
  -f values.yaml \
  -n tools
```

### Upgrading

```bash
helm upgrade n8n bjw-s/app-template \
  --version 4.1.2 \
  -f values.yaml \
  -n tools
```

## Configuration

The `values.yaml` file configures storage, secrets and app-template settings. Key sections:

```yaml
controllers:
  main:
    containers:
      main:
        image:
          repository: docker.io/n8nio/n8n
          tag: 1.44.0
service:
  main:
    ports:
      http:
        port: 5678
ingress:
  main:
    hosts:
      - host: n8n.home.lan
        paths:
          - path: /
            pathType: Prefix
```

Secrets are provided by an `ExternalSecret` named `n8n-external-secret` which populates the `n8n-secrets` secret used by the chart.
