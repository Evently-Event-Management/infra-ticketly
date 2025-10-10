#!/bin/bash
#
# Ticketly Infrastructure Setup Script
# This script handles the complete setup process including:
# - Checking prerequisites
# - Setting up hosts file (optional)
# - Checking for required credentials
# - Setting up Terraform workspaces
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

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."
  
  # Check for Git
  if ! command_exists git; then
    log_error "Git is not installed. Please install Git and try again."
    exit 1
  fi
  
  # Check for Docker and Docker Compose
  if ! command_exists docker; then
    log_error "Docker is not installed. Please install Docker Desktop and try again."
    exit 1
  fi
  
  # Check Docker Compose (v2 is integrated with Docker CLI)
  if ! docker compose version > /dev/null 2>&1; then
    log_error "Docker Compose is not available. Please ensure Docker Desktop is properly installed."
    exit 1
  fi
  
  # Check for Terraform
  if ! command_exists terraform; then
    log_error "Terraform CLI is not installed. Please install Terraform and try again."
    exit 1
  fi
  
  # Check for AWS CLI
  if ! command_exists aws; then
    log_error "AWS CLI is not installed. Please install AWS CLI and try again."
    exit 1
  fi
  
  # Check for jq
  if ! command_exists jq; then
    log_error "jq is not installed. Please install jq and try again."
    log_error "  - macOS: brew install jq"
    log_error "  - Linux (Debian/Ubuntu): sudo apt-get install jq"
    log_error "  - Linux (Fedora): sudo dnf install jq"
    log_error "  - Windows (Chocolatey): choco install jq"
    exit 1
  fi
  
  log_success "All prerequisites are installed"
}

# Function to prompt for user input
prompt() {
  local message="$1"
  local default="$2"
  local result
  
  read -p "$message [$default]: " result
  echo "${result:-$default}"
}

