#!/usr/bin/env bash
set -e

ENV_FILE="../../../.env"

echo "Running Airbyte instance setup..."


SETUP_RESPONSE=$(curl -s -X POST \
  "http://localhost:8000/api/v1/instance_configuration/setup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@gmail.com",
    "anonymousDataCollection": false,
    "securityCheck": "succeeded",
    "organizationName": "organization name",
    "initialSetupComplete": true,
    "displaySetupWizard": false
  }')

echo "Setup response:"
echo "$SETUP_RESPONSE"

echo "Generating API credentials..."

CREDS_RESPONSE=$(abctl local credentials)
echo "Credentials response:"
echo "$CREDS_RESPONSE"

CLEAN_RESPONSE=$(echo "$CREDS_RESPONSE" | sed 's/\x1b\[[0-9;]*m//g')

CLIENT_ID=$(echo "$CLEAN_RESPONSE" \
  | grep 'Client-Id:' \
  | sed 's/.*Client-Id:[[:space:]]*//')

CLIENT_SECRET=$(echo "$CLEAN_RESPONSE" \
  | grep 'Client-Secret:' \
  | sed 's/.*Client-Secret:[[:space:]]*//')

if [[ -z "$CLIENT_ID" || -z "$CLIENT_SECRET" ]]; then
  echo "❌ Failed to retrieve Airbyte credentials"
  echo "----- DEBUG OUTPUT -----"
  echo "$CLEAN_RESPONSE"
  echo "CLIENT_SECRET=$CLIENT_SECRET"
  exit 1
fi

echo "AIRBYTE_CLIENT_ID=$CLIENT_ID"
echo "AIRBYTE_CLIENT_SECRET=$CLIENT_SECRET"

# Optional: remove existing keys before appending (idempotent)
sed -i.bak '/^AIRBYTE_CLIENT_ID=/d' "$ENV_FILE"
sed -i.bak '/^AIRBYTE_CLIENT_SECRET=/d' "$ENV_FILE"

echo "AIRBYTE_CLIENT_ID=$CLIENT_ID" >> "$ENV_FILE"
echo "AIRBYTE_CLIENT_SECRET=$CLIENT_SECRET" >> "$ENV_FILE"

echo "Credentials retrieved successfully and saved into .env"
