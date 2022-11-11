## Influx

Installs and configures an InfluxDb container

## Requirements

Docker

## Variable

| Variable                          | Required | Default                           | Choices | Comments                                      |
|-----------------------------------|----------|-----------------------------------|---------|-----------------------------------------------|
| influxdb_container_name           | yes      | influxdb                          | string  | Docker image to use                           |
| influxdb_root_dir                 | yes      | /docker/{influxdb_container_name} | string  |                                               |
| influxdb_conf_dir                 | yes      | {{ influxdb_root_dir }}/conf      | string  |                                               |
| influxdb_data_dir                 | yes      | {{ influxdb_root_dir }}/data      | string  |                                               |
| influxdb_docker_networks          | yes      | []                                | list    | Additional networks to bind the container too |
| influxdb_container_restart_policy | yes      | always                            | string  |                                               |
| influxdb_users                    | yes      |                                   |         |                                               |

## Dependencies

## Example Playbook

## License

MIT
