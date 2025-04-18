# Persistent Storage Pattern for K3s Applications

This document describes the standardized pattern for implementing persistent storage in k3s applications using NFS and External Secrets.

## Overview

The persistent storage pattern provides a consistent way to:
- Define PersistentVolumes (PV) and PersistentVolumeClaims (PVC) for applications
- Configure NFS storage with secure credentials management
- Integrate with External Secrets for NFS server and path configuration

## Implementation

The pattern is implemented as a Helm library chart located at `k3s/library/storage-templates`. This library chart provides reusable templates for:
- PersistentVolume (PV)
- PersistentVolumeClaim (PVC)
- ExternalSecret integration for NFS configuration

## How to Use the Pattern

### 1. Add the library chart as a dependency

In your application chart's `Chart.yaml`:

```yaml
dependencies:
  - name: storage-templates
    version: 0.1.0
    repository: file://../../library/storage-templates
```

### 2. Configure storage in your values.yaml

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
      # Skip creation of PV and PVC for existing applications
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

### 3. Reference the PVC in your Deployment

The library chart will automatically create the PersistentVolume and PersistentVolumeClaim resources. You just need to reference the PVC in your Deployment template:

```yaml
volumes:
  - name: data
    persistentVolumeClaim:
      claimName: {{ .Values.storage.persistence.pvcName | default (printf "%s-pvc" .Release.Name) }}
```

Note: You don't need to create separate template files for the PV and PVC. The library chart handles this automatically.

### 5. Configure External Secrets

If your application already uses External Secrets for other secrets, you can add the NFS_SERVER and NFS_PATH to your existing ExternalSecret resource:

```yaml
data:
  - secretKey: DATABASE_URL
    remoteRef:
      key: secrets/data/my-app
      property: DATABASE_URL
  - secretKey: APP_SECRET
    remoteRef:
      key: secrets/data/my-app
      property: APP_SECRET
  - secretKey: NFS_SERVER
    remoteRef:
      key: secrets/data/platform
      property: NFS_SERVER
  - secretKey: NFS_PATH
    remoteRef:
      key: secrets/data/my-app
      property: NFS_PATH
```

## Vault Configuration

For this pattern to work, you need to store the NFS configuration in Vault:

1. Store the NFS server address in a common location:
   ```
   vault kv put secrets/platform NFS_SERVER=192.168.88.211
   ```

2. Store the application-specific NFS path:
   ```
   vault kv put secrets/my-app NFS_PATH=/volume1/docker/my-app
   ```

## Benefits

This pattern provides several benefits:
- **Consistency**: All applications use the same pattern for persistent storage
- **Security**: NFS credentials are managed securely through External Secrets
- **Flexibility**: Each application can have its own storage size and path
- **Maintainability**: Changes to the storage implementation only need to be made in one place

## Using with Existing Applications

If you have existing applications with PV and PVC resources already created, you can still use this pattern without recreating those resources. This is useful when you want to standardize your storage configuration without risking data loss.

To use this pattern with existing applications:

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

## Example Applications

For a working example of this pattern, see the `docmost` application in `k3s/apps/docmost`.
