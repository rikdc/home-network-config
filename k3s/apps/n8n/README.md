# n8n Helm Deployment

This directory contains configuration for deploying [n8n](https://n8n.io), an open-source workflow automation tool, using Helm.

## Prerequisites

1. Deploy the NFS storage classes:
   ```bash
   kubectl apply -f ../../nfs-storage-class.yaml
   ```
2. Ensure required namespaces exist:
   ```bash
   kubectl apply -f ../../namespaces.yaml
   ```
3. Create the persistent volumes and claims:
   ```bash
   kubectl apply -f ../../persistent-volumes/tools/n8n.yaml
   ```

## Deployment

Add the n8n Helm repository and install using the provided values file:

```bash
helm repo add n8n https://8gears.github.io/n8n-helm-chart/
helm repo update
helm install n8n n8n/n8n \
  -f values.yaml \
  -n tools
```

## Upgrading

To upgrade the deployment:

```bash
helm upgrade n8n n8n/n8n \
  -f values.yaml \
  -n tools
```

## Configuration

The `values.yaml` file contains configuration for storage, secrets and the n8n chart. Key settings include:

- **Storage**: Creates a persistent volume and claim backed by NFS for n8n data
- **External Secrets**: Retrieves credentials such as `DATABASE_URL` and authentication details from Vault
- **Ingress**: Exposes n8n at `n8n.home.lan`

Adjust the values as needed for your environment.
