#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

echo "Stop local infra"

if command -v abctl >/dev/null 2>&1; then
  abctl local uninstall || true
fi
rm -rf "$HOME/.airbyte/abctl/data" || true

docker compose --env-file "$ENV_FILE" -f "$POSTGRES_COMPOSE_FILE" down -v || true
docker compose --env-file "$ENV_FILE" -f "$AIRFLOW_COMPOSE_FILE" down -v || true
