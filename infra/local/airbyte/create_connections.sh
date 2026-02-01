#!/bin/bash
set -euo pipefail

# ---------------------------------------------------
# Configuration
# ---------------------------------------------------
ENV_FILE="../../../.env"
AIRBYTE_BASE="http://localhost:8000/api/v1"
TABLES_FILE="tables.json"
AUTH_HEADER=$(./login.sh)

# ---------------------------------------------------
# Load env vars
# ---------------------------------------------------
echo "Loading env vars from $ENV_FILE"
set -a
source "$ENV_FILE"
set +a

if [ -z "${POSTGRES_SOURCE_ID:-}" ] || [ -z "${SNOWFLAKE_DESTINATION_ID:-}" ] || [ -z "${WORKSPACE_ID:-}" ]; then
  echo "ERROR: Required env vars not set"
  exit 1
fi

SOURCE_ID="$POSTGRES_SOURCE_ID"
DESTINATION_ID="$SNOWFLAKE_DESTINATION_ID"

if [ ! -f "$TABLES_FILE" ]; then
  echo "ERROR: tables.json not found"
  exit 1
fi

# ---------------------------------------------------
# Discover source schema (once)
# ---------------------------------------------------
echo "Discovering source schema..."

DISCOVER_RESPONSE=$(curl -s -X POST "$AIRBYTE_BASE/sources/discover_schema" \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  -d "{\"sourceId\":\"$SOURCE_ID\"}")

if ! echo "$DISCOVER_RESPONSE" | jq -e '.catalog.streams' >/dev/null; then
  echo "ERROR: Invalid discover_schema response"
  echo "$DISCOVER_RESPONSE"
  exit 1
fi

CATALOG=$(echo "$DISCOVER_RESPONSE" | jq '.catalog')

# ---------------------------------------------------
# Loop over connections
# ---------------------------------------------------
CONNECTION_COUNT=$(jq 'length' "$TABLES_FILE")
echo "Processing $CONNECTION_COUNT connections"

for i in $(seq 0 $((CONNECTION_COUNT - 1))); do
  CONNECTION=$(jq ".[$i]" "$TABLES_FILE")

  CONNECTION_NAME=$(echo "$CONNECTION" | jq -r '.name')
  CONNECTION_STATUS=$(echo "$CONNECTION" | jq -r '.status')

  echo ""
  echo "Processing connection: $CONNECTION_NAME"

  # ---------------------------------------------------
  # Build syncCatalog.streams for this connection
  # ---------------------------------------------------
  STREAMS=$(jq -n \
    --argjson catalog "$CATALOG" \
    --argjson tables "$(echo "$CONNECTION" | jq '.tables')" '
    [
      $catalog.streams[] as $stream
      | $tables[] as $table
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
    echo "No matching streams found for $CONNECTION_NAME — skipping"
    continue
  fi

  # ---------------------------------------------------
  # Check if connection already exists (by name)
  # ---------------------------------------------------
  EXISTING=$(curl -s -X POST "$AIRBYTE_BASE/connections/list" \
    -H "Content-Type: application/json" \
    -H "$AUTH_HEADER" \
    -d "{\"workspaceId\":\"$WORKSPACE_ID\"}")

  CONNECTION_ID=$(echo "$EXISTING" | jq -r \
    ".connections[] | select(.name==\"$CONNECTION_NAME\") | .connectionId" | head -n1)

  # ---------------------------------------------------
  # Create or update connection
  # ---------------------------------------------------
  if [ -z "$CONNECTION_ID" ] || [ "$CONNECTION_ID" = "null" ]; then
    echo "Creating connection: $CONNECTION_NAME"

    CREATE_RESPONSE=$(curl -s -X POST "$AIRBYTE_BASE/connections/create" \
      -H "Content-Type: application/json" \
      -H "$AUTH_HEADER" \
      -d "{
        \"name\": \"$CONNECTION_NAME\",
        \"workspaceId\": \"$WORKSPACE_ID\",
        \"sourceId\": \"$SOURCE_ID\",
        \"destinationId\": \"$DESTINATION_ID\",
        \"status\": \"$CONNECTION_STATUS\",
        \"namespaceDefinition\": \"destination\",
        \"namespaceFormat\": null,
        \"status\": \"$CONNECTION_STATUS\",
        \"syncCatalog\": { \"streams\": $STREAMS }
      }")

    CONNECTION_ID=$(echo "$CREATE_RESPONSE" | jq -r '.connectionId')

    if [ -z "$CONNECTION_ID" ] || [ "$CONNECTION_ID" = "null" ]; then
      echo "ERROR: Failed to create connection $CONNECTION_NAME"
      echo "$CREATE_RESPONSE"
      exit 1
    fi
  else
    echo "Updating connection: $CONNECTION_NAME"

    curl -s -X POST "$AIRBYTE_BASE/connections/update" \
      -H "Content-Type: application/json" \
      -H "$AUTH_HEADER" \
      -d "{
        \"connectionId\": \"$CONNECTION_ID\",
        \"syncCatalog\": { \"streams\": $STREAMS },
        \"namespaceDefinition\": \"destination\",
        \"namespaceFormat\": null

      }" >/dev/null
  fi

  # ---------------------------------------------------
  # Trigger sync - Airflow is orchestrating syncs
  # ---------------------------------------------------
  #curl -s -X POST "$AIRBYTE_BASE/connections/sync" \
  #  -H "Content-Type: application/json" \
  #  -d "{\"connectionId\":\"$CONNECTION_ID\"}" >/dev/null
done

echo ""
echo "All connections processed successfully"
