#!/bin/bash

set -e

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Ticketly Local Kubernetes Deployment ===${NC}"

# Check for kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check if minikube or kind is installed
if command -v minikube &> /dev/null; then
    KUBE_TOOL="minikube"
    echo -e "${GREEN}Found Minikube, will use it for local deployment.${NC}"
elif command -v kind &> /dev/null; then
    KUBE_TOOL="kind"
    echo -e "${GREEN}Found kind, will use it for local deployment.${NC}"
else
    echo -e "${YELLOW}Neither Minikube nor kind found. Please install one of them first.${NC}"
    echo "Visit: https://minikube.sigs.k8s.io/docs/start/ or https://kind.sigs.k8s.io/docs/user/quick-start/"
    exit 1
fi

# Start local Kubernetes cluster if not already running
if [ "$KUBE_TOOL" = "minikube" ]; then
    echo -e "${GREEN}Checking Minikube status...${NC}"
    if ! minikube status | grep -q "Running"; then
        echo -e "${YELLOW}Starting Minikube cluster...${NC}"
        minikube start --memory=4096 --cpus=2 --driver=docker
        
        # Enable ingress addon
        echo -e "${GREEN}Enabling Ingress controller...${NC}"
        minikube addons enable ingress
    else
        echo -e "${GREEN}Minikube is already running.${NC}"
    fi
elif [ "$KUBE_TOOL" = "kind" ]; then
    echo -e "${GREEN}Checking kind clusters...${NC}"
    if ! kind get clusters | grep -q "ticketly"; then
        echo -e "${YELLOW}Creating kind cluster...${NC}"
        
        # Create a kind config file with port mappings
        cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ticketly
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
        kind create cluster --config kind-config.yaml
        
        # Install NGINX Ingress Controller
        echo -e "${GREEN}Installing NGINX Ingress Controller...${NC}"
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
        
        # Wait for ingress controller to be ready
        echo -e "${GREEN}Waiting for Ingress controller to be ready...${NC}"
        kubectl wait --namespace ingress-nginx \
          --for=condition=ready pod \
          --selector=app.kubernetes.io/component=controller \
          --timeout=90s
    else
        echo -e "${GREEN}Kind cluster 'ticketly' already exists.${NC}"
    fi
fi

# Create a local development .env file if it doesn't exist
if [ ! -f ".env.local" ]; then
    echo -e "${GREEN}Creating .env.local file with sample values...${NC}"
    cat <<EOF > .env.local
# Database credentials (using local instances)
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=password123
RDS_ENDPOINT=host.minikube.internal
AWS_REGION=local
AWS_S3_BUCKET_NAME=ticketly-local-bucket
AWS_ACCESS_KEY_ID=dummy
AWS_SECRET_ACCESS_KEY=dummy

# Keycloak client secrets
EVENTS_SERVICE_CLIENT_SECRET=dummy-secret
EVENT_PROJECTION_CLIENT_SECRET=dummy-secret
SCHEDULER_CLIENT_SECRET=dummy-secret
TICKET_CLIENT_SECRET=dummy-secret

# Order service
QR_SECRET_KEY=4RJUEJDURgKarhbwx3fjKA8Fy/KoFwpAmOWAGwiWU9A=
STRIPE_SECRET_KEY=dummy
STRIPE_WEBHOOK_SECRET=dummy
ORDER_POSTGRES_DSN=postgres://postgres:password123@host.minikube.internal:5432/order_service

# Scheduler service
SCHEDULER_POSTGRES_DSN=postgres://postgres:password123@host.minikube.internal:5432/scheduler_service
AWS_SQS_SESSION_SCHEDULING_ARN=arn:aws:sqs:local:000000000000:session-scheduling
AWS_SQS_SESSION_SCHEDULING_URL=http://localhost:4566/000000000000/session-scheduling
AWS_SQS_TRENDING_JOB_ARN=arn:aws:sqs:local:000000000000:trending-job
AWS_SQS_TRENDING_JOB_URL=http://localhost:4566/000000000000/trending-job
AWS_SQS_SESSION_REMINDERS_ARN=arn:aws:sqs:local:000000000000:session-reminders
AWS_SQS_SESSION_REMINDERS_URL=http://localhost:4566/000000000000/session-reminders
AWS_SCHEDULER_ROLE_ARN=dummy
AWS_SCHEDULER_GROUP_NAME=dummy

