#!/system/bin/sh
MODDIR=${0%/*}
[ -f "$MODDIR/common.sh" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/common.sh"
cat > /data/adb/a2dp-sink-yunluo <<WRAP
#!/system/bin/sh
exec sh "$MODDIR/action.sh" "\$@"
WRAP
chmod 755 /data/adb/a2dp-sink-yunluo 2>/dev/null || true
sleep 10
if [ -f "$MODE_MARKER" ]; then set_source_props || true
elif [ -f "$CONCURRENT_MARKER" ]; then set_concurrent_props || true
else set_sink_props || true; fi
ensure_audio_focus_overlay >/dev/null 2>&1 || true
