#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
OUT="../A2DP-Sink-RedmiPad-yunluo-experimental-v0.1.zip"
rm -f "$OUT"
zip -9r "$OUT" \
  module.prop customize.sh post-fs-data.sh service.sh action.sh uninstall.sh common.sh README.md LICENSE webroot
echo "Built: $(cd .. && pwd)/${OUT#../}"
