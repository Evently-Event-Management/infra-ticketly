#!/bin/bash

echo "🚀 Extracting secrets from Terraform..."

# --- Setup: Get project root and define .env file path ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

# --- Detect OS and set Docker socket path ---
echo "Detecting operating system..."
OS_NAME=$(uname -s)
DOCKER_SOCKET_PATH=""

if [[ "$OS_NAME" == "Linux" ]]; then
    # For native Linux and Windows users with WSL 2, this is the correct path.
    echo "-> Detected Linux / WSL 2"
    DOCKER_SOCKET_PATH="/var/run/docker.sock"
elif [[ "$OS_NAME" == "Darwin" ]]; then
    # For macOS
    echo "-> Detected macOS"
    DOCKER_SOCKET_PATH="/var/run/docker.sock"
elif [[ "$OS_NAME" == *"MINGW64_NT"* || "$OS_NAME" == *"MSYS_NT"* ]]; then
    # For Windows users using Git Bash without WSL 2
    echo "-> Detected Windows (non-WSL 2)"
    DOCKER_SOCKET_PATH="//./pipe/docker_engine"
else
    echo "-> Could not determine OS, defaulting to Linux socket path."
    DOCKER_SOCKET_PATH="/var/run/docker.sock"
fi

echo "Writing secrets to: ${ENV_FILE}"
# Overwrite .env file with a header
echo "# Terraform Outputs - Generated: $(date)" > "${ENV_FILE}"
echo "DOCKER_SOCKET_PATH=${DOCKER_SOCKET_PATH}" >> "${ENV_FILE}"

# --- The Improved Function ---
# This function takes a directory and a multi-line string of mappings.
# It runs `terraform output -json` ONCE, then uses `jq` to parse all values.
extract_outputs_from_json() {
  local dir=$1
  local mappings=$2
  local header=$3

  echo -e "\n${header}" >> "${ENV_FILE}"
  pushd "$dir" >/dev/null

  echo "Processing outputs from directory: ${dir}"
  
  # Fetch ALL outputs from the directory in one go
  json_output=$(terraform output -json)
  if [ $? -ne 0 ]; then
    echo "-> ❌ ERROR: Failed to get Terraform outputs from '${dir}'. Halting."
    popd >/dev/null
    return 1
  fi

  # Loop through each mapping (e.g., "scheduler_service_client_secret:SCHEDULER_CLIENT_SECRET")
  while IFS= read -r line; do
    if [ -z "$line" ]; then continue; fi

    tf_output_name=$(echo "$line" | cut -d: -f1)
    env_var_name=$(echo "$line" | cut -d: -f2)

    # Use jq to safely parse the value from the JSON output.
    # The '-r' flag gets the raw string without quotes.
    # The '--arg' flag safely passes the key to jq.
    # The '// empty' part makes jq output nothing if the key is null or doesn't exist.
    value=$(echo "$json_output" | jq -r --arg key "$tf_output_name" '.[$key].value // empty')

    if [ -n "$value" ]; then
      echo "$env_var_name=$value" >> "${ENV_FILE}"
      echo "  -> ✅ Extracted: $env_var_name"
    else
      echo "  -> ⚠️  WARNING: Could not extract '$tf_output_name' from '$dir' (output may not exist in this workspace)."
    fi
  done <<< "$mappings"

  popd >/dev/null
}

# --- Define Mappings ---
# Format: <terraform_output_name>:<env_variable_name>
KEYCLOAK_MAPPINGS="
scheduler_service_client_secret:SCHEDULER_CLIENT_SECRET
event_projection_service_client_secret:EVENT_PROJECTION_CLIENT_SECRET
ticket_service_client_secret:TICKET_CLIENT_SECRET
events_service_client_secret:EVENTS_SERVICE_CLIENT_SECRET
"

AWS_MAPPINGS="
aws_region:AWS_REGION
s3_bucket_name:AWS_S3_BUCKET_NAME
sqs_session_on_sale_arn:AWS_SQS_SESSION_ON_SALE_ARN
sqs_session_on_sale_url:AWS_SQS_SESSION_ON_SALE_URL
sqs_session_closed_arn:AWS_SQS_SESSION_CLOSED_ARN
sqs_session_closed_url:AWS_SQS_SESSION_CLOSED_URL
scheduler_role_arn:AWS_SCHEDULER_ROLE_ARN
scheduler_group_name:AWS_SCHEDULER_GROUP_NAME
service_user_access_key:AWS_ACCESS_KEY_ID
service_user_secret_key:AWS_SECRET_ACCESS_KEY
ticketly_db_endpoint:RDS_ENDPOINT
ticketly_db_user:DATABASE_USERNAME
ticketly_db_password:DATABASE_PASSWORD
ticketly_db_address:DATABASE_ADDRESS
ticketly_db_port:DATABASE_PORT
"

# --- Run Extraction ---
extract_outputs_from_json "${PROJECT_ROOT}/keycloak/terraform" "$KEYCLOAK_MAPPINGS" "# Keycloak Client Secrets"
extract_outputs_from_json "${PROJECT_ROOT}/aws" "$AWS_MAPPINGS" "# AWS Resources & Credentials"

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