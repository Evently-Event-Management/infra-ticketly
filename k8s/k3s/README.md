# Ticketly on K3s

This walkthrough deploys Ticketly with a clear split: Docker Compose keeps the shared infrastructure (Kafka, Redis, MongoDB, Debezium, tooling) on the host, while the Java and Go microservices run on a single-node [k3s](https://k3s.io/) cluster behind Traefik.

## 1. Prerequisites

- k3s v1.27+ on the target host (Traefik and metrics-server remain enabled)
- Docker 24+ and Docker Compose v2 on the same host that runs k3s
- `kubectl` installed locally (or on the server)
- `extract-secrets.sh` executed so that `.env` is populated with the latest Terraform outputs
- Public DNS (or `/etc/hosts`) entries for `api.dpiyumal.me` pointing to the k3s node IP

Grab the node IP with `kubectl get nodes -o wide` (or `hostname -I`) and keep it handy—it must match the address advertised by Kafka.

## 2. Create namespace and shared configuration

```bash
kubectl apply -f k8s/k3s/namespace.yaml
kubectl apply -f k8s/k3s/configs/ticketly-global-config.yaml
```

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

1. Export the advertised host for Kafka (must equal the k3s node IP or a DNS name that resolves to it):

    ```bash
    export KAFKA_PUBLIC_HOST=<K3S_NODE_IP>
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

Each deployment derives the node IP from `status.hostIP`, so the pods connect back to the Docker Compose services on the host. HPAs require the built-in metrics server; confirm readiness with `kubectl get hpa -n ticketly`.

## 6. Configure ingress

Traefik is bundled with k3s, so no extra controller is required. Apply the ingress once DNS (or `/etc/hosts`) points `api.dpiyumal.me` to the node IP:

```bash
kubectl apply -f k8s/k3s/ingress.yaml
```

For quick local testing:

```bash
sudo -- sh -c 'echo "<K3S_NODE_IP> api.dpiyumal.me" >> /etc/hosts'
```

## 7. Observability and tooling

- Kafka UI: `http://$KAFKA_PUBLIC_HOST:9000`
- Debezium Connect API: `http://$KAFKA_PUBLIC_HOST:8083`
- Container logs via Dozzle: `http://$KAFKA_PUBLIC_HOST:9999`
- Application logs: `kubectl logs -n ticketly <pod>`

Add your own Grafana/Loki stack if you need centralized logging—it's no longer deployed automatically.

## 8. Teardown

- Remove the Kubernetes workloads: `kubectl delete -f k8s/k3s/apps/`
- Optionally delete the namespace: `kubectl delete namespace ticketly`
- Stop infrastructure containers and drop volumes: `docker compose down -v`

## Troubleshooting

- **Pods cannot reach Kafka/Redis/MongoDB:** confirm `KAFKA_PUBLIC_HOST` matches the node IP reported by `kubectl get nodes -o wide`, then restart the Docker Compose stack.
- **Kafka keeps advertising `localhost`:** ensure `KAFKA_PUBLIC_HOST` is exported (or present in `.env`) before running `docker compose up`.
- **Debezium connector fails to register:** inspect `debezium-connector-init` logs with `docker compose logs debezium-connector-init`. The script re-runs on container restart.
- **Ingress returns 404:** verify Traefik sees the ingress (`kubectl get ingress -n ticketly`) and that DNS/hosts entries resolve to the node IP.
