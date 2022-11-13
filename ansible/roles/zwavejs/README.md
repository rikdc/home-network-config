# Zwave JS UI

Configures ZwaveJS Docker

## Requirements

Ansible 2.10 or newer.
Docker

## Role Variables

  ansible_nas_timezone

Timezone code for the container.

  zwavejs_device

Zwave serial device to attach to the Docker container

## Dependencies

None

## Example Playbook

    - hosts: all
    roles:
        - role: jellyfin

## License

MIT
