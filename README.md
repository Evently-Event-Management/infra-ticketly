# Ticketly Infrastructure & Deployment Guide 🎟️

Welcome to Ticketly! This guide covers everything from local development to production deployment on AWS with Kubernetes (K3s). Ticketly is a microservices-based event ticketing platform with infrastructure managed as code.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Production Deployment](#production-deployment)
- [Kubernetes Deployment Guide](#kubernetes-deployment-guide)
- [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Infrastructure Stack
- **Compute**: AWS EC2 instances (Control Plane, Workers, Infrastructure Node)
- **Database**: AWS RDS PostgreSQL with logical replication
- **Storage**: AWS S3 for assets (images, files)
- **Messaging**: Apache Kafka, AWS SQS
- **Cache**: Redis
- **Auth**: Keycloak (OIDC/OAuth2)
- **Container Orchestration**: K3s (lightweight Kubernetes)
- **Load Balancer**: AWS Application Load Balancer with WAF
- **Ingress**: Traefik (bundled with K3s)

### Microservices
- **Event Command Service** (Java/Spring Boot) - Write operations for events
- **Event Query Service** (Java/Spring Boot) - Read operations for events
- **Order Service** (Go) - Ticket ordering and payment processing
- **Scheduler Service** (Go) - Event scheduling and reminders

---

## Prerequisites

### For Local Development
- [ ] **Git**: For cloning the repository
- [ ] **Docker & Docker Compose v2**: To run infrastructure services
- [ ] **Terraform CLI**: To provision AWS resources
- [ ] **AWS CLI**: For AWS interactions
- [ ] **jq**: JSON processor for scripts
  - macOS: `brew install jq`
  - Linux (Debian/Ubuntu): `sudo apt-get install jq`
  - Linux (Fedora): `sudo dnf install jq`
  - Windows (Chocolatey): `choco install jq`
- [ ] **Personal AWS Account**: With IAM user having administrative permissions
- [ ] **Terraform Cloud Account**: Access to the project organization

### For Production Deployment
- [ ] All local development prerequisites
- [ ] **kubectl**: Kubernetes CLI tool
- [ ] **SSH key pair**: For EC2 access (generated during setup)
- [ ] **Domain name**: With DNS configured (e.g., `api.dpiyumal.me`)
- [ ] **SSL Certificate**: AWS ACM certificate for your domain
- [ ] **Production AWS credentials**: With appropriate IAM permissions  

---

## Local Development Setup

This section covers setting up Ticketly for local development. You'll run infrastructure services (Kafka, Redis, MongoDB, Keycloak) in Docker Compose while developing microservices locally or in containers.

### One-Time Setup

You only need to perform these steps the first time you set up the project.

#### 1. Clone the Repository

```bash
git clone https://github.com/Evently-Event-Management/infra-ticketly.git
cd infra-ticketly
```

#### 2. Configure Local Hosts

For local Keycloak access, add this entry to your hosts file:

- **Linux/macOS**: Edit `/etc/hosts`
- **Windows**: Edit `C:\Windows\System32\drivers\etc\hosts`

```
127.0.0.1   auth.ticketly.com
```

#### 3. Place Credential Files

Place your GCP credentials in the project:

```bash
# Place your GCP service account JSON
cp /path/to/your/gcp-credentials.json ./credentials/gcp-credentials.json
```

#### 4. Handle Script Line Endings (Windows Users)

**CRITICAL for Windows**: Scripts must use Unix line endings.

```bash
# Use Git Bash or MINGW terminal on Windows
cd scripts/
dos2unix extract-secrets.sh init-dbs.sh init-debezium.sh monitor-sqs-live.sh send-kafka-event.sh test-scheduler.sh
```

> **Note**: Avoid opening scripts in Windows Notepad as it may change line endings.

#### 5. Provision AWS Development Infrastructure

Create your personal AWS development environment:

```bash
cd aws/dev

# Log in to Terraform Cloud
terraform login

# Create your developer workspace (replace <your-name>)
terraform init
terraform workspace new dev-<your-name>
```

**Configure AWS Credentials in Terraform Cloud**:
1. Log in to Terraform Cloud UI
2. Admin creates a Variable Set for you (e.g., "AWS Credentials - YourName")
3. Add environment variables (mark as sensitive):
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` (e.g., `ap-south-1`)
4. Apply the variable set to your workspace

```bash
# Apply the infrastructure
terraform apply
```

This creates development resources: SQS queues, S3 buckets, and IAM policies.

#### 6. Configure Local Keycloak

Keycloak provides authentication and authorization for all services.

```bash
# Start Keycloak and its database
docker compose up -d keycloak ticketly-db

# Wait for Keycloak to be ready (check at http://auth.ticketly.com:8080)

# Apply Keycloak configuration with Terraform
cd keycloak/terraform/
terraform init -backend-config=backend.dev.hcl
terraform apply

# Return to project root
cd ../../

# Extract secrets from Keycloak
./scripts/extract-secrets.sh

# Stop temporary containers
docker compose down
```

The extract script creates a `.env` file with all necessary environment variables.

### Running the Application Locally

Once setup is complete, start the full stack:

```bash
# From project root
docker compose up -d
```

The first run will download all container images (~5-10 minutes depending on your connection).

### Accessing Local Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **API Gateway** | `http://localhost:8088` | - |
| **Keycloak Admin** | `http://auth.ticketly.com:8080` | `admin` / `admin123` |
| **Kafka UI** | `http://localhost:9000` | - |
| **Dozzle (Logs)** | `http://localhost:9999` | - |
| **Event Command API** | `http://localhost:8081` | Requires auth token |
| **Event Query API** | `http://localhost:8082` | Requires auth token |
| **Order Service API** | `http://localhost:8084` | Requires auth token |
| **Scheduler Service API** | `http://localhost:8085` | Requires auth token |

### Useful Development Commands

```bash
# View all logs
docker compose logs -f

# View logs for specific service
docker compose logs -f order-service

# Restart a service
docker compose restart event-command-service

# Stop all services
docker compose down

# Stop and remove all data (clean slate)
docker compose down -v

# Check service health
docker compose ps
```

---

## Production Deployment

This section covers deploying Ticketly to production on AWS with a K3s Kubernetes cluster.

### Production Architecture

```
Internet
    ↓
AWS ALB (with WAF) → SSL/TLS Termination
    ↓
K3s Cluster (EC2 Instances)
    ├── Control Plane Node (t3.small)
    │   └── K3s Server + Traefik Ingress
    │
    ├── Worker Nodes (4x t3.small)
    │   └── Microservices Pods
    │
    └── Infrastructure Node (c7i-flex.large)
        ├── Kafka
        ├── MongoDB
        ├── Redis
        ├── Debezium
        └── Kafka UI
```

### Step 1: Generate SSH Keys

SSH keys are required for accessing EC2 instances:

```bash
cd aws/prod

# Generate SSH key pair
ssh-keygen -t rsa -b 2048 -f ticketly-key -N ""

# Set correct permissions
chmod 600 ticketly-key
```

> **Security Note**: The `.gitignore` file already excludes SSH keys from version control. Never commit private keys!

### Step 2: Configure Production Variables

Edit `aws/prod/terraform.tfvars` to set your production configuration:

```hcl
# Domain and SSL
api_domain_ssl_arn = "arn:aws:acm:ap-south-1:YOUR_ACCOUNT:certificate/YOUR_CERT_ID"

# Other production-specific variables
# (Review all variables in variables.tf)
```

### Step 3: Provision Production Infrastructure

```bash
cd aws/prod

# Initialize Terraform
terraform init

# Select production workspace
terraform workspace select infra-ticketly
# Or create it if it doesn't exist
# terraform workspace new infra-ticketly

# Review the plan
terraform plan

# Apply infrastructure
terraform apply
```

This creates:
- VPC with public/private subnets across 3 availability zones
- EC2 instances (1 control plane, 4 workers, 1 infrastructure node)
- RDS PostgreSQL database with logical replication enabled
- S3 bucket for assets with public read access
- SQS queues for job processing
- Application Load Balancer with HTTPS
- WAF with managed rule sets (allowing large multipart uploads)
- Security groups and IAM roles
- EventBridge schedulers

**Important Outputs** (save these):

```bash
# View all outputs
terraform output

# Save SSH command
terraform output ssh_command

# Example output:
# ssh -i ./ticketly-key ubuntu@<CONTROL_PLANE_PUBLIC_IP>
```

### Step 4: Access Production Instances

After Terraform completes, you can access your instances:

```bash
# SSH to control plane
ssh -i ticketly-key ubuntu@<CONTROL_PLANE_PUBLIC_IP>

# SSH to infrastructure node (via control plane)
ssh -i ticketly-key ubuntu@10.0.80.20  # From control plane

# Port forward RDS (for database management)
ssh -i ticketly-key -L 5432:<RDS_ENDPOINT>:5432 ubuntu@<CONTROL_PLANE_PUBLIC_IP>

# Port forward Redis (for debugging)
ssh -i ticketly-key -L 6379:10.0.80.20:6379 ubuntu@<CONTROL_PLANE_PUBLIC_IP>

# Port forward MongoDB (for debugging)
ssh -i ticketly-key -L 27017:10.0.80.20:27017 ubuntu@<CONTROL_PLANE_PUBLIC_IP>
```

---

## Kubernetes Deployment Guide

After provisioning AWS infrastructure, deploy the Ticketly application to K3s.

### Prerequisites

1. **K3s installed** on control plane and worker nodes
2. **kubectl configured** to access the cluster
3. **DNS configured**: `api.dpiyumal.me` and `auth.dpiyumal.me` pointing to your ALB
4. **Terraform outputs extracted**: Run `extract-secrets.sh` script

### Step 1: Get Kubernetes Config

From the control plane node:

```bash
# On the control plane node
sudo cat /etc/rancher/k3s/k3s.yaml

# Copy the content to your local machine at ~/.kube/config
# Replace 127.0.0.1 with the actual control plane IP

# Set permissions
chmod 600 ~/.kube/config

# Test connection
kubectl get nodes
```

Expected output:
```
NAME                         STATUS   ROLES                  AGE   VERSION
ticketly-control-plane       Ready    control-plane,master   1d    v1.28.x+k3s1
ticketly-worker-0            Ready    <none>                 1d    v1.28.x+k3s1
ticketly-worker-1            Ready    <none>                 1d    v1.28.x+k3s1
ticketly-worker-2            Ready    <none>                 1d    v1.28.x+k3s1
ticketly-worker-3            Ready    <none>                 1d    v1.28.x+k3s1
```

### Step 2: Create Namespace and Configuration

```bash
# Create the ticketly namespace
kubectl apply -f k8s/k3s/namespace.yaml

# Update INFRA_HOST in the ConfigMap
# Edit k8s/k3s/configs/ticketly-global-config.yaml
# Set INFRA_HOST to your infrastructure node private IP (default: 10.0.80.20)

# Apply global configuration
kubectl apply -f k8s/k3s/configs/ticketly-global-config.yaml
```

### Step 3: Create Secrets

Generate Kubernetes secrets from Terraform outputs and credential files:

```bash
# From project root directory

# Extract secrets and generate .env.k8s
./scripts/extract-secrets.sh --k8s

# Create app secrets from environment variables
kubectl create secret generic ticketly-app-secrets \
  --namespace ticketly \
  --from-env-file=.env.k8s \
  --dry-run=client -o yaml \
  > k8s/k3s/secrets/app-secrets.yaml

kubectl apply -f k8s/k3s/secrets/app-secrets.yaml

# Create GCP credentials secret
kubectl create secret generic ticketly-gcp-credentials \
  --namespace ticketly \
  --from-file=google-credentials.json=credentials/gcp-credentials.json \
  --dry-run=client -o yaml \
  > k8s/k3s/secrets/gcp-credentials.yaml

kubectl apply -f k8s/k3s/secrets/gcp-credentials.yaml

# Create Google private key secret
kubectl create secret generic ticketly-google-private-key \
  --namespace ticketly \
  --from-file=GOOGLE_PRIVATE_KEY=credentials/google-private-key.pem \
  --dry-run=client -o yaml \
  > k8s/k3s/secrets/google-private-key.yaml

kubectl apply -f k8s/k3s/secrets/google-private-key.yaml
```

> **Security Note**: The generated secret YAML files contain sensitive data. They are gitignored but should be handled carefully.

### Step 4: Deploy Infrastructure Services

The infrastructure node runs Kafka, MongoDB, Redis, and Debezium in Docker Compose.

SSH to the infrastructure node and start services:

```bash
# SSH to infrastructure node via control plane
ssh -i ticketly-key ubuntu@<CONTROL_PLANE_IP>
ssh ubuntu@10.0.80.20

# Clone the repository on the infrastructure node
git clone https://github.com/Evently-Event-Management/infra-ticketly.git
cd infra-ticketly

# Set the Kafka advertised host
export KAFKA_PUBLIC_HOST=10.0.80.20

# Start infrastructure services
docker compose up -d redis kafka kafka-ui debezium-connect debezium-connector-init dozzle

# Verify services are running
docker compose ps

# Check logs
docker compose logs -f
```

**Infrastructure Services**:
- **Redis**: Port 6379 (cache and session storage)
- **Kafka**: Port 9092 (event streaming)
- **MongoDB**: Port 27017 (query database with CDC)
- **Debezium**: Port 8083 (change data capture)
- **Kafka UI**: Port 9000 (Kafka management)
- **Dozzle**: Port 9999 (container log viewer)

### Step 5: Initialize Databases

Create database schemas for each microservice:

```bash
# From the control plane or your local machine with port forwarding

# Initialize PostgreSQL databases
./scripts/init-dbs.sh

# This creates:
# - event_service (for event-command-service)
# - order_service (for order-service)
# - scheduler_service (for scheduler-service)
```

### Step 6: Deploy Microservices

Deploy all microservices to the K3s cluster:

```bash
# Deploy all services
kubectl apply -f k8s/k3s/apps/event-command.yaml
kubectl apply -f k8s/k3s/apps/event-query.yaml
kubectl apply -f k8s/k3s/apps/order-service.yaml
kubectl apply -f k8s/k3s/apps/scheduler-service.yaml

# Watch deployment progress
kubectl get pods -n ticketly -w

# Check deployment status
kubectl get deployments -n ticketly
```

Expected output:
```
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
event-command-service   1/1     1            1           2m
event-query-service     1/1     1            1           2m
order-service           1/1     1            1           2m
scheduler-service       1/1     1            1           2m
```

### Step 7: Configure Ingress

The ingress routes external traffic to microservices through Traefik.

```bash
# Apply ingress configuration
kubectl apply -f k8s/k3s/ingress.yaml

# Verify ingress
kubectl get ingress -n ticketly

# Check Traefik is routing correctly
kubectl describe ingress ticketly-api -n ticketly
```

**Ingress Routes**:
- `https://api.dpiyumal.me/api/event-seating` → Event Command Service
- `https://api.dpiyumal.me/api/event-query` → Event Query Service
- `https://api.dpiyumal.me/api/order` → Order Service
- `https://api.dpiyumal.me/api/scheduler` → Scheduler Service

### Step 8: Install Cert-Manager (Optional for Let's Encrypt)

If you want automatic SSL certificate management within K3s:

```bash
# Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

# Apply ClusterIssuer (update email in the file)
kubectl apply -f k8s/k3s/infra/cert-manager-clusterissuer.yaml

# Verify
kubectl get clusterissuer
kubectl describe clusterissuer ticketly-letsencrypt
```

> **Note**: In production, the ALB handles SSL termination, so cert-manager is optional but useful for internal services.

### Step 9: Deploy Monitoring (Optional)

Deploy a lightweight Kubernetes dashboard:

```bash
# Deploy dashboard
kubectl apply -f k8s/k3s/monitoring/dashboard.yaml

# Access at http://logs.dpiyumal.me (configure DNS or use port-forward)
kubectl port-forward -n ticketly svc/kubernetes-dashboard 8080:80
```

### Step 10: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n ticketly

# Check services
kubectl get svc -n ticketly

# Check ingress
kubectl get ingress -n ticketly

# Test API endpoint
curl https://api.dpiyumal.me/api/event-query/health

# View logs
kubectl logs -n ticketly -l app=event-command-service -f
```

### Scaling Services

The deployments support horizontal pod autoscaling:

```bash
# Manually scale a deployment
kubectl scale deployment event-command-service -n ticketly --replicas=3

# Check HPA status (if configured)
kubectl get hpa -n ticketly

# Describe HPA for details
kubectl describe hpa event-command-service-hpa -n ticketly
```

> **Important**: When scaling, ensure worker nodes have sufficient resources. The current setup has 4 worker nodes with `replicas: 1` by default.

### Updating Services

To deploy new versions:

```bash
# Update image tag in deployment YAML
# Or use kubectl set image

kubectl set image deployment/event-command-service \
  event-command-service=ticketly/event-command-service:v2.0.0 \
  -n ticketly

# Watch rollout
kubectl rollout status deployment/event-command-service -n ticketly

# Rollback if needed
kubectl rollout undo deployment/event-command-service -n ticketly
```

---

## Monitoring and Observability

### Application Logs

```bash
# Stream logs from all pods of a service
kubectl logs -n ticketly -l app=order-service -f

# Stream logs from specific pod
kubectl logs -n ticketly order-service-5d7c8b9f4-abc12 -f

# View previous container logs (if pod restarted)
kubectl logs -n ticketly order-service-5d7c8b9f4-abc12 --previous
```

### Infrastructure Monitoring

- **Kafka UI**: Access via SSH tunnel or direct connection to infrastructure node
  ```bash
  ssh -L 9000:10.0.80.20:9000 -i ticketly-key ubuntu@<CONTROL_PLANE_IP>
  # Open http://localhost:9000
  ```

- **Dozzle (Docker logs)**: View infrastructure container logs
  ```bash
  ssh -L 9999:10.0.80.20:9999 -i ticketly-key ubuntu@<CONTROL_PLANE_IP>
  # Open http://localhost:9999
  ```

- **Kubernetes Dashboard**: Monitor cluster resources
  ```bash
  kubectl port-forward -n ticketly svc/kubernetes-dashboard 8080:80
  # Open http://localhost:8080
  ```

### AWS CloudWatch

- ALB access logs
- WAF logs and metrics
- RDS performance insights
- SQS queue metrics

### Health Checks

```bash
# Check pod health
kubectl get pods -n ticketly

# Describe pod for events
kubectl describe pod <pod-name> -n ticketly

# Check resource usage
kubectl top nodes
kubectl top pods -n ticketly
```

---

## Troubleshooting

### Pods Not Starting After Node Shutdown

**Problem**: You shut down worker-2 and worker-3, and pods aren't rescheduling to remaining nodes.

**Causes**:
1. **Node taints**: K3s marks unreachable nodes as `NoSchedule`
2. **Pod replicas**: With `replicas: 1`, there's only one pod instance
3. **Resource constraints**: Remaining nodes may lack resources

**Solutions**:

```bash
# Check node status
kubectl get nodes

# Remove taints from failed nodes
kubectl taint nodes ticketly-worker-2 node.kubernetes.io/unreachable:NoSchedule-
kubectl taint nodes ticketly-worker-3 node.kubernetes.io/unreachable:NoSchedule-

# Delete stuck pods to force rescheduling
kubectl delete pod -n ticketly <stuck-pod-name>

# Or delete all pods in terminating state
kubectl delete pod -n ticketly --field-selector=status.phase=Terminating --force --grace-period=0

# Scale up replicas for high availability
kubectl scale deployment event-command-service -n ticketly --replicas=2
kubectl scale deployment order-service -n ticketly --replicas=2

# Check pod distribution
kubectl get pods -n ticketly -o wide
```

**Prevention**: For production, always run multiple replicas:

```yaml
# In deployment YAML
spec:
  replicas: 2  # Or more depending on load
```

### Pods Can't Reach Infrastructure Services

**Problem**: Pods showing connection errors to Kafka/Redis/MongoDB.

**Solution**:

```bash
# Verify INFRA_HOST in ConfigMap
kubectl get configmap ticketly-global-config -n ticketly -o yaml

# Check infrastructure services are running
ssh ubuntu@10.0.80.20 "docker compose ps"

# Test connectivity from a pod
kubectl run test-pod -n ticketly --rm -it --image=busybox -- sh
# Inside pod:
wget -O- 10.0.80.20:6379  # Test Redis
telnet 10.0.80.20 9092    # Test Kafka

# Check security groups allow traffic from worker nodes
```

### Service Returns 404 from ALB

**Problem**: ALB returns 404 or 403 errors.

**Solutions**:

```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn <TARGET_GROUP_ARN>

# Verify ingress configuration
kubectl describe ingress ticketly-api -n ticketly

# Check Traefik logs
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik -f

# Test from within cluster
kubectl run test-pod -n ticketly --rm -it --image=curlimages/curl -- sh
# Inside pod:
curl http://event-command-service:8081/api/event-seating/health
```

### WAF Blocking Requests

**Problem**: Multipart uploads or large requests return 403.

**Solution**: The WAF is configured to allow large uploads. If still blocked:

```bash
# Check WAF logs in CloudWatch
aws wafv2 get-sampled-requests \
  --scope REGIONAL \
  --region ap-south-1 \
  --web-acl-id <WEB_ACL_ID> \
  --rule-metric-name <RULE_NAME> \
  --time-window StartTime=<timestamp>,EndTime=<timestamp>

# Adjust WAF rules in load_balancer.tf if needed
```

### Database Connection Issues

**Problem**: Services can't connect to RDS.

**Solutions**:

```bash
# Verify RDS is accessible
aws rds describe-db-instances --db-instance-identifier ticketly-db

# Check security group rules
aws ec2 describe-security-groups --group-ids <DB_SECURITY_GROUP_ID>

# Test connection from worker node
kubectl run psql-test -n ticketly --rm -it --image=postgres:15 -- bash
# Inside pod:
psql -h <RDS_ENDPOINT> -U ticketly -d event_service

# Verify credentials in secrets
kubectl get secret ticketly-app-secrets -n ticketly -o jsonpath='{.data.DATABASE_PASSWORD}' | base64 -d
```

### Out of Memory Errors

**Problem**: Pods being OOMKilled.

**Solutions**:

```bash
# Check resource limits in deployment YAML
kubectl describe pod <pod-name> -n ticketly

# Increase memory limits
kubectl set resources deployment event-command-service \
  -n ticketly \
  --limits=memory=1Gi \
  --requests=memory=512Mi

# Or edit the deployment YAML:
# resources:
#   requests:
#     memory: "512Mi"
#     cpu: "250m"
#   limits:
#     memory: "1Gi"
#     cpu: "500m"
```

### Disk Space Issues

**Problem**: Nodes running out of disk space.

**Solutions**:

```bash
# Check node disk usage
kubectl describe nodes | grep -A 5 "Allocated resources"

# SSH to node and clean up
ssh ubuntu@<NODE_IP>
docker system prune -af
df -h

# Increase EBS volume size in Terraform
# Update compute.tf:
# root_block_device {
#   volume_size = 30  # Increase from 15
#   volume_type = "gp3"
# }
```

### Common kubectl Commands

```bash
# Get all resources in namespace
kubectl get all -n ticketly

# Describe resource for detailed info
kubectl describe pod <pod-name> -n ticketly

# Get events
kubectl get events -n ticketly --sort-by='.lastTimestamp'

# Execute command in pod
kubectl exec -n ticketly <pod-name> -- <command>

# Interactive shell
kubectl exec -it -n ticketly <pod-name> -- /bin/bash

# Port forward to local machine
kubectl port-forward -n ticketly svc/event-command-service 8081:8081

# View resource usage
kubectl top pod -n ticketly
kubectl top node
```

---

## Maintenance and Operations

### Backup Strategy

1. **RDS Automated Backups**: Configured in Terraform with retention period
2. **S3 Versioning**: Enable versioning for the assets bucket
3. **Database Manual Snapshots**:
   ```bash
   aws rds create-db-snapshot \
     --db-instance-identifier ticketly-db \
     --db-snapshot-identifier ticketly-db-$(date +%Y%m%d)
   ```

### Disaster Recovery

1. **Infrastructure**: Terraform state allows complete recreation
2. **Database**: Restore from RDS snapshot
3. **Application State**: Rebuild from CDC (Debezium) or Kafka logs

### Security Best Practices

1. **Secrets Management**: Never commit secrets to git
2. **IAM Least Privilege**: Use instance profiles and roles
3. **Network Segmentation**: Workers in private subnets
4. **WAF Rules**: Keep AWS managed rule sets updated
5. **Regular Updates**: Keep K3s, Docker, and base AMIs updated

### Cost Optimization

```bash
# View current costs
aws ce get-cost-and-usage \
  --time-period Start=2025-10-01,End=2025-10-31 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=SERVICE

# Consider:
# - Using spot instances for non-critical workers
# - Implementing HPA to scale down during low traffic
# - Using S3 lifecycle policies
# - Scheduling non-production environments to stop after hours
```

---

## Additional Resources

- **K3s Documentation**: https://docs.k3s.io/
- **Traefik Ingress**: https://doc.traefik.io/traefik/providers/kubernetes-ingress/
- **AWS ALB Controller**: https://kubernetes-sigs.github.io/aws-load-balancer-controller/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Kubernetes Best Practices**: https://kubernetes.io/docs/concepts/

---

## Contributing

When making infrastructure changes:

1. Test changes in your development workspace first
2. Update this documentation if adding new components
3. Run `terraform fmt` before committing
4. Use conventional commits for clear history
5. Update the k8s manifests if changing service configuration

---

## Support

For issues or questions:
- Check the troubleshooting section above
- Review logs using Dozzle or kubectl
- Check AWS CloudWatch for infrastructure issues
- Consult the team's internal documentation

Happy deploying! 🚀