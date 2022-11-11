# Jellyfin

Configures Jellyfin Media Server

## Requirements

Ansible 2.10 or newer.

## Role Variables

    jellyfin_volumes

Used by pre-tasks to determine which mounts to configure on the server

    jellyfin_volumes:
        - { src: '//media.server/video', dest: '/mnt/video' }
        - { src: '//media.server/books', dest: '/mnt/books' }

## Dependencies

None

## Example Playbook

    - hosts: all
    roles:
        - role: jellyfin

## License

MIT
