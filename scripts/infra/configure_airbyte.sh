#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

require_env_file
require_cmd curl
require_cmd jq

echo "Configure Airbyte credentials, source, destination, and connections"
pushd "$AIRBYTE_DIR" >/dev/null
chmod +x ./*.sh
./setup_credentials.sh
./setup_postgres_source.sh
./setup_snowflake_destination.sh
./generate_ingestion_json.sh
./create_connections.sh
popd >/dev/null