# Function to ask yes/no questions
ask_yes_no() {
  local message="$1"
  local response
  
  while true; do
    read -p "$message [y/n]: " response
    case "$response" in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer yes (y) or no (n).";;
    esac
  done
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Get the script's directory (project root)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Check if this is first-time setup
FIRST_TIME_SETUP=false
if ask_yes_no "Is this your first time setting up the project?"; then
  FIRST_TIME_SETUP=true
  log_info "Running first-time setup process..."
else
  log_info "Running regular update process..."
fi

# Check prerequisites
check_prerequisites

# First-time setup specific tasks
if [ "$FIRST_TIME_SETUP" = true ]; then
  # Step 1: Check hosts file configuration
  if ask_yes_no "Would you like to check/update your hosts file for auth.ticketly.com?"; then
    log_info "Checking hosts file configuration..."
    if grep -q "auth.ticketly.com" /etc/hosts; then
      log_success "Host entry for auth.ticketly.com already exists"
    else
      if ask_yes_no "Entry for auth.ticketly.com not found. Would you like to add it now? (requires sudo)"; then
        echo "127.0.0.1   auth.ticketly.com" | sudo tee -a /etc/hosts > /dev/null
        log_success "Host entry added successfully"
      else
        log_warning "Host entry not added. You need to manually add '127.0.0.1 auth.ticketly.com' to your hosts file"
      fi
    fi
  fi

  # Step 2: Check for GCP credentials
  log_info "Checking for GCP credentials..."
  if [ ! -f "$PROJECT_ROOT/credentials/gcp-credentials.json" ]; then
    log_warning "GCP credentials file not found at ./credentials/gcp-credentials.json"
    log_warning "Please place your gcp-credentials.json file in the ./credentials/ directory"
    if [ ! -d "$PROJECT_ROOT/credentials" ]; then
      mkdir -p "$PROJECT_ROOT/credentials"
      log_info "Created credentials directory. Please add your gcp-credentials.json file there."
    fi
    if ask_yes_no "Do you want to continue without GCP credentials? (Some features may not work)"; then
      log_warning "Continuing without GCP credentials. Google Analytics features may not work."
    else
      log_error "Setup aborted. Please add GCP credentials and run the script again."
      exit 1
    fi
  else
    log_success "GCP credentials found"
  fi
  
  # Step 3: Handle script line endings for Windows users
  if [[ "$(uname -s)" == *"MINGW"* || "$(uname -s)" == *"MSYS"* ]]; then
    log_info "Windows system detected. Checking script line endings..."
    if command_exists dos2unix; then
      log_info "Converting scripts to Unix line endings..."
      find "$PROJECT_ROOT/scripts" -name "*.sh" -exec dos2unix {} \;
      log_success "Scripts converted successfully"
    else
      log_warning "dos2unix not found. If you encounter script errors, you may need to install dos2unix"
      log_warning "and convert the line endings of script files."
    fi
  fi
fi

# Common setup steps
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

# Step 4: Set up and apply AWS Terraform
log_info "Setting up AWS infrastructure with Terraform..."
cd "$PROJECT_ROOT/aws"

# For first-time setup, we need to initialize workspace
if [ "$FIRST_TIME_SETUP" = true ]; then
  log_info "Setting up Terraform Cloud connection..."
  if ask_yes_no "Do you need to login to Terraform Cloud?"; then
    terraform login
    if [ $? -ne 0 ]; then
      log_error "Failed to log in to Terraform Cloud. Please try again manually."
      exit 1
    fi
    log_success "Successfully logged in to Terraform Cloud"
  fi
  
  # Initialize Terraform
  log_info "Initializing Terraform..."
  terraform init
  
  # Create developer workspace
  log_info "Creating your developer workspace in Terraform Cloud..."
  DEV_NAME=$(prompt "Enter your developer name (e.g., piyumal)" "$(whoami)")
  
  log_info "Creating workspace: dev-$DEV_NAME"
  terraform workspace new "dev-$DEV_NAME" || terraform workspace select "dev-$DEV_NAME"
  
  log_warning "IMPORTANT: You need to set up AWS credentials in Terraform Cloud!"
  log_warning "1. Log in to the Terraform Cloud UI"
  log_warning "2. Create a Variable Set for your account (e.g., \"AWS Credentials - $DEV_NAME\")"
  log_warning "3. Add the following environment variables (mark them as sensitive):"
  log_warning "   - AWS_ACCESS_KEY_ID"
  log_warning "   - AWS_SECRET_ACCESS_KEY"
  log_warning "   - AWS_REGION (e.g., ap-south-1)"
  log_warning "4. Apply this variable set to your 'infra-dev-$DEV_NAME' workspace"
  
  if ! ask_yes_no "Have you set up the AWS credentials in Terraform Cloud?"; then
    log_warning "You'll need to set up these credentials before proceeding."
    if ! ask_yes_no "Do you want to continue anyway? (The terraform apply step may fail)"; then
      log_error "Setup aborted. Please set up AWS credentials in Terraform Cloud and run again."
      exit 1
    fi
  fi
fi

# Apply Terraform configuration
log_info "Applying AWS Terraform configuration..."
terraform init
terraform apply $([ "$FIRST_TIME_SETUP" = false ] && echo "-auto-approve")
log_success "AWS infrastructure provisioned successfully"

# Step 5: Extract AWS secrets
log_info "Extracting AWS secrets from Terraform outputs..."
cd "$PROJECT_ROOT"
"$PROJECT_ROOT/scripts/extract-secrets.sh" aws-only
log_success "AWS secrets extracted successfully"

# Step 6: Start Keycloak and database for configuration
log_info "Starting Keycloak and database containers..."
docker compose up -d keycloak ticketly-db
log_success "Keycloak and database started successfully"

# Step 7: Wait for Keycloak to be ready
log_info "Waiting for Keycloak service to be ready..."
WAIT_TIME=45
log_info "Waiting $WAIT_TIME seconds for Keycloak to initialize..."
sleep $WAIT_TIME
log_success "Proceeding with Keycloak configuration"

# Step 8: Apply Keycloak Terraform
log_info "Applying Keycloak Terraform configuration..."
cd "$PROJECT_ROOT/keycloak/terraform"

if [ "$FIRST_TIME_SETUP" = true ]; then
  # For first time setup, use the dev backend
  log_info "Initializing Keycloak Terraform with local development backend..."
  terraform init -backend-config=backend.dev.hcl
else
  terraform init
fi

terraform apply $([ "$FIRST_TIME_SETUP" = false ] && echo "-auto-approve")
log_success "Keycloak configuration applied successfully"

# Step 9: Extract all secrets including Keycloak
log_info "Extracting all secrets including Keycloak..."
cd "$PROJECT_ROOT"
"$PROJECT_ROOT/scripts/extract-secrets.sh"
log_success "All secrets extracted successfully"

if [ "$FIRST_TIME_SETUP" = true ]; then
  # For first time setup, shut down the temporary containers
  log_info "Shutting down temporary containers..."
  docker compose down
  log_success "Temporary containers shut down successfully"
  
  log_info "First-time setup complete!"
  log_info "You can now start all services with: docker compose up -d"
else
  # For regular updates, start all services
  log_info "Starting all services with Docker Compose..."
  docker compose up -d
  log_success "All services started successfully"
fi

# Display service access information
log_info "Your local services are available at:"
log_info "  - API Gateway: http://localhost:8088"
log_info "  - Keycloak Admin: http://auth.ticketly.com:8080 (admin/admin123)"
log_info "  - Kafka UI: http://localhost:9000"
log_info "  - Dozzle (Log Viewer): http://localhost:9999"

log_success "============================="
log_success "Setup completed successfully!"
log_success "============================="