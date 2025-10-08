# Frigate Template

A Helm chart template for deploying Frigate NVR (Network Video Recorder) with proper security and resource management.

## Features

- Non-root user execution
- Proper resource limits and requests
- External secret integration for sensitive data
- Coral USB/PCI TPU support
- RTSP, RTMP, and WebRTC support
- Configurable ingress with TLS
- Persistent storage for recordings and media
- Health checks (liveness, readiness, startup)

## Prerequisites

- Kubernetes 1.16+
- Helm 3.0+
- Access to a Coral TPU (optional but recommended)
- MQTT broker for notifications
- RTSP camera streams

## Installing the Chart

To install the chart with the release name `my-frigate`:

```bash
helm install my-frigate .
```

## Configuration

The following table lists the configurable parameters of the Frigate chart and their default values.

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `namespace` | Namespace to deploy to | `tools` |
| `secretName` | Name of the Kubernetes secret containing sensitive data | `frigate-secrets` |
| `image.tag` | Frigate image tag | `0.16.1` |
| `mqtt.host` | MQTT broker hostname | `mqtt.home.local` |
| `mqtt.port` | MQTT broker port | `1883` |
| `coral.device` | Coral TPU device | `usb` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `256Mi` |
| `resources.limits.memory` | Memory limit | `2Gi` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.host` | Ingress hostname | `frigate.home.local` |
| `ingress.tlsSecret` | TLS secret name | `frigate-tls` |
| `persistence.data.size` | Data volume size | `20Gi` |
| `persistence.data.storageClass` | Data storage class | `local-path` |
| `persistence.media.size` | Media volume size | `500Gi` |
| `persistence.media.storageClass` | Media storage class | `local-path` |
| `persistence.apex.enabled` | Enable Coral TPU device | `true` |

## External Secrets

This template expects a Kubernetes secret with the following keys:

- `mqtt-user`: MQTT username
- `mqtt-password`: MQTT password
- `rtsp-password`: RTSP camera password

Create the secret using:

```bash
kubectl create secret generic frigate-secrets \
  --from-literal=mqtt-user='your-mqtt-user' \
  --from-literal=mqtt-password='your-mqtt-password' \
  --from-literal=rtsp-password='your-rtsp-password'
```

## Camera Configuration

Update the `go2rtc.streams` section in the configMap with your actual camera streams. The template includes placeholder entries that need to be replaced with your camera URLs.

## Resource Requirements

The default resource requests are minimal. Adjust based on your hardware and number of cameras:

- 1-2 cameras: Default settings
- 3-5 cameras: Increase memory limit to 4Gi
- 6+ cameras: Increase memory limit to 8Gi and CPU requests to 500m

## Storage

The chart creates two persistent volumes:

1. `data`: For Frigate's database and configuration (20Gi default)
2. `media`: For recordings and snapshots (500Gi default)

Adjust the sizes based on your retention requirements.

## TLS Configuration

To enable TLS, create a TLS secret:

```bash
kubectl create secret tls frigate-tls \
  --cert=path/to/cert.pem \
  --key=path/to/key.pem
```

## Verification

Check that the deployment is running:

```bash
kubectl get pods -n tools
kubectl get svc -n tools
```

Access the UI at https://frigate.home.local (or your configured hostname).

## Troubleshooting

1. **Camera streams not working**: Verify RTSP URLs and credentials in the configMap
2. **MQTT not connecting**: Check MQTT broker availability and credentials
3. **Storage issues**: Verify storage class availability and permissions
4. **Coral TPU not detected**: Check device path and permissions

For more information, visit the [Frigate documentation](https://docs.frigate.video/).