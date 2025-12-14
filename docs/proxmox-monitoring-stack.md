# Out-of-Band Monitoring Stack on Proxmox

This tutorial walks through designing and deploying a monitoring platform **outside** of the k3s cluster so you can still see what is happening when the cluster is down. The stack uses dedicated VMs on Proxmox to host Prometheus, Alertmanager, Loki, Grafana, and supporting exporters/log shippers. Automation is delivered via Ansible roles in this repo.

## 1. Target Architecture

| Component | Purpose | Placement |
|-----------|---------|-----------|
| `mon-prom` (2 vCPU / 4 GB RAM / 60 GB disk) | Prometheus, Alertmanager, node-exporter scrape hub | Proxmox VM |
| `mon-logs` (2 vCPU / 6 GB RAM / 120 GB disk) | Loki (or OpenSearch), Promtail/Vector ingress | Proxmox VM |
| `mon-graf` (2 vCPU / 4 GB RAM / 40 GB disk) | Grafana, dashboards, auth proxy | Proxmox VM |
| Optional `mon-net` | Zeek/Suricata, Pi-hole/AdGuard for DNS logging | Proxmox VM |

Key ideas:

* The monitoring VMs live on a separate Proxmox storage pool and power circuit if possible.
* Each VM has static DHCP reservations + DNS A records so certificates and scrape configs are predictable.
* Prometheus scrapes both in-cluster exporters (via k3s ingress/LoadBalancer) and all out-of-band hosts (Proxmox, switches, UPS, etc.).
* Logs and metrics replicate (e.g., Prometheus remote-write to VictoriaMetrics in the cloud, Loki object storage) for disaster recovery.

## 2. Prerequisites

1. Proxmox VE 7.x or newer with a storage pool that has ≥ 300 GB free.
2. Cloud-init enabled Ubuntu 22.04 (or Debian 12) template uploaded to Proxmox.
3. Management VLAN that can reach both the Proxmox host and k3s nodes.
4. DNS zone you can edit plus wildcard (or individual) TLS certificates (Let’s Encrypt or internal CA).
5. Existing Ansible control host (your laptop) with access to this repository and SSH reachability to the Proxmox host + new VMs.

## 2.5 Configure the Monitoring Inventory

Monitoring hosts live in the main Ansible inventory (`ansible/inventory/hosts.yml`). Define a `monitoring` group with child groups for Prometheus, Loki, and Grafana so the playbooks know where to run each role. Hostnames follow the `service.home.lan` convention and DNS/DHCP (e.g., 192.168.88.140‑150) supplies the correct addresses.

```yaml
all:
  children:
    monitoring:
      children:
        prom:
          hosts:
            prom.home.lan:
              monitoring_prometheus_alertmanager_urls:
                - http://localhost:9093
        logs:
          hosts:
            loki.home.lan:
              monitoring_loki_config:
                # trimmed for brevity; see ansible/inventory/hosts.yml for full example
                storage_config:
                  filesystem:
                    directory: /var/lib/loki/chunks
        grafana:
          hosts:
            graf.home.lan:
              monitoring_grafana_domain: graf.home.lan
```

Customize the host‑level variables (ports, retention, storage paths, etc.) as needed; DHCP/DNS will keep the IP assignments consistent so long as the MAC addresses remain tied to the containers.

## 3. Provision VMs on Proxmox

1. **Clone the template.** For each VM (`mon-prom`, `mon-logs`, `mon-graf`), use Proxmox GUI or `qm clone`.
2. **Adjust hardware.** Assign CPU/RAM per the table above (increase RAM for Loki if you expect heavy queries).
3. **Networking.** Attach each VM NIC to the management bridge/vLAN. Configure static addressing in cloud-init or via DHCP reservations.
4. **Boot and verify.** Ensure you can SSH into each VM using your automation user.

Tip: If you prefer automation, wrap these steps in Terraform + Proxmox provider so VM builds are reproducible.

## 4. Base OS Hardening

Before layering monitoring software, bring each VM to a consistent baseline:

```bash
sudo apt update && sudo apt -y dist-upgrade
sudo apt -y install qemu-guest-agent vim git python3-pip ufw
sudo systemctl enable --now qemu-guest-agent
```

* Lock down SSH (`AllowUsers`, disable password auth).
* Enable unattended-upgrades.
* Configure UFW to allow only required ports: `22`, `9090`, `9093`, `3100`, `3000`, `4317`, etc.

