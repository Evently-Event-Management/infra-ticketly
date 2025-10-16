# Ticketly on Minikube

This guide replaces the `docker-compose.yml` stack with a Kubernetes setup tailored for a single-node Minikube cluster. Redis and MongoDB come from their official Helm charts, Kafka and the application services run from the manifests in this folder, and ingress rules take over the routing behavior that the API gateway previously handled.

## 1. Prerequisites

- Minikube v1.33+ and kubectl
- Helm v3.12+
- `extract-secrets.sh` has been executed so that `.env` contains the latest Terraform outputs
- Domains (`api.dpiyumal.me`, `kafka.dpiyumal.me`, `logs.dpiyumal.me`) resolve to the Minikube IP (update `/etc/hosts` for local testing)

Enable required Minikube addons:

```bash
minikube addons enable ingress
minikube addons enable metrics-server
```

## 2. Create namespace and shared configuration

```bash
kubectl apply -f k8s/minikube/namespace.yaml
kubectl apply -f k8s/minikube/configs/ticketly-global-config.yaml
```

## 3. Create secrets

Secrets are intentionally templated so you can inject the real values quickly:

1. Generate the main secret from `.env` (edit the Google key afterwards so the multi-line block is preserved):

    ```bash
    kubectl create secret generic ticketly-app-secrets \
      --namespace ticketly \
      --from-env-file=.env \
      --dry-run=client -o yaml \
      > k8s/minikube/secrets/app-secrets.yaml
    ```

    Open the generated file, ensure the `GOOGLE_PRIVATE_KEY` entry uses the multi-line block style shown in `app-secrets.template.yaml`, and remove any unused keys. Apply it with:

    ```bash
    kubectl apply -f k8s/minikube/secrets/app-secrets.yaml
    ```

2. Create the service-account JSON secret so the Java service can mount the file:

    ```bash
    kubectl create secret generic ticketly-gcp-credentials \
      --namespace ticketly \
      --from-file=google-credentials.json=credentials/gcp-credentials.json \
      --dry-run=client -o yaml \
      > k8s/minikube/secrets/gcp-credentials.yaml

    kubectl apply -f k8s/minikube/secrets/gcp-credentials.yaml
    ```

3. If you keep credential files elsewhere, copy them into the same secret manifest before applying.

## 4. Provision infrastructure with Helm

Add the upstream repositories once:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Install the charts into the `ticketly` namespace with the provided values overrides (tuned for Minikube: single replica, no persistence):

```bash
helm upgrade --install redis bitnami/redis \
  --namespace ticketly \
  --create-namespace \
  -f k8s/minikube/infra/redis-values.yaml

helm upgrade --install mongodb bitnami/mongodb \
  --namespace ticketly \
  -f k8s/minikube/infra/mongodb-values.yaml

helm upgrade --install ticketly-logs grafana/loki-stack \
  --namespace ticketly \
  -f k8s/minikube/logging/loki-stack-values.yaml
```

MongoDB now provisions a 5Gi persistent volume on the cluster's default StorageClass; delete the `data-mongodb-0` PVC in the `ticketly` namespace if you need to reset the database between runs. The Loki stack deploys Grafana with an ingress at `logs.dpiyumal.me`; change the host inside `loki-stack-values.yaml` if you prefer another domain.

## 5. Deploy Kafka and supporting workloads

```bash
kubectl apply -f k8s/minikube/apps/kafka.yaml
kubectl wait --namespace ticketly --for=condition=ready pod -l app=kafka --timeout=180s

kubectl apply -f k8s/minikube/apps/debezium-connect.yaml
kubectl wait --namespace ticketly --for=condition=ready pod -l app=debezium-connect --timeout=180s
```

Kafka now uses a 10Gi persistent volume claim on the default StorageClass; delete the `data-kafka-0` PVC in the `ticketly` namespace if you need to wipe broker logs and offsets.

## 6. Deploy application services

Apply the services and HPAs in any order once secrets and infra are ready:

```bash
kubectl apply -f k8s/minikube/apps/event-command.yaml
kubectl apply -f k8s/minikube/apps/event-query.yaml
kubectl apply -f k8s/minikube/apps/order-service.yaml
kubectl apply -f k8s/minikube/apps/scheduler-service.yaml
kubectl apply -f k8s/minikube/apps/kafka-ui.yaml
```

Scale targets are managed by HPAs (requires the metrics-server addon). Use `kubectl get hpa -n ticketly` to observe actual scaling behavior.

## 7. Register the Debezium connector

Once the connect worker is running and the target PostgreSQL instance is reachable, apply the bootstrap ConfigMap + Job:

```bash
kubectl apply -f k8s/minikube/jobs/debezium-bootstrap.yaml
kubectl logs -n ticketly job/debezium-connector-init -f
```

Delete the job whenever you need to re-run it:

```bash
kubectl delete job -n ticketly debezium-connector-init
```

## 8. Configure ingress

```bash
kubectl apply -f k8s/minikube/ingress.yaml
```

The rules reproduce the API gateway behavior:

- `api.dpiyumal.me` with path-based routing (`/api/event-seating`, `/api/event-query`, `/api/order`, `/api/scheduler`).
- `kafka.dpiyumal.me` serves the Kafka UI deployment.
- The Loki stack chart exposes Grafana under `logs.dpiyumal.me` (see step 4).

For local Minikube, map the domain names to the Minikube IP:

```bash
minikube ip
sudo -- sh -c 'echo "$(minikube ip) api.dpiyumal.me kafka.dpiyumal.me logs.dpiyumal.me" >> /etc/hosts'
```

## 9. Observability and logs

- Grafana (from the Loki stack) is available at `https://logs.dpiyumal.me` (or `http://` if you do not add TLS). The default credentials are `admin` / `admin`.
- Kafka UI lives at `https://kafka.dpiyumal.me` once you provide TLS; by default it is `http`.
- Use `kubectl logs` or Grafana Loki searches for application logs.

## 10. Teardown and upgrades

- Remove workloads: `kubectl delete -f` the manifests in reverse order.
- Uninstall charts: `helm uninstall redis mongodb ticketly-logs -n ticketly`.
- Delete PVCs if you also want to drop persisted data: `kubectl delete pvc data-mongodb-0 data-kafka-0 -n ticketly`.
- Delete namespace when finished: `kubectl delete namespace ticketly`.

## Troubleshooting

- If services cannot reach external AWS resources, double-check the `ticketly-app-secrets` content, especially `AWS_REGION`, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY`.
- When redeploying the Debezium job, ensure the target tables and heartbeat table exist; otherwise the bootstrap will exit with a schema error.
- If HPAs stay in the `Unknown` state, confirm that the metrics-server addon is running: `kubectl get pods -n kube-system | grep metrics-server`.
- Minikube’s built-in ingress controller expects hostnames to resolve to the cluster IP; use `minikube tunnel` if you need LoadBalancer semantics.
