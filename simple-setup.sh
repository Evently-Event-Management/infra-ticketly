#!/bin/bash
#
# Simple Ticketly Infrastructure Setup Script
#

# Get the script's directory (project root)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Stop running services
echo "Stopping running Docker Compose services..."
docker compose down

# Update code from git
echo "Pulling latest code from git repository..."
git pull

# Pull latest Docker images
echo "Pulling latest Docker images..."
docker compose pull

# Apply AWS Terraform
echo "Applying AWS Terraform configuration..."
cd "$PROJECT_ROOT/aws"
terraform apply

# Return to project root and extract AWS secrets
echo "Extracting AWS secrets from Terraform outputs..."
cd "$PROJECT_ROOT"
"$PROJECT_ROOT/scripts/extract-secrets.sh" aws-only

# Start Docker Compose services
echo "Starting services with Docker Compose..."
docker compose up -d

# Wait for Keycloak to be ready
echo "Waiting for Keycloak service to be ready..."
sleep 30  # Adjust this time as needed for your Keycloak service to fully initialize
echo "Proceeding with Keycloak configuration"

# Apply Keycloak Terraform
echo "Applying Keycloak Terraform configuration..."
cd "$PROJECT_ROOT/keycloak/terraform"
terraform apply

# Return to project root and extract all secrets
echo "Extracting all secrets including Keycloak..."
cd "$PROJECT_ROOT"
"$PROJECT_ROOT/scripts/extract-secrets.sh"

echo "Setup completed successfully!"