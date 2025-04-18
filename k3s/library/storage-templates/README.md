# Storage Templates Library Chart

This Helm library chart provides reusable templates for Kubernetes persistent storage with NFS and External Secrets support.

## Overview

This library chart provides templates for:
- PersistentVolume (PV)
- PersistentVolumeClaim (PVC)
- ExternalSecret for NFS configuration

## Installation

As this is a library chart, it's not meant to be installed directly. Instead, it should be included as a dependency in your application charts.

## Usage

### 1. Add the library chart as a dependency

In your application chart's `Chart.yaml`:

```yaml
dependencies:
  - name: storage-templates
    version: 0.1.0
    repository: file://../../library/storage-templates
```

### 2. Update your application's values.yaml

Add the storage configuration to your application's `values.yaml`:

```yaml
storage:
  persistence:
    enabled: true
    type: nfs
    size: 10Gi
    storageClass: nfs-storage
    # Optional: Custom names
    pvName: my-app-data-pv
    pvcName: my-app-data-pvc
    # NFS configuration (required even when using External Secrets)
    nfs:
      server: 192.168.1.100  # Will be overridden by External Secrets if enabled
      path: /data/my-app     # Will be overridden by External Secrets if enabled
    # Enable External Secrets integration
    useExternalSecrets: true

  # External Secrets configuration
  externalSecrets:
    secretStore:
      name: vault-backend
      kind: ClusterSecretStore
    target:
      name: my-app-storage-secrets
    nfsServer:
      key: secrets/data/platform
      property: NFS_SERVER
    nfsPath:
      key: secrets/data/my-app
      property: NFS_PATH
```

### 3. No need to include templates

When using the library chart as a dependency, you don't need to include the templates in your application's template files. The library chart will automatically create the PersistentVolume, PersistentVolumeClaim, and ExternalSecret resources based on your values.yaml configuration.

### 4. Reference the PVC in your Deployment

In your Deployment template:

```yaml
volumes:
  - name: data
    persistentVolumeClaim:
      claimName: {{ .Values.storage.persistence.pvcName | default (printf "%s-pvc" .Release.Name) }}
```

## Configuration

See the [values.yaml](./values.yaml) file for the full list of configurable parameters.

## Examples

### Basic NFS Storage

```yaml
storage:
  persistence:
    enabled: true
    type: nfs
    size: 5Gi
    storageClass: nfs-storage
    nfs:
      server: 192.168.1.100
      path: /data/my-app
```

### NFS with External Secrets

```yaml
storage:
  persistence:
    enabled: true
    type: nfs
    size: 10Gi
    storageClass: nfs-storage
    useExternalSecrets: true
    nfs:
      server: 192.168.1.100  # Placeholder, will be overridden
      path: /data/my-app     # Placeholder, will be overridden

  externalSecrets:
    secretStore:
      name: vault-backend
      kind: ClusterSecretStore
    nfsServer:
      key: secrets/data/platform
      property: NFS_SERVER
    nfsPath:
      key: secrets/data/my-app
      property: NFS_PATH
