#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

load_env

DBT_DIR="$PROJECT_ROOT/dbt"
DBT_PROFILES_FILE="$DBT_DIR/profiles.yml"

if [ ! -d "$DBT_DIR" ]; then
  echo "Missing dbt directory at $DBT_DIR"
  exit 1
fi

cat >"$DBT_PROFILES_FILE" <<EOF
weather_pipeline:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: ${SNOWFLAKE_ORGANIZATION_NAME}-${SNOWFLAKE_ACCOUNT}
      user: ${SNOWFLAKE_USER}
      password: ${SNOWFLAKE_PASSWORD}
      role: ${SNOWFLAKE_ROLE}
      warehouse: ${SNOWFLAKE_WAREHOUSE}
      database: ${SNOWFLAKE_DATABASE}
      schema: BRONZE
      threads: 4
EOF

echo "dbt profile generated at $DBT_PROFILES_FILE"
