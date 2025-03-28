# Kubernetes Applications

This directory contains the configuration for applications deployed on the k3s cluster.

## Directory Structure

Each application has its own subdirectory containing the necessary configuration files:

```
apps/
├── [future-app]/             # Future application
│   ├── README.md
│   ├── values.yaml or deployment files
```

## Adding a New Application

To add a new application:

1. Create a new directory for the application:
   ```bash
   mkdir -p k8s/apps/[app-name]
   ```

2. Create the necessary persistent volumes and claims in the appropriate namespace directory:
   ```bash
   vim ansible/inventory/host_vars/k3s-controller.yml
   ```

## Namespaces

Applications are organized into the following namespaces:

- **home**: Home automation applications (e.g., Home Assistant)
- **media**: Media applications (e.g., Audiobookshelf, Jellyfin)
- **network**: Network applications (e.g., Blocky DNS)
- **monitoring**: Monitoring applications (e.g., Prometheus, Grafana)

Make sure to deploy applications to the appropriate namespace.

## Storage

Applications should use persistent volumes and claims defined in the `ansible/inventory/host_vars/k3s-controller.yml` file. See the [k8s_persistent_storage-README](../ansible/roles/k8s_persistent_storage/README.md) for more information.
