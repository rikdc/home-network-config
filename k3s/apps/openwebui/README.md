# OpenWebUI Helm Deployment

This directory contains the configuration for deploying OpenWebUI using Helm.

## About OpenWebUI

OpenWebUI is an extensible, self-hosted AI interface that adapts to your workflow while operating entirely offline. It supports various LLM runners like Ollama and OpenAI-compatible APIs with built-in inference engine for RAG (Retrieval-Augmented Generation).

## Prerequisites

1. The NFS storage classes must be deployed:
   ```bash
   kubectl apply -f ../../nfs-storage-class.yaml
   ```

2. The namespaces must exist:
   ```bash
   kubectl apply -f ../../namespaces.yaml
   ```

3. The persistent volumes and claims must be created:
   ```bash
   kubectl apply -f ../../persistent-volumes/tools/openwebui.yaml
   ```

## Deployment

Add the OpenWebUI Helm repository:

```bash
helm repo add open-webui https://helm.openwebui.com/
helm repo update
```

Deploy OpenWebUI using the values file:

```bash
helm install openwebui open-webui/open-webui \
  -f values.yaml \
  -n tools
```

## Upgrading

To upgrade the deployment:

```bash
helm upgrade openwebui open-webui/open-webui \
  -f values.yaml \
  -n tools
```

## Configuration

The `values.yaml` file contains the configuration for the OpenWebUI deployment. Key configurations include:

### Ollama Integration

The deployment can either connect to an external Ollama instance or deploy Ollama as part of the Helm chart:

- External Ollama: Set `ollama.enabled: false` and configure `ollamaUrls` with the IP address of your Ollama instance
- Integrated Ollama: Set `ollama.enabled: true` and configure resource limits as needed

### Database Configuration

OpenWebUI requires a PostgreSQL database. The connection string is configured via the `DATABASE_URL` environment variable. For security reasons, the database password should be stored in a Kubernetes secret rather than directly in the values.yaml file.

### Storage Configuration

The deployment uses persistent storage for both the main application and pipelines:

- **Configuration**: Stores application configuration and pipeline data
  - PV: `openwebui-config-pv`
  - PVC: `openwebui-config-pvc`
  - Size: 1Gi
  - Access Mode: ReadWriteOnce
  - NFS Path: /volume1/docker/openwebui

### Resource Configuration

Resource requests and limits can be configured to match your cluster's capabilities:

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "500Mi"
  limits:
    cpu: "1000m"
    memory: "1Gi"
```

## Accessing the Application

Once deployed, OpenWebUI will be available at:

http://chat.home.lan

Make sure your DNS is configured to resolve this hostname to your ingress controller's IP address.

### Troubleshooting Access Issues

If you encounter "Bad Gateway" or "Not Found" errors when accessing the application, check the following:

1. Ensure the ingress controller is properly configured
2. Verify that the service is running correctly:
   ```bash
   kubectl get pods -n tools
   kubectl get svc -n tools
   kubectl describe ingress -n tools
   ```
3. Check the logs for any errors:
   ```bash
   kubectl logs -n tools $(kubectl get pods -n tools -l app=openwebui -o name)
   ```

The configuration in this repository includes:
- Service port set to 8080 (the default port for OpenWebUI)
- Ingress path type set to "Prefix" for better compatibility
- Timezone set to "America/New_York" (adjust as needed)

## Security Considerations

The original configuration included a database password in plain text in the values.yaml file. This has been updated to use a Kubernetes secret instead.

### Creating the Database Secret

A helper script has been provided to create the necessary Kubernetes secret:

```bash
# Make the script executable if needed
chmod +x create-db-secret.sh

# Run the script (will use 'tools' namespace by default)
./create-db-secret.sh
```

The script will:
1. Prompt for the database password and other connection details
2. Create a Kubernetes secret containing the full database URL
3. Provide commands for deploying or upgrading OpenWebUI

The values.yaml file has been updated to reference this secret instead of containing the password directly:

```yaml
extraEnvVars:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: openwebui-db-credentials
        key: database-url
