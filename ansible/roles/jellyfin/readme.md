# Jellyfin

Configures Jellyfin Media Server

## Requirements

-

## Role Variables

jellyfin_volumes

Used by pre-tasks to determine which mounts to configure on the server

```yaml
jellyfin_volumes:
    - { src: '//media.server/video', dest: '/mnt/video' }
    - { src: '//media.server/books', dest: '/mnt/books' }
```

## Dependencies

-

## Example Playbook

-

## License

MIT
