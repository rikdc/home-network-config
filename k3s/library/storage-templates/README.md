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
# Values for your application's storage (for backward compatibility)
storage:
  persistence:
    enabled: true
    type: nfs
    size: 10Gi
    storageClass: nfs-storage
    pvName: my-app-data-pv
    pvcName: my-app-data-pvc
    useExternalSecrets: true
    nfs:
      server: 192.168.1.100
      path: /data/my-app

# Values for the storage-templates library chart
# IMPORTANT: This section is required for the library chart to work
storage-templates:
  storage:
    persistence:
      enabled: true
      type: nfs
      size: 10Gi
      storageClass: nfs-storage
      pvName: my-app-data-pv
      pvcName: my-app-data-pvc
      useExternalSecrets: true
      # Skip creation of PV and PVC (useful for existing applications)
      skipCreation: false
      nfs:
        server: 192.168.1.100  # Will be overridden by External Secrets if enabled
        path: /data/my-app     # Will be overridden by External Secrets if enabled

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

> **Note**: When using a Helm library chart as a dependency, the values need to be specified under a key that matches the dependency name (`storage-templates` in this case). The original `storage` section is kept for backward compatibility.

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

## Using with Existing Applications

If you have existing applications with PV and PVC resources already created, you can still use this library chart without recreating those resources. This is useful when you want to standardize your storage configuration without risking data loss.

To use this chart with existing applications:

1. Set `storage.persistence.skipCreation: true` in your values.yaml file:

```yaml
# Values for your application's storage (for backward compatibility)
storage:
  persistence:
    enabled: true
    type: nfs
    size: 10Gi
    storageClass: nfs-storage
    pvName: existing-pv-name
    pvcName: existing-pvc-name
    useExternalSecrets: true
    nfs:
      server: 192.168.1.100
      path: /data/my-app

# Values for the storage-templates library chart with skipCreation enabled
storage-templates:
  storage:
    persistence:
      enabled: true
      type: nfs
      size: 10Gi
      storageClass: nfs-storage
      pvName: existing-pv-name
      pvcName: existing-pvc-name
      # Skip creation of PV and PVC since they already exist
      skipCreation: true
      useExternalSecrets: true
      nfs:
        server: 192.168.1.100  # Placeholder
        path: /data/my-app     # Placeholder

    externalSecrets:
      secretStore:
        name: vault-backend
        kind: ClusterSecretStore
      target:
        name: app-secrets
      nfsServer:
        key: secrets/data/platform
        property: NFS_SERVER
      nfsPath:
        key: secrets/data/my-app
        property: NFS_PATH
```

2. The library chart will skip creating the PV and PVC resources, but will still:
   - Create the ExternalSecret for NFS configuration
   - Provide the same values structure for referencing in your Deployment

This approach allows you to gradually adopt the pattern across your cluster without disrupting existing applications.

## Examples

### Basic NFS Storage

```yaml
storage-templates:
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
storage-templates:
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
