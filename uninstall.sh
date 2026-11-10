#!/system/bin/sh
MODDIR=${0%/*}
[ -f "$MODDIR/common.sh" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/common.sh" 2>/dev/null || true
disable_audio_focus_overlay 2>/dev/null || true
set_source_props 2>/dev/null || true
rm -f "$MODE_MARKER" "$CONCURRENT_MARKER" /data/adb/a2dp-sink-yunluo
log "uninstall: restored SOURCE mode and cleaned up"
