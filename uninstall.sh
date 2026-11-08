#!/system/bin/sh
MODDIR=${0%/*}
[ -f "$MODDIR/common.sh" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/common.sh" 2>/dev/null || true
remove_sink_interop 2>/dev/null || true
disable_audio_focus_overlay 2>/dev/null || true
set_source_props 2>/dev/null || true
rm -f "$MODE_MARKER" /data/adb/a2dp-sink-yunluo /data/adb/a2dp_sink_yunluo_learned.conf
log "uninstall: restored SOURCE mode and cleaned up"
