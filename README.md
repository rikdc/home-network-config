# home-network-config

## :open_book: Overview
This repository contains everything I use to setup and manage my home network.

* Internal DNS Servers
* OpenVPN Server
* Docker Containers

* Workstations
  - My personal MacBook

ansible-galaxy install -r requirements.yml
ansible-galaxy collection install ansible.posix

# Bootstrapping

https://github.com/nfaction/ansible-collection-bootstrap/blob/c715f1381ccf15b450776fef29619fe2aa7832d2/roles/bootstrap/tasks/main.yml


# Molecule
https://github.com/nfaction/ansible-collection-bootstrap/blob/c715f1381ccf15b450776fef29619fe2aa7832d2/roles/bootstrap/.github/workflows/molecule.yml


Installation

    Ensure Apple's command line tools are installed (xcode-select --install to launch the installer).
    Install Ansible.
    Clone this repository to your local drive.
    Run $ ansible-galaxy install -r requirements.yml inside this directory to install required Ansible roles.
    Run ansible-playbook main.yml -i inventory -K inside this directory. Enter your account password when prompted.

https://github.com/nfaction/ansible-collection-bootstrap/blob/c715f1381ccf15b450776fef29619fe2aa7832d2/roles/ssh_port_probe/tasks/main.yml

## Security

https://docs.openstack.org/ansible-hardening/latest/
https://github.com/alivx/CIS-Ubuntu-20.04-Ansible


## Self Hosted Services

### Statistics
https://github.com/davestephens/ansible-nas/tree/master/roles/stats


## Ansible

- https://github.com/zahodi/ansible-mikrotik

https://github.com/mtabishk/ansible-playbooks/tree/main/docker_container_conf

https://unix.stackexchange.com/questions/16694/copy-input-to-clipboard-over-ssh
https://github.com/LearnLinuxTV/personal_ansible_desktop_configs
https://github.com/bennylope/macbook-configuration/blob/master/roles/golang/tasks/main.yml


https://github.com/lework/Ansible-roles/blob/master/docker/tasks/main.yml
https://github.com/mpereira/macbook-playbook#security
https://github.com/uschti/mac-default-playbook


https://github.com/bloodymage/ansible-collection-autonomy

# Conventions

This repository follows the standard conventions

https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html#role-directory-structure
# https://github.com/lisenet/homelab-ansible/blob/master/roles/hl.hardening/tasks/setup-RedHat.yml
