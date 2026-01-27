#!/bin/bash
set -euo pipefail

# ---------------------------------------------------
# Configuration
# ---------------------------------------------------
ENV_FILE="../../../.env"
AIRBYTE_BASE="http://localhost:8000/api/v1"
WORKSPACE_ID="1c09d0f7-0652-420d-b99b-50b1d0622e52"
TABLES_FILE="tables.json"

# ---------------------------------------------------
# Load env vars
# ---------------------------------------------------
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env file not found at $ENV_FILE"
  exit 1
fi

echo "Loading env vars from $ENV_FILE"
set -a
source "$ENV_FILE"
set +a

if [ -z "${POSTGRES_SOURCE_ID:-}" ] || [ -z "${SNOWFLAKE_DESTINATION_ID:-}" ]; then
  echo "ERROR: POSTGRES_SOURCE_ID or SNOWFLAKE_DESTINATION_ID not set"
  exit 1
fi

SOURCE_ID="$POSTGRES_SOURCE_ID"
DESTINATION_ID="$SNOWFLAKE_DESTINATION_ID"

if [ ! -f "$TABLES_FILE" ]; then
  echo "ERROR: tables.json not found"
  exit 1
fi

echo "Source ID: $SOURCE_ID"
echo "Destination ID: $DESTINATION_ID"
echo "Workspace ID: $WORKSPACE_ID"

# ---------------------------------------------------
# Discover source schema
# ---------------------------------------------------
echo "Discovering source schema..."

DISCOVER_RESPONSE=$(curl -s -X POST "$AIRBYTE_BASE/sources/discover_schema" \
  -H "Content-Type: application/json" \
  -d "{\"sourceId\":\"$SOURCE_ID\"}")

if ! echo "$DISCOVER_RESPONSE" | jq -e '.catalog.streams' >/dev/null; then
  echo "ERROR: Invalid discover_schema response"
  echo "$DISCOVER_RESPONSE"
  exit 1
fi

CATALOG=$(echo "$DISCOVER_RESPONSE" | jq '.catalog')

echo "Discovered tables:"
echo "$CATALOG" | jq -r '.streams[].stream | "\(.namespace).\(.name)"'

# ---------------------------------------------------
# Build syncCatalog.streams
# ---------------------------------------------------
echo "Building sync catalog from tables.json..."

STREAMS=$(jq -n \
  --argjson catalog "$CATALOG" \
  --slurpfile cfg "$TABLES_FILE" '
  [
    $catalog.streams[] as $stream
    | $cfg[0].tables[] as $table
    | select(
        $stream.stream.name == $table.name
        and
        ($stream.stream.namespace // "public") == $table.namespace
      )
    | {
        stream: $stream.stream,
        config: {
          selected: true,
          syncMode: $table.sync_mode,
          destinationSyncMode: $table.destination_sync_mode,
          cursorField: $table.cursor,
          primaryKey: ($table.primary_key | map([.]))
        }
      }
  ]
')

STREAM_COUNT=$(echo "$STREAMS" | jq 'length')

if [ "$STREAM_COUNT" -eq 0 ]; then
  echo "ERROR: No matching tables found between discovery and tables.json"
  exit 1
fi

echo "Prepared $STREAM_COUNT stream configurations"

# ---------------------------------------------------
# Check for existing connection
# ---------------------------------------------------
echo "Checking for existing connection..."

EXISTING=$(curl -s -X POST "$AIRBYTE_BASE/connections/list" \
  -H "Content-Type: application/json" \
  -d "{\"workspaceId\":\"$WORKSPACE_ID\"}")

CONNECTION_ID=$(echo "$EXISTING" | jq -r \
  ".connections[]
   | select(.sourceId==\"$SOURCE_ID\" and .destinationId==\"$DESTINATION_ID\")
   | .connectionId" | head -n1)

# ---------------------------------------------------
# Create or update connection
# ---------------------------------------------------
if [ -z "$CONNECTION_ID" ] || [ "$CONNECTION_ID" = "null" ]; then
  echo "Creating new connection..."

  CONNECTION_NAME=$(jq -r '.connection.name' "$TABLES_FILE")
  CONNECTION_STATUS=$(jq -r '.connection.status' "$TABLES_FILE")

  CREATE_RESPONSE=$(curl -s -X POST "$AIRBYTE_BASE/connections/create" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$CONNECTION_NAME\",
      \"sourceId\": \"$SOURCE_ID\",
      \"destinationId\": \"$DESTINATION_ID\",
      \"workspaceId\": \"$WORKSPACE_ID\",
      \"status\": \"$CONNECTION_STATUS\",
      \"syncCatalog\": { \"streams\": $STREAMS }
    }")

  CONNECTION_ID=$(echo "$CREATE_RESPONSE" | jq -r '.connectionId')

  if [ -z "$CONNECTION_ID" ] || [ "$CONNECTION_ID" = "null" ]; then
    echo "ERROR: Failed to create connection"
    echo "$CREATE_RESPONSE"
    exit 1
  fi

else
  echo "Updating existing connection: $CONNECTION_ID"

  curl -s -X POST "$AIRBYTE_BASE/connections/update" \
    -H "Content-Type: application/json" \
    -d "{
      \"connectionId\": \"$CONNECTION_ID\",
      \"syncCatalog\": { \"streams\": $STREAMS }
    }" >/dev/null
fi

echo "Connection ready: $CONNECTION_ID"

# ---------------------------------------------------
# Trigger sync
# ---------------------------------------------------
echo "Triggering sync..."

curl -s -X POST "$AIRBYTE_BASE/connections/sync" \
  -H "Content-Type: application/json" \
  -d "{\"connectionId\":\"$CONNECTION_ID\"}" >/dev/null

echo "Sync triggered successfully"
