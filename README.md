# Home Network Configuration

This repository contains the configuration for my homelab network infrastructure, primarily using Ansible for automation.

## K3s Cluster

The inventory file `ansible/inventory/hosts.yml` defines the nodes that form the
K3s cluster. Cluster provisioning is handled by the [k3s-ansible](https://github.com/k3s-io/k3s-ansible) role while storage tasks from the former `k3s_setup` role have been merged into `k8s_persistent_storage`. Install the required Ansible collections with:

```bash
ansible-galaxy collection install kubernetes.core community.kubernetes
```

Alternatively they can be installed from `ansible/requirements.yml` using:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

Once the collections are installed and the cluster has been provisioned with
`k3s-ansible`, run the following playbook to configure persistent storage:

```bash
ansible-playbook ansible/playbooks/k3s-setup.yml -i ansible/inventory/hosts.yml
```

Persistent volumes are configured on the controller host via variables in
`host_vars/k3s-controller.yml`. The `k8s_persistent_storage` role provisions the
volumes so they are shared between nodes for high performance workloads.
