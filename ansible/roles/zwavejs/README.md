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

    zwavejs_container_name: "zwave-js-ui"

Name of the Docker container.

    zwavejs_docker_image_name: "zwavejs/zwave-js-ui"

Base name of the Docker image to use for the container.

    zwavejsui_docker_image_version: "latest"

Specific Docker image version to use for the container.

    zwavejs_docker_use_volumes

Create and use Docker volumes for storing data. True when you want to use volumes.

    zwavejs_conf_dir

 Directory on filesystem to use for storing data files. Used when zwavejs_docker_use_volumes is false.

## Dependencies

None

## Example Playbook

    - hosts: all
        roles:
            - role: zwavejs

## License

MIT
