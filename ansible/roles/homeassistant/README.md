# Home Assistant

Configures an instance of Home Assistant

## Requirements

Ansible 2.10 or newer.
Docker
MQTT
ZWaveJSUI

## Role Variables

## Dependencies

Create a secrets.yaml file in the files/ directory.

## Example Playbook

  - hosts: all
      roles:
      - role: homeassistant

## License

MIT
