#!/bin/bash

echo "🚀 Extracting secrets from Terraform..."

# --- Setup: Get project root and define .env file path ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"
ENV_LOCAL_FILE="${PROJECT_ROOT}/.env.local"

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
scheduler_role_arn:AWS_SCHEDULER_ROLE_ARN
scheduler_group_name:AWS_SCHEDULER_GROUP_NAME
service_user_access_key:AWS_ACCESS_KEY_ID
sqs_session_scheduling_arn:AWS_SQS_SESSION_SCHEDULING_ARN
sqs_session_scheduling_url:AWS_SQS_SESSION_SCHEDULING_URL
sqs_trending_job_arn:AWS_SQS_TRENDING_JOB_ARN
sqs_trending_job_url:AWS_SQS_TRENDING_JOB_URL
sqs_session_reminders_arn:AWS_SQS_SESSION_REMINDERS_ARN
sqs_session_reminders_url:AWS_SQS_SESSION_REMINDERS_URL
service_user_secret_key:AWS_SECRET_ACCESS_KEY
ticketly_db_endpoint:RDS_ENDPOINT
ticketly_db_user:DATABASE_USERNAME
ticketly_db_password:DATABASE_PASSWORD
ticketly_db_address:DATABASE_ADDRESS
ticketly_db_port:DATABASE_PORT
"

# --- Extract Google Analytics credentials ---
extract_ga_credentials() {
  local credentials_file="${PROJECT_ROOT}/credentials/gcp-credentials.json"
  local header="# Google Analytics Credentials"

  echo -e "\n${header}" >> "${ENV_FILE}"

  if [ -f "$credentials_file" ]; then
    echo "Processing Google Analytics credentials from: $credentials_file"
    
    # Note: GA_PROPERTY_ID is not extracted from credentials.json
    # It should be defined in .env.local instead
    
    # Extract client_email
    client_email=$(jq -r '.client_email // empty' "$credentials_file")
    if [ -n "$client_email" ]; then
      echo "GOOGLE_CLIENT_EMAIL=\"${client_email}\"" >> "${ENV_FILE}"
      echo "  -> ✅ Extracted: GOOGLE_CLIENT_EMAIL"
    fi
    
    # Extract private_key (preserving newlines)
    private_key=$(jq -r '.private_key // empty' "$credentials_file")
    if [ -n "$private_key" ]; then
      echo "GOOGLE_PRIVATE_KEY=\"${private_key}\"" >> "${ENV_FILE}"
      echo "  -> ✅ Extracted: GOOGLE_PRIVATE_KEY"
    fi
    
    # Extract client_id
    client_id=$(jq -r '.client_id // empty' "$credentials_file")
    if [ -n "$client_id" ]; then
      echo "GOOGLE_CLIENT_ID=${client_id}" >> "${ENV_FILE}"
      echo "  -> ✅ Extracted: GOOGLE_CLIENT_ID"
    fi
    
    # Extract private_key_id
    private_key_id=$(jq -r '.private_key_id // empty' "$credentials_file")
    if [ -n "$private_key_id" ]; then
      echo "GOOGLE_PRIVATE_KEY_ID=${private_key_id}" >> "${ENV_FILE}"
      echo "  -> ✅ Extracted: GOOGLE_PRIVATE_KEY_ID"
    fi
  else
    echo "  -> ⚠️ WARNING: GCP credentials file not found at ${credentials_file}"
  fi
}

# --- Run Extraction ---
if [[ "$1" == "aws-only" ]]; then
  # Extract only AWS resources
  echo "Running in AWS-only mode..."
  extract_outputs_from_json "${PROJECT_ROOT}/aws" "$AWS_MAPPINGS" "# AWS Resources & Credentials"
  extract_ga_credentials
else
  # Extract all resources
  extract_outputs_from_json "${PROJECT_ROOT}/keycloak/terraform" "$KEYCLOAK_MAPPINGS" "# Keycloak Client Secrets"
  extract_outputs_from_json "${PROJECT_ROOT}/aws" "$AWS_MAPPINGS" "# AWS Resources & Credentials"
  extract_ga_credentials
fi

# Append .env.local content at the end, overriding any previous values
if [ -f "${ENV_LOCAL_FILE}" ]; then
    echo -e "\n# Local Environment Variables (from .env.local)" >> "${ENV_FILE}"
    echo "-> ℹ️ Appending .env.local contents (these will override any previous values)..."
    
    # Read .env.local and append all non-commented, non-empty lines
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        if [[ ! "$line" =~ ^[[:space:]]*# && -n "$line" && "$line" == *"="* ]]; then
            # Extract the key part (before the first =)
            key=$(echo "$line" | cut -d= -f1)
            echo "$line" >> "${ENV_FILE}"
            echo "  -> ✅ Added from .env.local: $key"
        fi
    done < "${ENV_LOCAL_FILE}"
fi

echo "✅ Secrets extraction complete."

# # --- Prompt for Docker Compose restart (no changes here) ---
# echo ""
# read -p "Do you want to restart Docker Compose services to apply changes? (y/n) " -r restart_choice
# if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
#     echo "Restarting Docker Compose services..."
#     cd "${PROJECT_ROOT}"
#     docker compose down && docker compose up -d
#     echo "✅ Docker Compose services restarted."
# else
#     echo "Skipping restart."
# fi