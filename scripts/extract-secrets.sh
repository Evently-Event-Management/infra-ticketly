#!/bin/bash

# Script to extract Keycloak client secrets from Terraform and update .env file

echo "Extracting Keycloak client secrets from Terraform..."

# Navigate to terraform directory
cd keycloak/terraform

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "Error: terraform.tfstate not found. Make sure you've run 'terraform apply' first."
    exit 1
fi

# Extract secrets
SCHEDULER_SECRET=$(terraform output -raw scheduler_service_client_secret 2>/dev/null)
API_GATEWAY_SECRET=$(terraform output -raw api_gateway_client_secret 2>/dev/null)

if [ -z "$SCHEDULER_SECRET" ]; then
    echo "Error: Could not extract scheduler_service_client_secret from Terraform output"
    exit 1
fi

if [ -z "$API_GATEWAY_SECRET" ]; then
    echo "Error: Could not extract api_gateway_client_secret from Terraform output"
    exit 1
fi

# Navigate back to root
cd ../..

# Update .env file
echo "Updating .env file with extracted secrets..."

# Create or update .env file
cat > .env << EOF
# Keycloak Client Secrets (Auto-generated from Terraform)
SCHEDULER_CLIENT_SECRET=${SCHEDULER_SECRET}
API_GATEWAY_CLIENT_SECRET=${API_GATEWAY_SECRET}
EOF

echo "✅ Successfully updated .env file with client secrets"
echo "Scheduler Secret: ${SCHEDULER_SECRET}"
echo "API Gateway Secret: ${API_GATEWAY_SECRET}"
