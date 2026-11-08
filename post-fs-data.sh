#!/system/bin/sh
MODDIR=${0%/*}
[ -f "$MODDIR/common.sh" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/common.sh"
if [ -f "$MODE_MARKER" ]; then log "post-fs-data: SOURCE"; set_source_props || true
elif [ -f "$CONCURRENT_MARKER" ]; then log "post-fs-data: CONCURRENT"; set_concurrent_props || true
else log "post-fs-data: SINK"; set_sink_props || true; fi
