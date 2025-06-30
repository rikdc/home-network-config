# n8n Helm Deployment

This directory contains configuration for deploying [n8n](https://n8n.io) using the community `app-template` chart from bjw-s labs.

## Deployment

Add the bjw-s labs Helm repository:

```bash
helm repo add bjw-s https://bjw-s-labs.github.io/helm-charts/
helm repo update
```

Deploy n8n using the provided values file:

```bash
helm install n8n bjw-s/app-template \
  --version 4.1.2 \
  -f values.yaml \
  -n tools
```

### Upgrading

```bash
helm upgrade n8n bjw-s/app-template \
  --version 4.1.2 \
  -f values.yaml \
  -n tools
```

## Configuration

`values.yaml` configures persistence, secrets and ingress. Persistence uses an NFS mount:

```yaml
controllers:
  main:
    containers:
      main:
        image:
          repository: n8nio/n8n
          tag: latest
        envFrom:
          - secretRef:
              name: n8n-secrets
persistence:
  config:
    type: nfs
    server: nas.home.lan
    path: /volume1/docker/n8n
    globalMounts:
      - path: /home/node/.n8n
service:
  main:
    ports:
      http:
        port: 5678
ingress:
  main:
    hosts:
      - host: n8n.home.lan
        paths:
          - path: /
            pathType: Prefix
            service:
              identifier: main
              port: http
```

Secrets are retrieved through an `ExternalSecret` named `n8n-external-secret`.

