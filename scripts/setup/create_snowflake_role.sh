#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

echo "Create Snowflake role and terraform user"

load_env
require_cmd snowsql

snowflake_account_id="${SNOWFLAKE_ACCOUNT_IDENTIFIER:-${SNOWFLAKE_ORGANIZATION_NAME}-${SNOWFLAKE_ACCOUNT}}"
bootstrap_warehouse="${SNOWFLAKE_TERRAFORM_WAREHOUSE:-COMPUTE_WH}"

SNOWSQL_PWD="$SNOWFLAKE_PASSWORD" snowsql \
  -a "$snowflake_account_id" \
  -u "$SNOWFLAKE_USER" \
  -r "$SNOWFLAKE_ROLE" \
  -w "$bootstrap_warehouse" \
  -f "$PROJECT_ROOT/infra/remote/snowflake/setup/roles.sql" \
  -o log_level=ERROR \
  -o exit_on_error=true

echo "Created/updated TERRAFORM_ROLE and TERRAFORM_USER from roles.sql"
