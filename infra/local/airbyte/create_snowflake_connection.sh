#!/bin/bash
set -e

ENV_FILE="../../../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env file not found at $ENV_FILE"
  exit 1
fi

echo "📦 Loading env vars from $ENV_FILE"
set -a
source "$ENV_FILE"
set +a

AIRBYTE_BASE="http://localhost:8000"

echo "⏳ Waiting for Airbyte..."
until curl -s "$AIRBYTE_BASE/api/v1/health" | jq -e '.available == true' >/dev/null; do
  sleep 5
done
echo "✅ Airbyte is ready"

# ---------------------------------------------------
# 1. Workspace ID (PUBLIC API — same as manual)
# ---------------------------------------------------
echo "🔍 Fetching workspace ID (public API)..."

WORKSPACE_RESPONSE=$(curl -s "$AIRBYTE_BASE/api/public/v1/workspaces")
echo "$WORKSPACE_RESPONSE" | jq . >/dev/null

WORKSPACE_ID=$(echo "$WORKSPACE_RESPONSE" | jq -r '.data[0].workspaceId')

if [ -z "$WORKSPACE_ID" ] || [ "$WORKSPACE_ID" = "null" ]; then
  echo "❌ Failed to get workspaceId"
  exit 1
fi

echo "WORKSPACE_ID=$WORKSPACE_ID"
# save workspace id into .env
sed -i.bak '/^WORKSPACE_ID=/d' "$ENV_FILE"
echo "WORKSPACE_ID=$WORKSPACE_ID" >> $ENV_FILE

# ---------------------------------------------------
# 2. Snowflake destinationDefinitionId (CONFIG API)
# ---------------------------------------------------
echo "🔍 Fetching Snowflake destinationDefinitionId..."

DEF_RESPONSE=$(curl -s -X POST "$AIRBYTE_BASE/api/v1/destination_definitions/list" \
  -H "Content-Type: application/json")

echo "$DEF_RESPONSE" | jq . >/dev/null

SNOWFLAKE_DEF_ID=$(echo "$DEF_RESPONSE" \
  | jq -r '.destinationDefinitions[] | select(.name=="Snowflake") | .destinationDefinitionId')

if [ -z "$SNOWFLAKE_DEF_ID" ] || [ "$SNOWFLAKE_DEF_ID" = "null" ]; then
  echo "❌ Failed to get Snowflake destinationDefinitionId"
  exit 1
fi

echo "SNOWFLAKE_DEF_ID=$SNOWFLAKE_DEF_ID"

# ---------------------------------------------------
# 3. Create Snowflake destination (CONFIG API)
# ---------------------------------------------------
echo "🚀 Creating Snowflake destination..."

CREATE_RESPONSE=$(curl -s -X POST "$AIRBYTE_BASE/api/v1/destinations/create" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "snowflake_retail_fresh1",
    "workspaceId": "'"$WORKSPACE_ID"'",
    "destinationDefinitionId": "'"$SNOWFLAKE_DEF_ID"'",
    "connectionConfiguration": {
      "host": "YS80657.us-east-2.aws.snowflakecomputing.com",
      "warehouse": "RETAIL_WH",
      "database": "RETAIL_ANALYTICS",
      "schema": "BRONZE",
      "role": "ACCOUNTADMIN",
      "username": "CAIOHANDRADELIMA",
      "credentials": {
        "password": "Otr@conta1Health",
        "auth_type": "Username and Password"
      },
      "cdc_deletion_mode": "Hard delete"
    }
  }')

echo "$CREATE_RESPONSE" | jq . >/dev/null

DESTINATION_ID=$(echo "$CREATE_RESPONSE" | jq -r '.destinationId')

if [ -z "$DESTINATION_ID" ] || [ "$DESTINATION_ID" = "null" ]; then
  echo "❌ Failed to create destination"
  echo "$CREATE_RESPONSE"
  exit 1
fi

echo ""
echo "Snowflake destination created successfully"
echo "DESTINATION_ID=$DESTINATION_ID"
# Remove existing POSTGRES_SOURCE_ID if present
sed -i.bak '/^SNOWFLAKE_DESTINATION_ID=/d' "$ENV_FILE"
echo "SNOWFLAKE_DESTINATION_ID=$DESTINATION_ID" >> $ENV_FILE
