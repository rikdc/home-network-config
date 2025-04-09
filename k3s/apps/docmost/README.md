# Docmost

This directory contains the configuration for deploying [Docmost](https://github.com/docmost/docmost) on the k3s cluster.

Docmost is an open-source knowledge base and documentation platform that helps teams organize and share knowledge efficiently.

## Prerequisites

- Kubernetes cluster
- PostgreSQL database (external or in-cluster)
- NFS storage for persistent data

## Storage Configuration

The persistent volume and claim for Docmost are defined in:
- `k8s/persistent-volumes/tools/docmost.yaml`

This configuration creates:
- A 5Gi persistent volume for Docmost data
- A corresponding persistent volume claim in the `tools` namespace

## Database Configuration

Docmost requires a PostgreSQL database. The connection details are stored in a Kubernetes secret.

To create the database secret:

1. Run the provided script:
   ```bash
   ./k8s/apps/docmost/create-db-secret.sh
   ```

2. Follow the prompts to enter:
   - Database password
   - Database username (default: docmost)
   - Database host (default: 192.168.88.30)
   - Database name (default: docmost)
   - Kubernetes namespace (default: tools)

The script will create a secret named `docmost-db-credentials` in the specified namespace.

## Application Secret Configuration

Docmost requires a secure application secret for encryption and session management. This secret must be at least 32 characters long.

To create the application secret:

1. Run the provided script:
   ```bash
   ./k8s/apps/docmost/create-app-secret.sh
   ```

2. The script will:
   - Generate a secure random string
   - Prompt for the namespace (default: tools)
   - Create a Kubernetes secret named `docmost-app-secret`

This secret will be used by the application for secure operations.

## Redis Configuration

Docmost requires Redis for caching and session management. The deployment includes a Redis sidecar container that runs alongside the main application. This approach simplifies deployment by not requiring a separate Redis instance.

The Redis container:
- Uses the official Redis Alpine image
- Stores data in an ephemeral volume (data will be lost on pod restart)
- Is accessible to the main application via localhost

## Deployment

Since Docmost doesn't have an official Helm chart, we'll deploy it using Kubernetes manifests.

1. Apply the persistent volume and claim:
   ```bash
   kubectl apply -f k8s/persistent-volumes/tools/docmost.yaml
   ```

2. Create the database secret:
   ```bash
   ./k8s/apps/docmost/create-db-secret.sh
   ```

3. Create the application secret:
   ```bash
   ./k8s/apps/docmost/create-app-secret.sh
   ```

4. Apply all resources at once:
   ```bash
   kubectl apply -f k8s/apps/docmost/
   ```

## Configuration Options

The deployment files contain the following key configurations:

- **Persistence**: Uses the `docmost-data-pvc` persistent volume claim
- **Database**: Uses the `docmost-db-credentials` secret for database connection
- **Application Secret**: Uses the `docmost-app-secret` for secure operations
- **Redis**: Runs as a sidecar container within the same pod
- **Ingress**: Configured to use `docs.home.lan` as the host
- **Resources**: CPU and memory limits and requests
- **Environment Variables**: Configuration for the Docmost application

## Accessing Docmost

Once deployed, Docmost will be available at:
- http://docs.home.lan

## Upgrading

To upgrade an existing Docmost deployment:

```bash
kubectl apply -f k8s/apps/docmost/
```

## Troubleshooting

If you encounter issues:

1. Check the pod status:
   ```bash
   kubectl get pods -n tools -l app=docmost
   ```

2. View the docmost container logs:
   ```bash
   kubectl logs -n tools -l app=docmost -c docmost
   ```

3. View the redis container logs:
   ```bash
   kubectl logs -n tools -l app=docmost -c redis
   ```

4. Verify the database connection:
   ```bash
   kubectl describe secret docmost-db-credentials -n tools
   ```

5. Verify the application secret:
   ```bash
   kubectl describe secret docmost-app-secret -n tools
   ```

6. Check persistent volume claim status:
   ```bash
   kubectl get pvc -n tools | grep docmost
