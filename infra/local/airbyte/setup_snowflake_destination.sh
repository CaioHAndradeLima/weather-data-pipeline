#!/bin/bash
set -e

ENV_FILE="../../../.env"

echo "📦 Loading env vars from $ENV_FILE"
set -a
source "$ENV_FILE"
set +a

AIRBYTE_BASE="http://localhost:8000"
AUTH_HEADER=$(./login.sh)

# ---------------------------------------------------
# 1. Workspace ID (INTERNAL API)
# ---------------------------------------------------
echo ""

WORKSPACE_RESPONSE=$(curl -s "$AIRBYTE_BASE/api/public/v1/workspaces"  \
-H "$AUTH_HEADER" \
)
echo "$WORKSPACE_RESPONSE" | jq . >/dev/null

WORKSPACE_ID=$(echo "$WORKSPACE_RESPONSE" | jq -r '.data[0].workspaceId')

if [ -z "$WORKSPACE_ID" ] || [ "$WORKSPACE_ID" = "null" ]; then
  echo "❌ Failed to get workspaceId"
  exit 1
fi

echo "WORKSPACE_ID=$WORKSPACE_ID"

sed -i.bak '/^WORKSPACE_ID=/d' "$ENV_FILE"
echo "WORKSPACE_ID=$WORKSPACE_ID" >> "$ENV_FILE"
# ---------------------------------------------------
# 2. Snowflake destinationDefinitionId (CONFIG API)
# ---------------------------------------------------
echo "🔍 Fetching Snowflake destinationDefinitionId..."

DEF_RESPONSE=$(curl -s -X POST "$AIRBYTE_BASE/api/v1/destination_definitions/list" \
  -H "$AUTH_HEADER" \
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
  -H "$AUTH_HEADER" \
  -d '{
    "name": "snowflake_retail",
    "workspaceId": "'"$WORKSPACE_ID"'",
    "destinationDefinitionId": "'"$SNOWFLAKE_DEF_ID"'",
    "connectionConfiguration": {
      "host": "'"$SNOWFLAKE_ACCOUNT"'.snowflakecomputing.com",
      "warehouse": "'"$SNOWFLAKE_WAREHOUSE"'",
      "database": "'"$SNOWFLAKE_DATABASE"'",
      "schema": "'"$SNOWFLAKE_SCHEMA"'",
      "role": "'"$SNOWFLAKE_ROLE"'",
      "username": "'"$SNOWFLAKE_USER"'",
      "credentials": {
        "password": "'"$SNOWFLAKE_PASSWORD"'",
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
