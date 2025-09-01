#!/bin/bash

echo "Extracting secrets from Terraform..."

# Get project root and define .env file path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

echo "Writing secrets to: ${ENV_FILE}"

# Overwrite .env file with a header
echo "# Terraform Outputs - Generated: $(date)" > "${ENV_FILE}"

# --- A single, simplified function ---
extract_tf_output() {
  local dir=$1
  local output_name=$2
  local env_var_name=$3

  pushd "$dir" >/dev/null
  echo "Extracting: $env_var_name"

  value=$(terraform output -raw "$output_name" 2>/dev/null)
  if [ $? -eq 0 ] && [ -n "$value" ]; then
    echo "$env_var_name=$value" >> "${ENV_FILE}"
  else
    echo "-> ❌ WARNING: Could not extract '$output_name' from '$dir'."
  fi
  popd >/dev/null
}

# --- Extract all raw values ---

echo -e "\n# Keycloak Client Secrets" >> "${ENV_FILE}"
KEYCLOAK_DIR="${PROJECT_ROOT}/keycloak/terraform"
extract_tf_output "${KEYCLOAK_DIR}" "scheduler_service_client_secret" "SCHEDULER_CLIENT_SECRET"
extract_tf_output "${KEYCLOAK_DIR}" "event_projection_service_client_secret" "EVENT_PROJECTION_CLIENT_SECRET"
extract_tf_output "${KEYCLOAK_DIR}" "ticket_service_client_secret" "TICKET_CLIENT_SECRET"
extract_tf_output "${KEYCLOAK_DIR}" "events_service_client_secret" "EVENTS_SERVICE_CLIENT_SECRET"

echo -e "\n# AWS Resources" >> "${ENV_FILE}"
AWS_DIR="${PROJECT_ROOT}/aws"
extract_tf_output "${AWS_DIR}" "s3_bucket_name" "AWS_S3_BUCKET_NAME"
extract_tf_output "${AWS_DIR}" "sqs_session_on_sale_arn" "AWS_SQS_SESSION_ON_SALE_ARN"
extract_tf_output "${AWS_DIR}" "sqs_session_closed_arn" "AWS_SQS_SESSION_CLOSED_ARN"
extract_tf_output "${AWS_DIR}" "scheduler_role_arn" "AWS_SCHEDULER_ROLE_ARN"
extract_tf_output "${AWS_DIR}" "scheduler_group_name" "AWS_SCHEDULER_GROUP_NAME"

echo -e "\n# AWS Credentials" >> "${ENV_FILE}"
extract_tf_output "${AWS_DIR}" "ticketly_dev_user_access_key" "AWS_ACCESS_KEY_ID"
extract_tf_output "${AWS_DIR}" "ticketly_dev_user_secret_key" "AWS_SECRET_ACCESS_KEY"

echo -e "\n# RDS Database Components" >> "${ENV_FILE}"
extract_tf_output "${AWS_DIR}" "ticketly_db_endpoint" "RDS_ENDPOINT"
extract_tf_output "${AWS_DIR}" "ticketly_db_user" "DATABASE_USERNAME"
extract_tf_output "${AWS_DIR}" "ticketly_db_password" "DATABASE_PASSWORD"

echo "✅ Secrets extraction complete."

# --- Prompt for Docker Compose restart (no changes here) ---
echo ""
read -p "Do you want to restart Docker Compose services to apply changes? (y/n) " -r restart_choice
if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
    echo "Restarting Docker Compose services..."
    cd "${PROJECT_ROOT}"
    docker-compose down && docker-compose up -d
    echo "✅ Docker Compose services restarted."
else
    echo "Skipping restart."
fi