# Ticketly on K3s

This guide mirrors the Docker Compose setup on a single-node [k3s](https://k3s.io/) cluster. Redis and MongoDB are installed from their Helm charts, Kafka and the application services run from manifests in this directory, and the built-in Traefik ingress controller replaces the Spring Cloud Gateway.

## 1. Prerequisites

- k3s v1.27+ running on your server (Traefik and metrics-server are enabled by default)
- kubectl and Helm v3.12+ installed on your workstation (or directly on the server)
- `extract-secrets.sh` run so that `.env` contains the latest Terraform outputs
- Public DNS (or `/etc/hosts`) entries for `api.dpiyumal.me`, `kafka.dpiyumal.me`, and `logs.dpiyumal.me` pointing to the k3s server IP

Grab the server IP with `kubectl get nodes -o wide` (or `hostname -I` locally) and keep it handy for DNS/hosts updates.

## 2. Create namespace and shared configuration

```bash
kubectl apply -f k8s/k3s/namespace.yaml
kubectl apply -f k8s/k3s/configs/ticketly-global-config.yaml
```

## 3. Create secrets

Secrets are templated so you can inject the values produced by `extract-secrets.sh` without editing every manifest.

1. Generate a Kubernetes-compatible environment file and create the main secret:

    ```bash
    # Generate environment files (also writes credentials/google-private-key.pem)
    ./scripts/extract-secrets.sh --k8s
    
    # Create the secret from the .env.k8s file and the PEM that contains newlines
    kubectl create secret generic ticketly-app-secrets \
      --namespace ticketly \
      --from-env-file=.env.k8s \
      --from-file=GOOGLE_PRIVATE_KEY=credentials/google-private-key.pem \
      --dry-run=client -o yaml \
      > k8s/k3s/secrets/app-secrets.yaml
    ```

    The `--k8s` flag generates `.env.k8s` **and** writes `credentials/google-private-key.pem`. Because the Google key contains newlines, it must be provided via `--from-file` instead of an environment variable.

    Alternatively, you can run:
    ```bash
    # Generate only the K8s compatible .env file without extracting other secrets
    ./scripts/extract-secrets.sh k8s-only
    ```

    Review the generated file to ensure all values are properly encoded, remove any unused keys, then apply it:

    ```bash
    kubectl apply -f k8s/k3s/secrets/app-secrets.yaml
    ```

2. Create the service-account JSON secret so the Java service can mount the file:

    ```bash
    kubectl create secret generic ticketly-gcp-credentials       --namespace ticketly       --from-file=google-credentials.json=credentials/gcp-credentials.json       --dry-run=client -o yaml       > k8s/k3s/secrets/gcp-credentials.yaml

    kubectl apply -f k8s/k3s/secrets/gcp-credentials.yaml
    ```

3. If you keep credential files elsewhere, copy them into the same manifest before applying.

## 4. Provision infrastructure with Helm

Add the upstream repositories once:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Install the charts in the `ticketly` namespace using the provided overrides (single replica, persistence enabled on the default `local-path` storage class):

```bash
helm upgrade --install redis bitnami/redis   --namespace ticketly   --create-namespace   -f k8s/k3s/infra/redis-values.yaml

helm upgrade --install mongodb bitnami/mongodb   --namespace ticketly   -f k8s/k3s/infra/mongodb-values.yaml

helm upgrade --install ticketly-logs grafana/loki-stack   --namespace ticketly   -f k8s/k3s/logging/loki-stack-values.yaml
```

MongoDB provisions a 5 Gi PVC on the default `local-path` storage class; delete the `data-mongodb-0` PVC in the `ticketly` namespace if you need to reset the database between runs. The Loki stack deploys Grafana with an ingress at `logs.dpiyumal.me`; change the host inside `loki-stack-values.yaml` if you prefer a different domain.

## 5. Deploy Kafka and supporting workloads

```bash
kubectl apply -f k8s/k3s/apps/kafka.yaml
kubectl wait --namespace ticketly --for=condition=ready pod -l app=kafka --timeout=180s

kubectl apply -f k8s/k3s/apps/debezium-connect.yaml
kubectl wait --namespace ticketly --for=condition=ready pod -l app=debezium-connect --timeout=180s
```

Kafka uses a 10 Gi PVC on the default storage class; delete the `data-kafka-0` PVC if you need to wipe broker logs and offsets.

## 6. Deploy application services

Apply the services and HPAs once secrets and infra are ready:

```bash
kubectl apply -f k8s/k3s/apps/event-command.yaml
kubectl apply -f k8s/k3s/apps/event-query.yaml
kubectl apply -f k8s/k3s/apps/order-service.yaml
kubectl apply -f k8s/k3s/apps/scheduler-service.yaml
kubectl apply -f k8s/k3s/apps/kafka-ui.yaml
```

HPAs require the metrics-server, which k3s enables by default. Use `kubectl get hpa -n ticketly` to monitor scaling behaviour.

## 7. Register the Debezium connector

Once the connect worker is running and the target PostgreSQL instance is reachable, apply the bootstrap ConfigMap + Job:

```bash
kubectl apply -f k8s/k3s/jobs/debezium-bootstrap.yaml
kubectl logs -n ticketly job/debezium-connector-init -f
```

Delete the job whenever you need to re-run it:

```bash
kubectl delete job -n ticketly debezium-connector-init
```

## 8. Configure ingress

Traefik ships with k3s, so no extra ingress controller is required. Apply the ingress manifest after DNS (or `/etc/hosts`) points to the server IP:

```bash
kubectl apply -f k8s/k3s/ingress.yaml
```

Ingress rules mirror the Spring Cloud Gateway routing:

- `api.dpiyumal.me` handles the microservice paths (`/api/event-seating`, `/api/event-query`, `/api/order`, `/api/scheduler`).
- `kafka.dpiyumal.me` serves the Kafka UI deployment.
- The Loki stack chart exposes Grafana under `logs.dpiyumal.me` (see step 4).

For quick local testing, add entries to `/etc/hosts`:

```bash
sudo -- sh -c 'echo "<SERVER_IP> api.dpiyumal.me kafka.dpiyumal.me logs.dpiyumal.me" >> /etc/hosts'
```

Replace `<SERVER_IP>` with the public or private address of your k3s node.

## 9. Observability and logs

- Grafana (from the Loki stack) is available at `https://logs.dpiyumal.me` (or `http://` if you do not add TLS). Default credentials are `admin` / `admin`.
- Kafka UI lives at `https://kafka.dpiyumal.me` once TLS is installed; by default it serves over HTTP.
- Use `kubectl logs` or Grafana Loki queries to inspect application logs.

## 10. Teardown and upgrades

- Remove workloads: `kubectl delete -f` the manifests in reverse order.
- Uninstall charts: `helm uninstall redis mongodb ticketly-logs -n ticketly`.
- Delete PVCs if you also want to drop persisted data: `kubectl delete pvc data-mongodb-0 data-kafka-0 -n ticketly`.
- Delete the namespace when finished: `kubectl delete namespace ticketly`.

## Troubleshooting

- If services cannot reach external AWS resources, double-check the `ticketly-app-secrets` content, especially `AWS_REGION`, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY`.
- When redeploying the Debezium job, ensure the target tables and heartbeat table exist; otherwise the bootstrap will exit with a schema error.
- If HPAs remain in the `Unknown` state, confirm the metrics API is working: `kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes | jq '.'`.
- Traefik uses the `traefik` ingress class by default. If you install a different controller, update `ingressClassName` in `k8s/k3s/ingress.yaml` accordingly.
