# Secrets Management for K3s Homelab

This is the main documentation for the secrets management solution for the k3s homelab. The solution provides a secure, automated, and GitOps-friendly approach to managing secrets in the k3s cluster using HashiCorp Vault and External Secrets Operator.

## Documentation

1. [Overview](./secrets-management-overview.md) - High-level overview of the secrets management solution
2. [Implementation Plan](./secrets-management-implementation.md) - Detailed implementation steps
3. [Helper Scripts](./secrets-management-scripts.md) - Helper scripts for managing secrets
4. [Examples](./secrets-management-examples.md) - Example files and directory structure

## Quick Start

1. Install HashiCorp Vault on a Raspberry Pi:
   ```bash
   # Download and install Vault
   wget https://releases.hashicorp.com/vault/1.13.1/vault_1.13.1_linux_arm.zip
   unzip vault_1.13.1_linux_arm.zip
   sudo mv vault /usr/local/bin/
   sudo chmod +x /usr/local/bin/vault
   ```

2. Generate a self-signed certificate:
   ```bash
   # Generate private key
   openssl genrsa -out vault-key.pem 2048

   # Generate certificate
   openssl req -new -x509 -key vault-key.pem -out vault-cert.pem -days 3650 -subj "/CN=vault.local" -addext "subjectAltName = IP:192.168.88.43"
   ```

3. Configure Vault:
   ```bash
   # Create configuration file
   cat > config.hcl << EOF
   ui            = true
   cluster_addr  = "https://192.168.88.43:8201"
   api_addr      = "https://192.168.88.43:8200"
   disable_mlock = true

   storage "raft" {
     path = "/path/to/vault/data"
     node_id = "raft_node_id"
   }

   listener "tcp" {
     address       = "192.168.88.43:8200"
     tls_cert_file = "/path/to/vault/certs/vault-cert.pem"
     tls_key_file  = "/path/to/vault/certs/vault-key.pem"
   }
   EOF
   ```

4. Create a systemd service for Vault:
   ```bash
   # Create systemd service file
   sudo cat > /etc/systemd/system/vault.service << EOF
   [Unit]
   Description=HashiCorp Vault
   Documentation=https://www.vaultproject.io/docs/
   Requires=network-online.target
   After=network-online.target

   [Service]
   User=vault
   Group=vault
   ExecStart=/usr/local/bin/vault server -config=/path/to/vault/config/config.hcl
   ExecReload=/bin/kill -HUP \$MAINPID
   KillMode=process
   KillSignal=SIGINT
   Restart=on-failure
   RestartSec=5
   TimeoutStopSec=30
   StartLimitIntervalSec=60
   StartLimitBurst=3
   LimitNOFILE=65536

   [Install]
   WantedBy=multi-user.target
   EOF

   # Enable and start the service
   sudo systemctl daemon-reload
   sudo systemctl enable vault
   sudo systemctl start vault
   ```

5. Initialize and unseal Vault:
   ```bash
   # Initialize Vault
   export VAULT_ADDR='https://192.168.88.43:8200'
   export VAULT_SKIP_VERIFY=true
   vault operator init -key-shares=3 -key-threshold=2

   # Unseal Vault (run this command twice with different unseal keys)
   vault operator unseal <unseal-key-1>
   vault operator unseal <unseal-key-2>
   ```

6. Create a ConfigMap with the Vault CA certificate:
   ```bash
   # Create ConfigMap
   kubectl create namespace external-secrets
   kubectl create configmap vault-ca --from-file=ca.crt=vault-cert.pem -n external-secrets
   ```

7. Create a Secret with the Vault token:
   ```bash
   # Create Secret
   kubectl create secret generic vault-token --from-literal=token=<vault-token> -n argocd
   ```

8. Install External Secrets Operator:
   ```bash
   # Create Helm chart files
   mkdir -p k3s/platform/external-secrets

   cat > k3s/platform/external-secrets/Chart.yaml << EOF
   apiVersion: v2
   name: external-secrets
   version: 0.1.0
   dependencies:
     - name: external-secrets
       version: 0.8.1
       repository: https://charts.external-secrets.io
   EOF

   cat > k3s/platform/external-secrets/values.yaml << EOF
   external-secrets:
     installCRDs: true
     serviceAccount:
       create: true
       name: external-secrets
     webhook:
       create: true
     certController:
       create: true
   EOF

   # Install External Secrets Operator
   helm dependency update k3s/platform/external-secrets
   helm install external-secrets k3s/platform/external-secrets -n external-secrets
   ```

9. Configure ClusterSecretStore:
   ```bash
   # Create ClusterSecretStore
   mkdir -p k3s/platform/global-secrets

   cat > k3s/platform/global-secrets/secret-store.yaml << EOF
   apiVersion: external-secrets.io/v1beta1
   kind: ClusterSecretStore
   metadata:
     name: vault-backend
   spec:
     provider:
       vault:
         server: "https://192.168.88.43:8200"
         path: "secrets"
         version: "v2"
         caProvider:
           type: ConfigMap
           name: "vault-ca"
           key: "ca.crt"
           namespace: external-secrets
         auth:
           tokenSecretRef:
             name: "vault-token"
             key: "token"
             namespace: "argocd"
   EOF

   kubectl apply -f k3s/platform/global-secrets/secret-store.yaml
   ```

10. Create helper scripts:
    ```bash
    # Create scripts directory
    mkdir -p scripts

    # Create helper scripts as described in Helper Scripts document
    ```

## Key Components

- **HashiCorp Vault** - Secure secrets storage and management
- **External Secrets Operator** - Kubernetes operator for managing secrets
- **ArgoCD** - GitOps tool for deploying applications
- **Vault CA ConfigMap** - ConfigMap with Vault CA certificate for secure communication

## Integration Points

- **Kubernetes** - External Secrets Operator creates Kubernetes secrets
- **Vault** - Secrets are stored and managed in Vault
- **ArgoCD** - ArgoCD deploys ExternalSecret manifests

## Security Considerations

- **Vault Token** - The Vault token used by External Secrets Operator should have minimal permissions
- **Certificate Management** - Regularly rotate the self-signed certificate
- **Vault Backups** - Regularly backup Vault data
- **Monitoring** - Set up monitoring for Vault and External Secrets Operator

## Next Steps

After implementing the solution, consider:

1. **Automating Certificate Management** - Create scripts to automate certificate rotation
2. **Integrating with Ansible** - Create Ansible roles for Vault setup and management
3. **Implementing Secret Rotation** - Set up automated secret rotation
4. **Monitoring and Alerting** - Implement monitoring and alerting for Vault and External Secrets Operator

## Troubleshooting

### Vault Issues

- Check Vault status: `vault status`
- Check Vault logs: `sudo journalctl -u vault`

### External Secrets Operator Issues

- Check External Secrets Operator pods: `kubectl get pods -n external-secrets`
- Check External Secrets Operator logs: `kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets`
- Check ExternalSecret status: `kubectl describe externalsecret <name> -n <namespace>`

### Certificate Issues

- Verify certificate: `openssl x509 -in vault-cert.pem -text -noout`
- Verify ConfigMap: `kubectl get configmap vault-ca -n external-secrets -o yaml`
