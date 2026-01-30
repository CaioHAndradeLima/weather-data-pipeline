#!/bin/bash
set -e

# ---------------------------------------------------
# Load .env
# ---------------------------------------------------
ENV_FILE="../../../.env"
set -a
source "$ENV_FILE"
set +a


AIRBYTE_BASE="http://localhost:8000"

AUTH_HEADER=$(./login.sh)


# ---------------------------------------------------
# 1. Workspace ID (PUBLIC API)
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

# ---------------------------------------------------
# 2. Postgres sourceDefinitionId (CONFIG API)
# ---------------------------------------------------
echo "🔍 Fetching Postgres sourceDefinitionId..."

DEF_RESPONSE=$(curl -s -X POST "$AIRBYTE_BASE/api/v1/source_definitions/list" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER")

echo "$DEF_RESPONSE" | jq . >/dev/null

POSTGRES_DEF_ID=$(echo "$DEF_RESPONSE" \
  | jq -r '.sourceDefinitions[] | select(.name=="Postgres") | .sourceDefinitionId')

if [ -z "$POSTGRES_DEF_ID" ] || [ "$POSTGRES_DEF_ID" = "null" ]; then
  echo "❌ Failed to get Postgres sourceDefinitionId"
  exit 1
fi

echo "POSTGRES_DEF_ID=$POSTGRES_DEF_ID"

# ---------------------------------------------------
# 3. Create Postgres source (CDC)
# ---------------------------------------------------
echo "🚀 Creating Postgres CDC source..."

CREATE_RESPONSE=$(curl -s -X POST "$AIRBYTE_BASE/api/v1/sources/create" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d '{
    "name": "postgres_retail",
    "workspaceId": "'"$WORKSPACE_ID"'",
    "sourceDefinitionId": "'"$POSTGRES_DEF_ID"'",
    "connectionConfiguration": {
      "host": "host.docker.internal",
      "port": 5433,
      "database": "retail_prod",
      "username": "airbyte",
      "password": "airbyte_pass",
      "schemas": ["public","retail"],
      "ssl_mode": {
        "mode": "disable"
      },
      "tunnel_method": {
        "tunnel_method": "NO_TUNNEL"
      },
      "replication_method": {
        "method": "CDC",
        "replication_slot": "airbyte_slot",
        "publication": "airbyte_publication"
      }
    }
  }')

echo "$CREATE_RESPONSE" | jq . >/dev/null

SOURCE_ID=$(echo "$CREATE_RESPONSE" | jq -r '.sourceId')

if [ -z "$SOURCE_ID" ] || [ "$SOURCE_ID" = "null" ]; then
  echo "❌ Failed to create Postgres source"
  echo "$CREATE_RESPONSE"
  exit 1
fi

echo ""
echo "Postgres CDC source created successfully"
echo "SOURCE_ID=$SOURCE_ID"

# Remove existing POSTGRES_SOURCE_ID if present
sed -i.bak '/^POSTGRES_SOURCE_ID=/d' "$ENV_FILE"

echo "POSTGRES_SOURCE_ID=$SOURCE_ID" >> "$ENV_FILE"
rm -f "${ENV_FILE}.bak" # remove backup file created by sed (macOS)
