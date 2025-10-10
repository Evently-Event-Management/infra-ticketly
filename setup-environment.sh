#!/bin/bash
#
# Ticketly Infrastructure Setup Script
# This script handles the complete setup process including:
# - Stopping current services
# - Updating code
# - Pulling Docker images
# - Applying Terraform configurations
# - Starting services
# - Extracting secrets
#

# Set strict mode
set -eo pipefail

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

handle_error() {
  log_error "An error occurred at line $1. Exiting..."
  exit 1
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Get the script's directory (project root)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Step 1: Stop running services
log_info "Stopping running Docker Compose services..."
docker compose down
log_success "Docker services stopped successfully"

# Step 2: Update code from git
log_info "Pulling latest code from git repository..."
git pull
log_success "Code updated successfully"

# Step 3: Pull latest Docker images
log_info "Pulling latest Docker images..."
docker compose pull
log_success "Docker images updated successfully"

# Step 4: Apply AWS Terraform
log_info "Applying AWS Terraform configuration..."
cd "$PROJECT_ROOT/aws"
terraform init
terraform apply -auto-approve
log_success "AWS infrastructure provisioned successfully"

# Step 5: Extract AWS secrets
log_info "Extracting AWS secrets from Terraform outputs..."
cd "$PROJECT_ROOT"
"$PROJECT_ROOT/scripts/extract-secrets.sh" aws-only
log_success "AWS secrets extracted successfully"

# Step 6: Start Docker Compose services
log_info "Starting services with Docker Compose..."
docker compose up -d
log_success "Services started successfully"

# Step 7: Wait for Keycloak to be ready
log_info "Waiting for Keycloak service to be ready..."
sleep 30  # Adjust this time as needed for your Keycloak service to fully initialize
log_success "Proceeding with Keycloak configuration"

# Step 8: Apply Keycloak Terraform
log_info "Applying Keycloak Terraform configuration..."
cd "$PROJECT_ROOT/keycloak/terraform"
terraform init
terraform apply -auto-approve
log_success "Keycloak configuration applied successfully"

# Step 9: Extract all secrets including Keycloak
log_info "Extracting all secrets including Keycloak..."
cd "$PROJECT_ROOT"
"$PROJECT_ROOT/scripts/extract-secrets.sh"
log_success "All secrets extracted successfully"

log_success "============================="
log_success "Setup completed successfully!"
log_success "============================="