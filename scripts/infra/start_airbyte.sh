#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

require_env_file
require_cmd abctl

echo "Start local Airbyte"
pushd "$AIRBYTE_DIR" >/dev/null
chmod +x ./*.sh
./start_airbyte.sh
popd >/dev/null
