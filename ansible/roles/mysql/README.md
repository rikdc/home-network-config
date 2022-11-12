# MySQL

Configures a MySQL Server

## Requirements

- Ansible 2.10 or newer.
- [community.mysql.mysql_user module](https://docs.ansible.com/ansible/latest/collections/community/mysql/mysql_user_module.html)

## Role Variables

```yaml
  mysql_backups_dir: /var/mysql/backups
```

The directory to store backups

```yaml
  mysql_conf_dir: /etc/mysql/conf.d
```

The configuration directory. The templated my.cnf will be placed here.

```yaml
  mysql_character_set: utf8mb4
```

Specifies which MySQL [character set](https://www.mysqltutorial.org/mysql-character-set/) to use

```yaml
  mysql_collation: utf8mb4_unicode_520_ci
```

Specifies which MySQL [collationt](https://www.mysqltutorial.org/mysql-collation/) to use

```yaml
  mysql_config_mysqld:
    max_connections: 500
    skip_name_resolve: "true"
```

mysqld configurations

```yaml
  mysql_container_name: mysql
```

Name of the docker container

```yaml
  mysql_env: {}
```

Additional environment variables to include

```yaml
  mysql_lib_dir: /var/mysql/lib
```

Location for the lib directory (data is stored here as well)

```yaml
  mysql_network: mysql
```

Internal network name to use

```yaml
  mysql_port: 3306
```

MySQL Port to listen on

```yaml
  mysql_state: started
```

The docker container state.

```yaml
  mysql_users:
    regular:
      - {username: 'homeassistant', password: 'homeassistant', host: "localhost", database: 'homeassistant'}
```

Users to configure on the initial step.

## Dependencies

None

## Example Playbook

```yaml
  - hosts: mufasa.local

    vars_files:
      - default.config.yml

    roles:
      - role: mysql
        become: true
```

## License

MIT
