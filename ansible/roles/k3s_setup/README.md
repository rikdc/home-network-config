# k3s_setup

This role sets up a k3s Kubernetes cluster with a controller and worker nodes.

## Requirements

- Ubuntu/Debian-based systems
- SSH access to all nodes
- Sudo privileges

## Role Variables

### Common Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `k3s_packages_update` | Whether to update apt cache | `true` |
| `k3s_packages_upgrade` | Whether to upgrade all packages | `true` |

### Helm Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `k3s_helm_charts` | List of Helm charts to add | See below |

Default Helm charts:
```yaml
k3s_helm_charts:
  - name: csi-driver-nfs
    repo: https://kubernetes-csi.github.io/charts
```

### NFS CSI Driver Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `k3s_nfs_csi_namespace` | Namespace for NFS CSI driver | `kube-system` |
| `k3s_nfs_csi_kubelet_dir` | Kubelet directory for NFS CSI driver | `/var/lib/kubelet` |

### Node Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `k3s_server_url_template` | URL template for k3s server | `"https://{{ hostvars['k3s-controller']['ansible_host'] }}:6443"` |
| `k3s_node_token_path` | Path to node token on controller | `/var/lib/rancher/k3s/server/node-token` |

## Dependencies

None.

## Example Playbook

```yaml
- name: Set up k3s Kubernetes cluster
  hosts: k3s
  become: true
  roles:
    - role: k3s_setup

- name: Set up persistent storage
  hosts: k3s-controller
  become: true
  roles:
    - role: k8s_persistent_storage
      vars:
        kubeconfig_path: /etc/rancher/k3s/k3s.yaml
```

## Role Structure

```
k3s_setup/
├── defaults/
│   └── main.yml       # Default variables
├── meta/
│   └── main.yml       # Role metadata
└── tasks/
    ├── main.yml       # Main task file that includes other task files
    ├── common.yml     # Common tasks for all nodes (package updates, NFS client)
    ├── controller.yml # Controller-specific tasks (k3s server, Helm, NFS CSI driver)
    └── node.yml       # Node-specific tasks (k3s agent setup)
```

## Task Descriptions

### common.yml
- Updates apt cache
- Upgrades all packages
- Installs NFS client

### controller.yml
- Installs k3s server
- Installs Helm
- Sets up Helm repositories
- Installs NFS CSI driver
- Creates NFS Storage Class

### node.yml
- Waits for controller to generate node token
- Fetches node token from controller
- Installs k3s agent on node

## License

MIT

## Author Information

rikdc
