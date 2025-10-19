# Ticketly on K3s

This walkthrough deploys Ticketly with a clear split: Docker Compose keeps the shared infrastructure (Kafka, Redis, MongoDB, Debezium, tooling) on the host, while the Java and Go microservices run on a single-node [k3s](https://k3s.io/) cluster behind Traefik.

## 1. Prerequisites

- k3s v1.27+ on the target host (Traefik and metrics-server remain enabled)
- Docker 24+ and Docker Compose v2 on the same host that runs k3s
- `kubectl` installed locally (or on the server)
- `extract-secrets.sh` executed so that `.env` is populated with the latest Terraform outputs
- Public DNS (or `/etc/hosts`) entries for `api.dpiyumal.me` pointing to the k3s node IP

Grab the node IP with `kubectl get nodes -o wide` (or `hostname -I`) and keep it handy—it must match the address advertised by Kafka.

If you're copying the cluster config from `/etc/rancher/k3s/k3s.yaml`, place it at `~/.kube/config`, ensure ownership (`sudo chown $(id -u):$(id -g) ~/.kube/config`) and permissions (`chmod 600 ~/.kube/config`), then set `export KUBECONFIG=$HOME/.kube/config` (add it to your shell profile so non-sudo `kubectl` uses the local file).

## 2. Create namespace and shared configuration

```bash
kubectl apply -f k8s/k3s/namespace.yaml
kubectl apply -f k8s/k3s/configs/ticketly-global-config.yaml
```

Make sure `INFRA_HOST` inside `k8s/k3s/configs/ticketly-global-config.yaml` points to the server hosting Kafka, Redis, and MongoDB (default: `10.160.0.7`) before applying the ConfigMap.

## 3. Create secrets

Secrets are templated so you can inject Terraform outputs without editing manifests manually.

1. Generate a Kubernetes-compatible env file and render the secrets:

    ```bash
    # Generate .env.k8s and credentials/google-private-key.pem
    ./scripts/extract-secrets.sh --k8s

    kubectl create secret generic ticketly-app-secrets \
      --namespace ticketly \
      --from-env-file=.env.k8s \
      --dry-run=client -o yaml \
      > k8s/k3s/secrets/app-secrets.yaml

    kubectl create secret generic ticketly-google-private-key \
      --namespace ticketly \
      --from-file=GOOGLE_PRIVATE_KEY=credentials/google-private-key.pem \
      --dry-run=client -o yaml \
      > k8s/k3s/secrets/google-private-key.yaml
    ```

    Alternative (only write `.env.k8s`):

    ```bash
    ./scripts/extract-secrets.sh k8s-only
    ```

    Apply the generated manifests after reviewing the contents:

    ```bash
    kubectl apply -f k8s/k3s/secrets/app-secrets.yaml
    kubectl apply -f k8s/k3s/secrets/google-private-key.yaml
    ```

2. Create the service-account JSON secret so the command service can mount it:

    ```bash
    kubectl create secret generic ticketly-gcp-credentials \
      --namespace ticketly \
      --from-file=google-credentials.json=credentials/gcp-credentials.json \
      --dry-run=client -o yaml \
      > k8s/k3s/secrets/gcp-credentials.yaml

    kubectl apply -f k8s/k3s/secrets/gcp-credentials.yaml
    ```

3. If credentials live elsewhere, update the rendered YAML before applying it.

## 4. Start shared infrastructure with Docker Compose

1. Export the advertised host for Kafka (use the server where the Docker Compose infrastructure runs—`10.160.0.7` by default):

    ```bash
    export KAFKA_PUBLIC_HOST=<INFRA_HOST>
    ```

    You can persist this value inside `.env` so `docker compose` picks it up automatically.

2. Bring up the infrastructure stack from the repository root:

    ```bash
    docker compose up -d query-db redis kafka kafka-ui debezium-connect debezium-connector-init dozzle
    ```

    The stack publishes Redis (6379), MongoDB (27017), Kafka (9092), Debezium (8083), Kafka UI (9000), and Dozzle (9999) on the host. Verify with `docker compose ps` and wait for the health checks to turn green.

## 5. Deploy microservices to k3s

Apply the workloads once the infrastructure containers are healthy:

```bash
kubectl apply -f k8s/k3s/apps/event-command.yaml
kubectl apply -f k8s/k3s/apps/event-query.yaml
kubectl apply -f k8s/k3s/apps/order-service.yaml
kubectl apply -f k8s/k3s/apps/scheduler-service.yaml
```

Each deployment now reads the shared infrastructure host from the ConfigMap, so the pods connect to the Docker Compose services running on the external server. HPAs require the built-in metrics server; confirm readiness with `kubectl get hpa -n ticketly`.

## 6. Enable TLS certificates

Install cert-manager so Traefik can request certificates from Let's Encrypt:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

Create the ClusterIssuer that cert-manager will use (update the email in the manifest if needed):

```bash
kubectl apply -f k8s/k3s/infra/cert-manager-clusterissuer.yaml
```

You can inspect the status with:

```bash
kubectl describe clusterissuer ticketly-letsencrypt
```

Wait until the issuer shows `Ready=True` before applying the ingress.

## 7. Configure ingress

Traefik is bundled with k3s, so no extra controller is required. Apply the ingress once DNS (or `/etc/hosts`) points `api.dpiyumal.me` to the node IP:

```bash
kubectl apply -f k8s/k3s/ingress.yaml
```

Traefik and cert-manager will issue a certificate for `api.dpiyumal.me` automatically; track the request with `kubectl describe certificate ticketly-api-tls -n ticketly` and `kubectl get challenges -A` if troubleshooting is needed.

For quick local testing:

```bash
sudo -- sh -c 'echo "<K3S_NODE_IP> api.dpiyumal.me" >> /etc/hosts'
```

## 8. Observability and tooling

### Infrastructure monitoring

- Kafka UI: `http://$KAFKA_PUBLIC_HOST:9000`
- Debezium Connect API: `http://$KAFKA_PUBLIC_HOST:8083`
- Container logs via Dozzle: `http://$KAFKA_PUBLIC_HOST:9999`
- Application logs: `kubectl logs -n ticketly <pod>`

### Kubernetes dashboard

A lightweight Kubernetes dashboard is included to monitor cluster resources:

```bash
# Deploy the dashboard
kubectl apply -f k8s/k3s/monitoring/dashboard.yaml

# Add DNS entry (if not already done)
sudo -- sh -c 'echo "<K3S_NODE_IP> logs.dpiyumal.me" >> /etc/hosts'
```

Access the dashboard at `http://logs.dpiyumal.me` to view:
- Node information
- Pod counts and status
- Deployment status
- Horizontal Pod Autoscaler metrics

The dashboard auto-refreshes every 30 seconds and requires minimal resources.

## 9. Teardown

- Remove the Kubernetes workloads: `kubectl delete -f k8s/k3s/apps/`
- Optionally delete the namespace: `kubectl delete namespace ticketly`
- Stop infrastructure containers and drop volumes: `docker compose down -v`

## Troubleshooting

- **Pods cannot reach Kafka/Redis/MongoDB:** confirm `INFRA_HOST` in the ConfigMap and `KAFKA_PUBLIC_HOST` in your environment both reference the infrastructure server IP/DNS, then restart the Docker Compose stack if needed.
- **Kafka keeps advertising `localhost`:** ensure `KAFKA_PUBLIC_HOST` is exported (or present in `.env`) before running `docker compose up`.
- **Debezium connector fails to register:** inspect `debezium-connector-init` logs with `docker compose logs debezium-connector-init`. The script re-runs on container restart.
- **Ingress returns 404:** verify Traefik sees the ingress (`kubectl get ingress -n ticketly`) and that DNS/hosts entries resolve to the node IP.
