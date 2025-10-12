#!/bin/bash

# This script verifies credentials for the existing login-testing client

# Exit on error
set -e

# Keycloak settings
KEYCLOAK_URL="http://auth.ticketly.com:8080"
REALM="event-ticketing"
USERNAME="user@yopmail.com"
PASSWORD="user123"
CLIENT_ID="login-testing"

echo "🔑 Verifying credentials for Keycloak client: $CLIENT_ID"

# Test credentials to verify they work
echo "Testing credentials by requesting a token..."
TOKEN_RESPONSE=$(curl -s \
  -d "client_id=$CLIENT_ID" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD" \
  -d "grant_type=password" \
  -d "scope=internal-api" \
  "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token")

# Extract the token or error message
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
ERROR_MESSAGE=$(echo "$TOKEN_RESPONSE" | grep -o '"error_description":"[^"]*' | cut -d'"' -f4)

if [ -n "$ACCESS_TOKEN" ]; then
  echo "✅ Successfully obtained token for $CLIENT_ID"
  
  # Verify the token contains the internal-api scope
  echo "Checking if token has internal-api scope..."
  SCOPE=$(echo "$TOKEN_RESPONSE" | grep -o '"scope":"[^"]*' | cut -d'"' -f4)
  
  if [[ "$SCOPE" == *"internal-api"* ]]; then
    echo "✅ Token includes internal-api scope"
  else
    echo "⚠️ Warning: Token does not include internal-api scope. Add it in Keycloak."
  fi
  
  # Extract token information
  TOKEN_TYPE=$(echo "$TOKEN_RESPONSE" | grep -o '"token_type":"[^"]*' | cut -d'"' -f4)
  EXPIRES_IN=$(echo "$TOKEN_RESPONSE" | grep -o '"expires_in":[^,}]*' | cut -d':' -f2)
  
  echo "Token type: $TOKEN_TYPE"
  echo "Expires in: $EXPIRES_IN seconds"
else
  echo "❌ Failed to get token: $ERROR_MESSAGE"
  exit 1
fi

echo ""
echo "🔧 Update your config.js with these values:"
echo "  clientId: \"$CLIENT_ID\","
echo "  username: \"$USERNAME\","
echo "  password: \"$PASSWORD\","
echo "  scope: \"internal-api\""