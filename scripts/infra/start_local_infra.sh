#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Start full local infra: Airbyte -> Postgres -> Airbyte setup -> Airflow"
bash "$SCRIPT_DIR/start_airbyte.sh"
bash "$SCRIPT_DIR/start_postgres.sh"
bash "$SCRIPT_DIR/configure_airbyte.sh"
bash "$SCRIPT_DIR/start_airflow.sh"
