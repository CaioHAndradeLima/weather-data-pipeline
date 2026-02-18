#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Start full local infra"
bash "$SCRIPT_DIR/start_local_infra.sh"
