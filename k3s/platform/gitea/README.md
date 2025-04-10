# Gitea Setup

This directory contains the configuration files and scripts needed to deploy Gitea in a Kubernetes cluster with an external PostgreSQL database.

## Prerequisites

- Kubernetes cluster (k3s)
- External PostgreSQL database (running at 192.168.88.30)
- NFS server for persistent storage (at 192.168.88.211)
- Helm installed

## Setup Process

1. Create the necessary Kubernetes secrets:

   ```bash
   # Make the scripts executable
   chmod +x setup.sh
   ./setup.sh

   # Run each script as instructed
   ./create-db-secret.sh
   ./create-admin-secret.sh
   ./create-redis-secret.sh
   ```

2. Create the persistent volume and claim:

   ```bash
   kubectl apply -f ../../persistent-volumes/tools/gitea.yaml
   ```

3. Deploy Gitea using Helm:

   ```bash
   helm repo add gitea https://dl.gitea.com/charts/
   helm install gitea gitea/gitea -f values.yaml -n tools
   ```

## Configuration Details

### Database Configuration

Gitea is configured to use an external PostgreSQL database. The database credentials are stored in a Kubernetes secret named `gitea-db-credentials`.

### Admin User

The initial admin user credentials are stored in a Kubernetes secret named `gitea-admin-credentials`.

### Redis

Redis is used for caching and is deployed as part of the Helm chart. The Redis password is stored in a Kubernetes secret named `gitea-redis-credentials`.

### Persistence

Gitea data is stored on an NFS share. The persistent volume and claim are defined in `../../persistent-volumes/tools/gitea.yaml`.

### Ingress

Gitea is exposed via an Ingress at `git.home.lan`. Make sure this hostname is resolvable in your network.

## Security Notes

- All sensitive information (passwords, credentials) is stored in Kubernetes secrets
- The values.yaml file does not contain any hardcoded credentials
- For production use, consider enabling TLS for the Ingress
