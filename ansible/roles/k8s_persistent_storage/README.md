# Kubernetes Persistent Storage Role

This Ansible role installs the NFS CSI driver, creates the required StorageClass and then provisions Kubernetes PersistentVolumes (PVs) and PersistentVolumeClaims (PVCs) based on configuration defined in host_vars.

## Requirements

- Kubernetes cluster (e.g., k3s) must be running
- NFS server must be accessible
- `kubernetes.core` collection must be installed

## Role Variables

Variables are defined in `defaults/main.yml` and can be overridden in host_vars:

| Variable | Description | Default |
|----------|-------------|---------|
| default_namespace | Default namespace for PVCs | default |
| kubeconfig_path | Path to kubeconfig file | /etc/rancher/k3s/k3s.yaml |
| storage_class_name | Default storage class name | nfs-storage |
| nfs_server | Default NFS server IP/hostname | "" |
| nfs_path | Default NFS path | "" |
| helm_charts | Helm repositories to add for CSI driver | see defaults |
| nfs_csi_namespace | Namespace for the NFS CSI driver | kube-system |
| nfs_csi_kubelet_dir | Kubelet directory used by the CSI driver | /var/lib/kubelet |

## Host Variables Structure

The role expects the following structure in your host_vars file:

```yaml
persistent_storage:
  nfs_server: 192.168.x.x
  nfs_path: /path/to/nfs/share
  storage_class_name: nfs-storage

persistent_volumes:
  - name: volume-name-pv
    labels:
      type: shared
      content: media
    capacity:
      storage: 1 # in Ti
    accessModes:
      - ReadWriteMany
    persistentVolumeReclaimPolicy: Retain
    storageClassName: nfs-storage
    nfs:
      server: 192.168.x.x  # Optional, falls back to persistent_storage.nfs_server
      path: /path/to/nfs/share  # Optional, falls back to persistent_storage.nfs_path
    namespace: default  # Optional, defaults to 'default'
```

## Example Playbook

```yaml
- name: Setup Kubernetes persistent storage
  hosts: k3s-controller
  tasks:
    - name: Include k8s_persistent_storage role
      include_role:
        name: k8s_persistent_storage
```

## Notes

- PVCs are created with the same name as the PV but with "-pvc" suffix
- The role will use NFS server and path from the PV definition if provided, otherwise it will use the global settings from persistent_storage
