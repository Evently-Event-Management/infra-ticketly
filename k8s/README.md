# Ticketly Kubernetes Infrastructure

This directory contains the Kubernetes manifests for deploying the Ticketly microservices infrastructure.

## Architecture

The Ticketly platform consists of the following components:

- **Event Command Service**: Handles event management and seating operations
- **Event Query Service**: Provides read-only access to event data
- **Order Service**: Manages ticket orders and payments
- **Scheduler Service**: Handles scheduling and reminders for events

Supporting infrastructure:
- MongoDB for query service persistence
- Redis for caching and distributed locking
- Kafka for event streaming
- Debezium for Change Data Capture (CDC)
- EFK Stack (Elasticsearch, Fluentd, Kibana) for logging

## Key Differences from Docker Compose Setup

1. **API Gateway Removed**: Kubernetes Ingress Controller now handles routing to services
2. **Horizontal Auto Scaling**: Services can automatically scale based on CPU/memory usage
3. **Dozzle Replaced**: Using EFK stack (Elasticsearch, Fluentd, Kibana) for centralized logging
4. **Improved Resilience**: Health checks, readiness/liveness probes added
5. **Kubernetes Native Resources**: StatefulSets for stateful services, Deployments for stateless services
6. **CORS Handling**: Moved from API Gateway to Ingress Controller

## Directory Structure

```
k8s/
  base/            # Base Kubernetes manifests
    namespace.yaml
    mongodb.yaml
    redis.yaml
    kafka.yaml
    kafka-ui.yaml
    debezium.yaml
    event-command-service.yaml
    event-query-service.yaml
    scheduler-service.yaml
    order-service.yaml
    secrets.yaml
    configmap.yaml
    ingress.yaml
    logging.yaml
    kustomization.yaml
```

## Deployment Instructions

### Prerequisites

1. Kubernetes cluster (EKS, GKE, AKS, or local like minikube)
2. `kubectl` configured to access your cluster
3. `kustomize` installed (included in recent kubectl versions)
4. Environment variables in a `.env` file

### Deploy

```bash
# Deploy all resources
./deploy-k8s.sh
```

### Accessing Services

- **API**: https://api.dpiyumal.me
- **Kafka UI**: https://kafka.dpiyumal.me
- **Logging**: https://logs.dpiyumal.me

## Environment Variables

Ensure you have the following environment variables set in your `.env` file:

- Database credentials (DATABASE_USERNAME, DATABASE_PASSWORD, RDS_ENDPOINT)
- Keycloak client secrets
- AWS credentials and configuration
- SMTP configuration
- Stripe keys

## Secrets Management

In this setup, secrets are loaded from a local `.env` file. For production, consider using:
- Sealed Secrets
- HashiCorp Vault
- AWS Secret Manager or GCP Secret Manager with external-secrets operator

## Ingress Configuration

The Kubernetes Ingress replaces the API Gateway and handles:
- Path-based routing to services
- CORS configuration
- TLS termination

## Horizontal Pod Autoscaling

Services will automatically scale based on:
- CPU utilization (70%)
- Memory utilization (80%)

Min replicas: 2
Max replicas: 10