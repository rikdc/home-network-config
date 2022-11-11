# Docker

Configures Docker on the given server

## Requirements

Ansible 2.10 or newer.

## Role Variables

  ubuntu_version

The ubuntu version being used.

## Dependencies

None

## Example Playbook

- hosts: all
    roles:
  - role: docker

## License

MIT
