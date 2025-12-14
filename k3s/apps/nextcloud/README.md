# Nextcloud with Office (Collabora)

This directory contains the configuration required to deploy Nextcloud together with the bundled Collabora Online (Nextcloud Office) suite on the k3s cluster.

## About

The deployment wraps the upstream [`nextcloud/nextcloud` Helm chart](https://github.com/nextcloud/helm) and enables the Collabora subchart so that browser-based document editing works out of the box. The instance is intended to be exposed at `http://docs.home.lan` while Collabora is published separately at `http://collabora.home.lan`.

## Prerequisites

1. The namespaces used by the chart must already exist:
   ```bash
   kubectl apply -f ../../namespaces.yaml
   ```

2. Provision the persistent volume that backs Nextcloud's data directory. This chart templates the PV/PVC objects, so applying the Helm release will create them referencing your NFS server defined in `values.yaml`.

3. Ensure the External Secrets Operator is installed and that the `vault-kv` `ClusterSecretStore` is configured. The deployment expects credentials to live under the Vault key `nextcloud` with the following properties:
   - `NEXTCLOUD_ADMIN_USER`
   - `NEXTCLOUD_ADMIN_PASSWORD`
   - `NEXTCLOUD_DB_USERNAME`
   - `NEXTCLOUD_DB_PASSWORD`
   - `REDIS_PASSWORD`
   - `COLLABORA_ADMIN_USER`
   - `COLLABORA_ADMIN_PASSWORD`

## Deployment

Add and update the Nextcloud Helm repository (only required once):

```bash
helm repo add nextcloud https://nextcloud.github.io/helm/
helm repo update
```

Install the release into the `tools` namespace:

```bash
helm install nextcloud nextcloud/nextcloud \
  -f values.yaml \
  -n tools
```

## Upgrading

To apply configuration changes or upgrade the chart/app versions:

```bash
helm upgrade nextcloud nextcloud/nextcloud \
  -f values.yaml \
  -n tools
```

## Configuration Highlights

- **Ingress**: Requests for `docs.home.lan` and `collabora.home.lan` are routed through the Traefik ingress controller. TLS is disabled by default; enable it by adding certificates to the `ingress.tls` and `collabora.ingress.tls` sections if desired.
- **Storage**: An NFS-backed volume is defined for the Nextcloud data directory (`nextcloud-data-pv`). Adjust capacity or the NFS path before deploying if different storage is required.
- **Database**: The chart is configured to use an existing PostgreSQL instance (`externalDatabase`). Update `externalDatabase.host`, `externalDatabase.user`, and `externalDatabase.database` in `values.yaml` to match your server. The username and password are pulled from Vault.
- **Caching**: Redis is enabled to provide file locking and caching support, improving performance and reliability.
- **Collabora Online**: The Collabora dependency is switched on and exposed via its own ingress at `collabora.home.lan`. The alias group is pre-populated so Collabora trusts the Nextcloud host.

Review `values.yaml` for additional tunables such as resource requests, cron scheduling, and trusted domains.

## Access

Once deployed, Nextcloud is reachable at: `http://docs.home.lan`

Collabora Online is reachable at: `http://collabora.home.lan`

DNS entries should point these hostnames at the ingress controller's address.
