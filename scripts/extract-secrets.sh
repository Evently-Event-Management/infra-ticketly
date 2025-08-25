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
EVENT_PROJECTION_SECRET=$(terraform output -raw event_projection_service_client_secret 2>/dev/null)
TICKET_SECRET=$(terraform output -raw ticket_service_client_secret 2>/dev/null)
PAYMENT_SECRET=$(terraform output -raw payment_service_client_secret 2>/dev/null)
EVENTS_SERVICE_SECRET=$(terraform output -raw events_service_client_secret 2>/dev/null)

if [ -z "$SCHEDULER_SECRET" ]; then
    echo "Error: Could not extract scheduler_service_client_secret from Terraform output"
    exit 1
fi

if [ -z "$API_GATEWAY_SECRET" ]; then
    echo "Error: Could not extract api_gateway_client_secret from Terraform output"
    exit 1
fi

if [ -z "$EVENT_PROJECTION_SECRET" ]; then
    echo "Error: Could not extract event_projection_service_client_secret from Terraform output"
    exit 1
fi

if [ -z "$TICKET_SECRET" ]; then
    echo "Error: Could not extract ticket_service_client_secret from Terraform output"
    exit 1
fi
if [ -z "$EVENTS_SERVICE_SECRET" ]; then
    echo "Error: Could not extract events_service_client_secret from Terraform output"
    exit 1
fi

if [ -z "$PAYMENT_SECRET" ]; then
    echo "Error: Could not extract payment_service_client_secret from Terraform output"
    exit 1
fi

# Navigate back to root
cd ../..

# Update .env file
echo "Updating .env file with extracted secrets..."

# Create or update .env file
cat > .env << EOF
# Keycloak Client Secrets (Auto-generated from Terraform)
EVENTS_SERVICE_CLIENT_SECRET=${EVENTS_SERVICE_SECRET}
SCHEDULER_CLIENT_SECRET=${SCHEDULER_SECRET}
API_GATEWAY_CLIENT_SECRET=${API_GATEWAY_SECRET}
EVENT_PROJECTION_CLIENT_SECRET=${EVENT_PROJECTION_SECRET}
TICKET_CLIENT_SECRET=${TICKET_SECRET}
PAYMENT_CLIENT_SECRET=${PAYMENT_SECRET}
EOF

echo "✅ Successfully updated .env file with client secrets"
echo "Events Service Secret: ${EVENTS_SERVICE_SECRET}"
echo "Scheduler Secret: ${SCHEDULER_SECRET}"
echo "API Gateway Secret: ${API_GATEWAY_SECRET}"
echo "Event Projection Secret: ${EVENT_PROJECTION_SECRET}"
echo "Ticket Service Secret: ${TICKET_SECRET}"
echo "Payment Service Secret: ${PAYMENT_SECRET}"


# Re run the service to apply changes
echo "Restarting services to apply changes..."
docker-compose down
docker-compose up -d