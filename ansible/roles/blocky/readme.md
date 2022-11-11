# Blocky

Configures the Blocky DNS Server

## Requirements

Ansible 2.10 or newer.

## Role Variables

  blocky_config_path

The destination of the Blocky configuration file

## Dependencies

None

## Example Playbook

  - hosts: all
      roles:
    - role: blocky

## License

MIT
