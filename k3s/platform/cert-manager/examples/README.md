# Certificate Manager Examples

This directory contains example configurations for using cert-manager with various services in the k3s cluster.

## Contents

- `service-certificates.yaml`: Example certificate configurations for common services
- `service-ingress.yaml`: Example Traefik IngressRoute configurations with TLS

## Usage

### Creating Certificates for New Services

1. Copy and modify the certificate template:
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: your-service-tls
  namespace: your-namespace
spec:
  secretName: your-service-tls-secret
  duration: 2160h  # 90 days
  renewBefore: 360h  # 15 days
  subject:
    organizations:
      - Home Lab
  commonName: your-service.home.lan
  dnsNames:
    - your-service.home.lan
    - your-service.your-namespace.home.lan
  issuerRef:
    name: vault-issuer
    kind: ClusterIssuer
  secretTemplate:
    annotations:
      reloader.stakater.com/reload: "true"
```

### Creating Ingress for New Services

1. Copy and modify the IngressRoute template:
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: your-service
  namespace: your-namespace
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`your-service.home.lan`)
      kind: Rule
      middlewares:
        - name: https-redirect
      services:
        - name: your-service
          port: your-port
  tls:
    secretName: your-service-tls-secret
```

## Best Practices

1. **Naming Conventions**
   - Certificate name: `<service-name>-tls`
   - Secret name: `<service-name>-tls-secret`
   - DNS names: Include both direct and namespaced variants

2. **Security**
   - Always use HTTPS redirect middleware
   - Include reloader annotation for automatic certificate updates
   - Use appropriate namespace isolation

3. **DNS Configuration**
   - Primary domain: `<service>.home.lan`
   - Namespaced domain: `<service>.<namespace>.home.lan`

4. **Certificate Duration**
   - Standard duration: 90 days
   - Renewal buffer: 15 days
   - Consistent across all services

## Verification

After applying certificates:

1. Check certificate status:
```bash
kubectl get certificate -n <namespace>
```

2. Verify secret creation:
```bash
kubectl get secret <service-name>-tls-secret -n <namespace>
```

3. Check IngressRoute:
```bash
kubectl get ingressroute -n <namespace>
```

## Troubleshooting

1. **Certificate Not Issued**
   - Check cert-manager logs
   - Verify ClusterIssuer status
   - Check Vault connectivity

2. **Ingress Issues**
   - Verify TLS secret exists
   - Check Traefik logs
   - Validate DNS resolution

3. **HTTPS Redirect Issues**
   - Verify middleware exists
   - Check Traefik configuration
   - Validate entryPoints configuration

## Adding New Services

1. Create certificate in appropriate namespace
2. Create IngressRoute with TLS
3. Verify certificate issuance
4. Test HTTPS access
5. Verify automatic renewal setup

Remember to always use the https-redirect middleware to ensure secure access to your services.
