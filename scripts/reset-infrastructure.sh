#!/bin/bash

set -e  # Exit on any error

# Determine the project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Change to project root to ensure commands run from there
cd "$PROJECT_ROOT"

echo "Running infrastructure reset script from project root: $PROJECT_ROOT"

# Stop and remove all containers and volumes
docker compose down -v

# Start Keycloak service in detached mode
docker compose up keycloak -d

# Wait for Keycloak to start up
for i in {1..20}; do
    echo "Waiting for Keycloak to start... ($i/20)"
     sleep 1
done

# Navigate to Keycloak Terraform directory
cd keycloak/terraform/

# Remove existing Terraform state file
rm -f terraform.tfstate

# Apply Terraform configuration with auto-approve
terraform apply -auto-approve

# Return to project root
cd ../../

# Extract secrets using the existing script
./scripts/extract-secrets.sh

# Stop all services
docker compose down

echo "Infrastructure reset and secrets extraction completed successfully."