# Email settings
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USERNAME=dummy
SMTP_PASSWORD=dummy
FROM_EMAIL=noreply@ticketly.local
FROM_NAME=Ticketly Local
EOF
    echo -e "${GREEN}Created .env.local file. Please edit it if needed.${NC}"
else
    echo -e "${GREEN}.env.local file already exists, will use that.${NC}"
fi

# Create a local GCP credentials file if it doesn't exist
if [ ! -d "./credentials" ]; then
    mkdir -p "./credentials"
fi

if [ ! -f "./credentials/gcp-credentials.json" ]; then
    echo -e "${GREEN}Creating dummy GCP credentials file...${NC}"
    cat <<EOF > "./credentials/gcp-credentials.json"
{
  "type": "service_account",
  "project_id": "dummy-project",
  "private_key_id": "dummy",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7VJTUt9Us8cKj\nMzEfYyjiWA4R4/M2bS1GB4t7NXp98C3SC6dVMvDuictGeurT8jNbvJZHtCSuYEvu\nNMoSfm76oqFvAp8Gy0iz5sxjZmSnXyCdPEovGhLa0VzMaQ8s+CLOyS56YyCFGeJZ\n-----END PRIVATE KEY-----\n",
  "client_email": "dummy@dummy-project.iam.gserviceaccount.com",
  "client_id": "000000000000000000000",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/dummy%40dummy-project.iam.gserviceaccount.com"
}
EOF
    echo -e "${GREEN}Created dummy GCP credentials file.${NC}"
fi

# Create a local development overlay for Kubernetes
echo -e "${GREEN}Creating local development overlay for Kubernetes...${NC}"

# Create the overlay directory structure
mkdir -p k8s/overlays/local

# Create a local kustomization.yaml
cat <<EOF > k8s/overlays/local/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ticketly

resources:
  - ../../base

# Patches to adjust base resources for local development
patches:
  # Update the Ingress hosts to use local domains
  - target:
      kind: Ingress
      name: ticketly-ingress
    patch: |-
      - op: replace
        path: /spec/rules/0/host
        value: api.ticketly.test
      - op: replace
        path: /spec/rules/1/host
        value: kafka.ticketly.test
      - op: replace
        path: /spec/tls/0/hosts/0
        value: api.ticketly.test
      - op: replace
        path: /spec/tls/1/hosts/0
        value: kafka.ticketly.test
  
  # Disable TLS for local development
  - target:
      kind: Ingress
      name: ticketly-ingress
    patch: |-
      - op: remove
        path: /spec/tls
  
  # Reduce resource requests for local development
  - target:
      kind: Deployment
      name: event-command-service
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/resources/requests/cpu
        value: 100m
      - op: replace
        path: /spec/template/spec/containers/0/resources/requests/memory
        value: 256Mi

  # Reduce replicas for HPAs in local environment
  - target:
      kind: HorizontalPodAutoscaler
      name: event-command-service
    patch: |-
      - op: replace
        path: /spec/minReplicas
        value: 1

  - target:
      kind: HorizontalPodAutoscaler
      name: event-query-service
    patch: |-
      - op: replace
        path: /spec/minReplicas
        value: 1

  - target:
      kind: HorizontalPodAutoscaler
      name: scheduler-service
    patch: |-
      - op: replace
        path: /spec/minReplicas
        value: 1

  - target:
      kind: HorizontalPodAutoscaler
      name: order-service
    patch: |-
      - op: replace
        path: /spec/minReplicas
        value: 1
EOF

# Create hostAliases patch for local development
cat <<EOF > k8s/overlays/local/host-aliases.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: event-command-service
spec:
  template:
    spec:
      hostAliases:
      - ip: "192.168.65.2" # Docker for Mac host IP
        hostnames:
        - "host.docker.internal"
        - "host.minikube.internal"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: event-query-service