These base OS steps (packages, qemu-guest-agent, user/bootstrap tasks) are automated later via the `monitoring_common` Ansible role; layer your preferred firewall policy on top.

## 5. Deploy Prometheus + Alertmanager VM

1. Create system users (`prometheus`, `alertmanager`), directories in `/var/lib/{prometheus,alertmanager}`.
2. Download official tarballs or install via Apt repo (Prometheus community APT).
3. Configure `prometheus.yml` with scrape jobs for:
   * `kubernetes-apiserver` via k3s load balancer
   * `kube-state-metrics`, `node-exporter`, `traefik` metrics endpoints
   * Proxmox host (`node-exporter` + `pve-exporter`)
   * Network gear via SNMP exporter
4. Configure Alertmanager with routes for paging (PagerDuty/ntfy) and notifications (email/Matrix).
5. Enable services via systemd units; verify `systemctl status`.

The repository provides an Ansible role `monitoring_prometheus` that codifies this process.

## 6. Deploy Loki + Promtail (or Vector) VM

1. Install Loki in single-binary or distributed mode (for single node, binary is fine).
2. Configure filesystem or object storage for chunks (e.g., `/var/lib/loki` or S3-compatible bucket).
3. Deploy Promtail/Vector agents on:
   * Proxmox host
   * Monitoring VMs
   * k3s nodes (as DaemonSet)
4. Define scrape configs to capture systemd journald, `/var/log/*`, Kubernetes logs via `promtail + k3s`.
5. Set retention (e.g., 14 days on disk, 90 days in object storage via compactor).

Automation is handled by the `monitoring_loki` Ansible role plus a lightweight `logging_agent` role for Promtail.

## 7. Deploy Grafana VM

1. Install Grafana OSS (APT repo). Harden with SSO (OAuth/OIDC or Auth Proxy).
2. Add Prometheus + Loki data sources.
3. Import dashboards for k3s, Proxmox, and network gear.
4. Configure alert rules (Grafana Alerting) if you need cross-datasource correlation.
5. Publish dashboards via HTTPS (Grafana built-in TLS or an external reverse proxy such as Caddy/Nginx).

`monitoring_grafana` Ansible role handles package install plus datasource/dashboard provisioning so you can layer whichever TLS/auth proxy you prefer.

## 8. Network + DNS Visibility (Optional but Recommended)

* Deploy Pi-hole or AdGuard on `mon-net`, forward to Unbound, and log every query to Loki.
* Install Zeek or Suricata on the Proxmox bridge using `AF_PACKET` capture to record flows, log to Loki/Elastic.
* Enable `node-exporter`, `smartctl_exporter`, and `apcupsd_exporter` on the Proxmox host for hardware insights.

## 9. Integrate k3s Cluster

1. Expose in-cluster metrics via `kube-prometheus-stack` or raw manifests, but ensure ingress is authenticated (mTLS or OAuth).
2. Deploy Promtail DaemonSet with service account limited to log reading.
3. Use VictoriaMetrics or Thanos sidecar in-cluster to ship metrics to the Proxmox Prometheus if you need historical retention when tunnels flap.

## 10. Disaster Testing & Maintenance

* Quarterly: power off each monitoring VM and ensure alerts fire from remaining components.
* Simulate k3s outage; confirm out-of-band stack continues to scrape/alert.
* Regularly snapshot VMs (Proxmox) and backup configuration (`/etc`, `/var/lib/prometheus`, Grafana dashboards) to offline storage.

## 11. Automating with Ansible

The rest of this change introduces Ansible roles that implement the steps above. At a high level:

1. `monitoring_common`: base OS hardening (packages, qemu-guest-agent, timezone, users).
2. `monitoring_prometheus`: installs Prometheus + Alertmanager, systemd units, configuration templates fed by inventory variables.
3. `monitoring_loki`: installs Loki single-binary and configures storage/retention.
4. `monitoring_grafana`: installs Grafana and provisions datasources/dashboards ready for your preferred auth/TLS layer.
5. `logging_agent`: installs and configures Promtail on targets.

Usage example:

```bash
ansible-galaxy install -r ansible/requirements.yml
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/monitoring.yml
```

This entrypoint provisions the Proxmox-hosted containers (starting at VMID 201) and immediately applies the monitoring roles so Prometheus, Loki, Grafana, and Promtail converge in one run.
