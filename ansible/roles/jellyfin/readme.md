## Role Name

Jellyfin

## Requirements

Docker

## Variables

### jellyfin_volumes

Used by pre-tasks to determine which mounts to configure on the server

```yaml
jellyfin_volumes:
    - { src: '//media.server/video', dest: '/mnt/video' }
    - { src: '//media.server/books', dest: '/mnt/books' }
```

## Dependencies

### Variables

- docker_daemon_options


## Example Playbook

## License

