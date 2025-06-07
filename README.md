# Home Network Configuration

This repository contains the configuration for my homelab network infrastructure, primarily using Ansible for automation.

## K3s Cluster

The inventory file `ansible/inventory/hosts.yml` defines the nodes that form the
K3s cluster. The older `k3s_setup` role has been replaced by tasks provided by
the Kubernetes community Ansible collections. Install these collections with:

```bash
ansible-galaxy collection install kubernetes.core community.kubernetes
```

Alternatively they can be installed from `ansible/requirements.yml` using:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

Once the collections are installed, deploy the cluster and persistent storage
with the provided playbook:

```bash
ansible-playbook ansible/playbooks/k3s-setup.yml -i ansible/inventory/hosts.yml
```

Persistent volumes are configured on the controller host via variables in
`host_vars/k3s-controller.yml`. The `k8s_persistent_storage` role provisions the
volumes so they are shared between nodes for high performance workloads.