spec:
  template:
    spec:
      hostAliases:
      - ip: "192.168.65.2"
        hostnames:
        - "host.docker.internal"
        - "host.minikube.internal"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scheduler-service
spec:
  template:
    spec:
      hostAliases:
      - ip: "192.168.65.2"
        hostnames:
        - "host.docker.internal"
        - "host.minikube.internal"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
spec:
  template:
    spec:
      hostAliases:
      - ip: "192.168.65.2"
        hostnames:
        - "host.docker.internal"
        - "host.minikube.internal"
EOF

# Add the host-aliases patch to kustomization
echo "  - host-aliases.yaml" >> k8s/overlays/local/kustomization.yaml

# Create local ConfigMap patches
cat <<EOF > k8s/overlays/local/config-patches.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ticketly-config
data:
  KEYCLOAK_URL: "http://host.minikube.internal:9080"
  KEYCLOAK_REALM: "event-ticketing"
  KEYCLOAK_ISSUER_URI: "http://host.minikube.internal:9080/realms/event-ticketing"
  KEYCLOAK_JWK_SET_URI: "http://host.minikube.internal:9080/realms/event-ticketing/protocol/openid-connect/certs"
EOF

# Add the config-patches to kustomization
echo "  - config-patches.yaml" >> k8s/overlays/local/kustomization.yaml

# Update the hosts file entry reminder
echo -e "${YELLOW}Don't forget to add these entries to your /etc/hosts file:${NC}"
echo "127.0.0.1 api.ticketly.test"
echo "127.0.0.1 kafka.ticketly.test"
echo "127.0.0.1 logs.ticketly.test"

# Deploy to local Kubernetes
echo -e "${GREEN}Deploying to local Kubernetes...${NC}"

# Create a namespace first
kubectl apply -f k8s/base/namespace.yaml

# Handle the secrets
echo -e "${GREEN}Creating secrets...${NC}"
kubectl create secret generic ticketly-secrets --from-env-file=.env.local -n ticketly --dry-run=client -o yaml | kubectl apply -f -

# Create the GCP credentials secret
kubectl create secret generic gcp-credentials --from-file=gcp-credentials.json=./credentials/gcp-credentials.json -n ticketly --dry-run=client -o yaml | kubectl apply -f -

# Apply all resources using kustomize with local overlay
echo -e "${GREEN}Applying Kubernetes manifests with local overlay...${NC}"
kubectl apply -k k8s/overlays/local/

# Wait for core infrastructure to be ready
echo -e "${GREEN}Waiting for core infrastructure to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n ticketly
kubectl wait --for=condition=available --timeout=300s deployment/redis -n ticketly
kubectl wait --for=condition=available --timeout=300s statefulset/kafka -n ticketly

echo -e "${GREEN}Core infrastructure is ready. Waiting for services to become available...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/event-command-service -n ticketly
kubectl wait --for=condition=available --timeout=300s deployment/event-query-service -n ticketly
kubectl wait --for=condition=available --timeout=300s deployment/scheduler-service -n ticketly
kubectl wait --for=condition=available --timeout=300s deployment/order-service -n ticketly

echo -e "${GREEN}All services are available. Waiting for Debezium connector initialization...${NC}"
kubectl wait --for=condition=complete job/debezium-connector-init -n ticketly --timeout=180s || echo "Debezium connector initialization may not be complete. Check the logs for details."

echo -e "${GREEN}Ticketly infrastructure deployment completed successfully!${NC}"
echo -e "${GREEN}You can access:${NC}"
echo " - API Gateway at http://api.ticketly.test"
echo " - Kafka UI at http://kafka.ticketly.test"
echo " - Logging Dashboard at http://logs.ticketly.test"

if [ "$KUBE_TOOL" = "minikube" ]; then
    echo -e "${YELLOW}Note: If using Minikube, you might need to run 'minikube tunnel' in a separate terminal to access the services.${NC}"
fi

echo -e "${GREEN}To view the status of all pods, run:${NC}"
echo "kubectl get pods -n ticketly"

echo -e "${GREEN}To view logs of a specific pod, run:${NC}"
echo "kubectl logs -f -n ticketly <pod-name>"