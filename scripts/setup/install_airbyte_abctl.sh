#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

echo "Install Airbyte abctl"

require_cmd brew
brew tap airbytehq/tap
brew install abctl
