# MQTT

Configures a VS Code Container

## Requirements

Ansible 2.10 or newer.
Docker

## Role Variables

    code_server_enabled

If true, container is created.

    code_server_available_externally

Configures firewall rules to allow external access.

    code_server_config_directory

    code_server_projects_directory

    code_server_user_id

    code_server_group_id
    code_server_port: "8443"
    code_server_hostname: "code-server"
    code_server_memory: 1g
    code_server_container_name: code_server

## Dependencies

None

## Example Playbook

  - hosts: all
      roles:
      - role: codeserver

## License

MIT
