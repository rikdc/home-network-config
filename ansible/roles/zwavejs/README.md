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


    zwavejs_keys_s2_unauthenticated
    zwavejs_keys_s2_authenticated
    zwavejs_keys_s2_accesscontrol
    zwavejs_keys_s0_legacy

The various security keys required by S2 Authenication

## Dependencies

None

## Example Playbook

    - hosts: all
    roles:
        - role: jellyfin

## License

MIT
