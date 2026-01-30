#!/usr/bin/env bash
set -e

ENV_FILE="../../../.env"
set -a
source "$ENV_FILE"
set +a

AIRBYTE_URL="http://localhost:8000"

TOKEN_RESPONSE=$(curl -s -X POST "$AIRBYTE_URL/api/v1/applications/token" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"client_id\": \"$AIRBYTE_CLIENT_ID\",
    \"client_secret\": \"$AIRBYTE_CLIENT_SECRET\",
    \"grant-type\": \"client_credentials\"
  }")

echo "$TOKEN_RESPONSE"
# Extract ONLY the token
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "❌ Failed to retrieve access token" >&2
  exit 1
fi

AUTH_HEADER="Authorization: Bearer $ACCESS_TOKEN"

echo "$AUTH_HEADER"
