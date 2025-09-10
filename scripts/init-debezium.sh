#!/bin/sh

set -e

echo "Waiting for Debezium Connect to start..."
sleep 30

# --- NEW: Parse the RDS_ENDPOINT variable ---
# This removes the port (e.g., ":5432") from the end of the string
export RDS_HOSTNAME=${RDS_ENDPOINT%:*}

echo "Using RDS Hostname: ${RDS_HOSTNAME}"

# Define the path for the final config file
CONFIG_FILE="/debezium/debezium-final.json"

echo "Substituting environment variables in Debezium template..."
envsubst < /debezium/debezium.json > ${CONFIG_FILE}

echo "Debezium configuration generated:"
cat ${CONFIG_FILE}

echo "Registering Debezium connector..."
# --- IMPROVED: Added -f to fail on API errors ---
curl -f -X POST -H "Content-Type: application/json" --data @${CONFIG_FILE} http://debezium-connect:8083/connectors

echo "✅ Connector registration complete!"