#!/system/bin/sh
MODDIR=${0%/*}
[ -f "$MODDIR/common.sh" ] || MODDIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
. "$MODDIR/common.sh"

ACTION=${1:-toggle}
if [ "$ACTION" = "toggle" ]; then
    if [ "$(current_mode)" = "source" ]; then ACTION=on; echo "Currently SOURCE; switching to SINK..."; else ACTION=off; echo "Currently SINK/CONCURRENT; switching to SOURCE..."; fi
fi

case "$ACTION" in
    status) show_status ;;
    off|source|normal)
        touch "$MODE_MARKER" 2>/dev/null || true; rm -f "$CONCURRENT_MARKER" 2>/dev/null || true
        echo "Switching to SOURCE (normal Bluetooth output)..."
        set_source_props || { echo "Could not set properties."; exit 1; }
        restart_bluetooth source || true
        echo; show_status; echo; echo "Normal Bluetooth output restored."
        ;;
    on|sink|receiver)
        rm -f "$MODE_MARKER" "$CONCURRENT_MARKER" 2>/dev/null || true
        echo "Switching to SINK (receiver)..."
        set_sink_props || { echo "Could not set properties."; exit 1; }
        restart_bluetooth sink || true
        echo; show_status; echo
        echo "Sink mode on (SBC/AAC supported; AAC observed working)."
        echo "After connecting, wait a few seconds. No sound? BT off/on on both devices, or: restart"
        ;;
    concurrent|both|dual)
        echo "EXPERIMENTAL: enabling CONCURRENT A2DP source+sink (stack flag supported; routing not guaranteed)."
        rm -f "$MODE_MARKER" 2>/dev/null || true; touch "$CONCURRENT_MARKER" 2>/dev/null || true
        set_concurrent_props || { echo "Could not set properties."; exit 1; }
        restart_bluetooth concurrent || true
        echo; show_status; echo
        echo "If audio routing misbehaves, revert: $0 off  OR  $0 on"
        ;;
    restart|restart-sink)
        _cm=$(current_mode)
        echo "Restarting Bluetooth (mode: $_cm)..."
        case "$_cm" in sink) set_sink_props; rm -f "$MODE_MARKER" "$CONCURRENT_MARKER" ;; source) set_source_props; touch "$MODE_MARKER"; rm -f "$CONCURRENT_MARKER" ;; concurrent) set_concurrent_props; rm -f "$MODE_MARKER"; touch "$CONCURRENT_MARKER" ;; esac >/dev/null 2>&1 || true
        restart_bluetooth "$_cm" || true
        echo; show_status; echo; echo "Restarted. Reconnect devices as needed."
        ;;
    learn|fix)
        _addr=${2:-}
        if [ -n "$_addr" ] && [ "$_addr" != "--force-sbc" ]; then
            _p=$(echo "$_addr" | tr 'A-F' 'a-f' | awk -F: '{if(NF>=3) print $1":"$2":"$3}')
            if [ -n "$_p" ]; then _cur=""; [ -f "$LEARNED_INTEROP_FILE" ] && . "$LEARNED_INTEROP_FILE" 2>/dev/null && _cur=$A2DP_SINK_LEARNED; printf 'A2DP_SINK_LEARNED=%s\n' "$(echo "${_cur},${_p}" | tr ',' '\n' | awk 'NF && !seen[$0]++{out=(out==""?$0:out "," $0)} END{print out}')" > "$LEARNED_INTEROP_FILE"; echo "Learned: $_p"; else echo "Invalid address"; exit 1; fi
        fi
        echo "Learning addresses and (troubleshooting) forcing SBC for learned sources..."
        _disc=$(discover_sink_blacklist_addrs 2>/dev/null | tr '\n' ',' | sed 's/,$//'); [ -n "$_disc" ] && echo "Discovered: $_disc"
        A2DP_SINK_FORCE_SBC=true
        mkdir -p /data/adb 2>/dev/null
        if [ -f /data/adb/a2dp_sink_yunluo.conf ]; then grep -v '^A2DP_SINK_FORCE_SBC=' /data/adb/a2dp_sink_yunluo.conf > /data/adb/a2dp_sink_yunluo.conf.tmp 2>/dev/null || true; printf 'A2DP_SINK_FORCE_SBC=true\n' >> /data/adb/a2dp_sink_yunluo.conf.tmp; mv /data/adb/a2dp_sink_yunluo.conf.tmp /data/adb/a2dp_sink_yunluo.conf; else printf 'A2DP_SINK_FORCE_SBC=true\n' > /data/adb/a2dp_sink_yunluo.conf; fi
        ensure_sink_interop || true
        _cm=$(current_mode); [ "$_cm" = "sink" ] || [ "$_cm" = "concurrent" ] && { echo "Restarting Bluetooth..."; restart_bluetooth "$_cm" || true; }
        show_status
        ;;
    diag|diagnose)
        DURATION=${2:-60}; case "$DURATION" in ''|*[!0-9]*) DURATION=60;; esac; [ "$DURATION" -lt 15 ] && DURATION=15; [ "$DURATION" -gt 300 ] && DURATION=300
        OUT=/data/adb/a2dp_sink_yunluo_diag_$(date '+%Y%m%d_%H%M%S').txt; BASE=${OUT%.txt}
        echo "Capturing ${DURATION}s. Connect/play audio."
        { echo "=== $(date) ==="; show_status; echo; echo "=== interop ==="; cat "$INTEROP_STANDARD_FILE" 2>/dev/null; echo; "$ANDROID_GETPROP" | grep -iE 'bluetooth.profile.(a2dp|avrcp)|a2dp' | sort; } > "$OUT" 2>&1
        /system/bin/logcat -c >/dev/null 2>&1 || true
        i=0; while [ "$i" -lt "$DURATION" ]; do sleep 5; i=$((i+5)); { echo; echo "=== t+${i}s ==="; "$ANDROID_DUMPSYS" bluetooth_manager 2>/dev/null | grep -E 'A2DP Source State|A2DP Sink State|Active peer|Streaming|State|Codec|SEP|Configured|Requested' | head -45; } >> "$OUT" 2>&1; done
        /system/bin/logcat -d -v time > "${BASE}.logcat" 2>/dev/null
        "$ANDROID_DUMPSYS" bluetooth_manager > "${BASE}.bluetooth.txt" 2>&1
        echo "Saved: $OUT ${BASE}.logcat ${BASE}.bluetooth.txt"; show_status
        ;;
    *)
        echo "Usage: $0 [toggle|on|off|concurrent|restart|status|learn [addr]|diag [sec]]"
        echo "  concurrent = EXPERIMENTAL source+sink (stack-supported flag; routing may vary)"
        exit 1 ;;
esac
