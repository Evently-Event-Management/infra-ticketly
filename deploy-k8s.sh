#!/bin/bash

# Deploy Kubernetes resources with kustomize
echo "Deploying Ticketly infrastructure to Kubernetes..."

# Create a namespace first
kubectl apply -f k8s/base/namespace.yaml

# Handle the secrets
echo "Creating secrets..."
# In a real environment, you'd use a proper secret management solution
# This is a placeholder to remind you to set up your secrets properly
kubectl create secret generic ticketly-secrets --from-env-file=.env -n ticketly --dry-run=client -o yaml | kubectl apply -f -

# Create the GCP credentials secret
if [ -f "./credentials/gcp-credentials.json" ]; then
  kubectl create secret generic gcp-credentials --from-file=gcp-credentials.json=./credentials/gcp-credentials.json -n ticketly --dry-run=client -o yaml | kubectl apply -f -
else
  echo "Warning: GCP credentials file not found. Make sure to create this secret manually."
fi

# Apply all resources using kustomize
kubectl apply -k k8s/base/

# Wait for core infrastructure to be ready
echo "Waiting for core infrastructure to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n ticketly
kubectl wait --for=condition=available --timeout=300s deployment/redis -n ticketly
kubectl wait --for=condition=available --timeout=300s statefulset/kafka -n ticketly

echo "Core infrastructure is ready. Waiting for services to become available..."
kubectl wait --for=condition=available --timeout=300s deployment/event-command-service -n ticketly
kubectl wait --for=condition=available --timeout=300s deployment/event-query-service -n ticketly
kubectl wait --for=condition=available --timeout=300s deployment/scheduler-service -n ticketly
kubectl wait --for=condition=available --timeout=300s deployment/order-service -n ticketly

echo "All services are available. Waiting for Debezium connector initialization..."
kubectl wait --for=condition=complete job/debezium-connector-init -n ticketly --timeout=180s

echo "Ticketly infrastructure deployment completed successfully!"
echo "You can access:"
echo " - API Gateway at https://api.dpiyumal.me"
echo " - Kafka UI at https://kafka.dpiyumal.me"
echo " - Logging Dashboard at https://logs.dpiyumal.me"