#!/bin/bash
set -e

ENV_FILE="../../../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env file not found at $ENV_FILE"
  exit 1
fi

echo "Loading env vars from $ENV_FILE"
set -a
source "$ENV_FILE"
set +a

AIRBYTE_BASE="http://localhost:8000/api/v1"
SOURCE_ID="${POSTGRES_SOURCE_ID}"
OUTPUT_FILE="tables.json"

if [ -z "$SOURCE_ID" ]; then
  echo "ERROR: POSTGRES_SOURCE_ID is not set"
  exit 1
fi

echo "Discovering schema from Airbyte..."
DISCOVER_RESPONSE=$(curl -s -X POST "$AIRBYTE_BASE/sources/discover_schema" \
  -H "Content-Type: application/json" \
  -d "{\"sourceId\":\"$SOURCE_ID\"}")

CATALOG=$(echo "$DISCOVER_RESPONSE" | jq '.catalog')

STREAM_COUNT=$(echo "$CATALOG" | jq '.streams | length')

if [ "$STREAM_COUNT" -eq 0 ]; then
  echo "ERROR: No streams discovered"
  exit 1
fi

echo "Discovered $STREAM_COUNT streams"
echo "Generating tables.json..."

jq -n \
  --argjson catalog "$CATALOG" '
  {
    connection: {
      name: "postgres_to_snowflake",
      status: "active"
    },
    tables: [
      $catalog.streams[]
      | {
          name: .stream.name,
          namespace: .stream.namespace,
          sync_mode: "incremental",
          destination_sync_mode: "append_dedup",
          cursor: [],
          primary_key: (
            if (.stream.sourceDefinedPrimaryKey | length) > 0
            then (.stream.sourceDefinedPrimaryKey | map(.[0]))
            else []
            end
          )
        }
    ]
  }' > "$OUTPUT_FILE"

echo "tables.json generated successfully"
echo "--------------------------------"
jq . "$OUTPUT_FILE"
echo "--------------------------------"
