# Local Kubernetes Development Setup for Ticketly

This document explains how to set up and run the Ticketly microservices infrastructure locally using Kubernetes.

## Prerequisites

1. Docker
2. One of the following local Kubernetes tools:
   - Minikube: https://minikube.sigs.k8s.io/docs/start/
   - kind (Kubernetes in Docker): https://kind.sigs.k8s.io/docs/user/quick-start/
3. kubectl: https://kubernetes.io/docs/tasks/tools/
4. At least 8GB of RAM available for Docker/Kubernetes

## Step 1: Setting Up Local Host Entries

Add the following entries to your `/etc/hosts` file:

```
127.0.0.1 api.ticketly.test
127.0.0.1 kafka.ticketly.test
127.0.0.1 logs.ticketly.test
```

On Linux/Mac:
```bash
sudo nano /etc/hosts
# Add the lines above and save
```

On Windows (as Administrator):
```
notepad c:\Windows\System32\drivers\etc\hosts
# Add the lines above and save
```

## Step 2: Setting Up Required External Services

For local development, you'll need PostgreSQL running locally:

```bash
# Start PostgreSQL with Docker
docker run -d --name ticketly-postgres \
  -e POSTGRES_PASSWORD=password123 \
  -p 5432:5432 \
  -v ticketly-postgres-data:/var/lib/postgresql/data \
  postgres:15
```

Create the necessary databases:
```bash
# Create required databases
docker exec -it ticketly-postgres psql -U postgres -c "CREATE DATABASE event_service;"
docker exec -it ticketly-postgres psql -U postgres -c "CREATE DATABASE scheduler_service;"
docker exec -it ticketly-postgres psql -U postgres -c "CREATE DATABASE order_service;"
```

## Step 3: Running the Local Kubernetes Setup

1. Run the setup script:

```bash
./setup-local-k8s.sh
```

This script will:
- Check if Minikube or kind is installed and start it if needed
- Create a local environment file (`.env.local`) with default values
- Create a local development overlay for Kubernetes
- Deploy all services to the local Kubernetes cluster

2. If using Minikube, you might need to run `minikube tunnel` in a separate terminal window to enable access to the Ingress services:

```bash
minikube tunnel
```

## Step 4: Accessing the Services

Once deployment is complete, you can access the services at:

- API: http://api.ticketly.test
- Kafka UI: http://kafka.ticketly.test
- Logging Dashboard: http://logs.ticketly.test

## Monitoring and Debugging

### View all pods
```bash
kubectl get pods -n ticketly
```

### Check pod logs
```bash
kubectl logs -f -n ticketly <pod-name>
```

### Check pod details
```bash
kubectl describe pod -n ticketly <pod-name>
```

### Access a shell in a pod
```bash
kubectl exec -it -n ticketly <pod-name> -- /bin/sh
```

## Cleaning Up

To remove all resources:

```bash
./cleanup-local-k8s.sh
```

This will delete the Ticketly namespace and all its resources. It will also offer to delete the kind cluster or stop Minikube.

## Common Issues and Solutions

1. **Pods stuck in Pending state**
   - Check resource limits: `kubectl describe pod -n ticketly <pod-name>`
   - Try increasing resources for your local Kubernetes cluster

2. **Services not accessible**
   - If using Minikube, make sure `minikube tunnel` is running
   - Verify Ingress is working: `kubectl get ingress -n ticketly`

3. **Connection refused errors**
   - Check if the pods are running: `kubectl get pods -n ticketly`
   - Check service endpoints: `kubectl get endpoints -n ticketly`

4. **External database connection issues**
   - Verify the hostAliases configuration
   - Check if your PostgreSQL is accessible from within the Kubernetes pods

5. **DNS resolution issues**
   - Try using IP addresses instead of hostnames in your .env.local file
   - Check that the host aliases are correctly configured

6. **Permission denied errors**
   - Check the logs: `kubectl logs -n ticketly <pod-name>`
   - Verify secrets are properly created: `kubectl get secrets -n ticketly`