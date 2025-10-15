#!/bin/sh

set -e

CONNECT_URL="http://debezium-connect:8083/connectors"
CONFIG_TEMPLATE="/debezium/debezium.json"
CONFIG_FILE="/debezium/debezium-final.json"

echo "Waiting for Debezium Connect to start..."
# A simple sleep is okay, but a loop would be more robust
# For now, we'll keep the sleep to match your original script
sleep 30

echo "Substituting environment variables in Debezium template..."
envsubst < ${CONFIG_TEMPLATE} > ${CONFIG_FILE}

# Extract connector name from the JSON config file
# This requires `jq` to be installed (we'll add it in the docker-compose file)
CONNECTOR_NAME=$(jq -r .name ${CONFIG_FILE})

echo "Generated config for connector: '${CONNECTOR_NAME}'"
cat ${CONFIG_FILE}

# Check if the connector already exists
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${CONNECT_URL}/${CONNECTOR_NAME}")

if [ "$STATUS_CODE" -eq "404" ]; then
  # Connector does not exist, so create it with POST
  echo "Connector '${CONNECTOR_NAME}' not found. Creating..."
  curl -X POST -H "Content-Type: application/json" --data @${CONFIG_FILE} ${CONNECT_URL}
elif [ "$STATUS_CODE" -eq "200" ]; then
  # Connector exists, so update it with PUT
  echo "Connector '${CONNECTOR_NAME}' found. Updating configuration..."
  curl -X PUT -H "Content-Type: application/json" --data "$(jq .config ${CONFIG_FILE})" "${CONNECT_URL}/${CONNECTOR_NAME}/config"
else
  # Handle other potential errors (e.g., Debezium is down)
  echo "Error: Received status code ${STATUS_CODE} when checking for connector '${CONNECTOR_NAME}'."
  exit 1
fi

echo "✅ Connector '${CONNECTOR_NAME}' is configured."