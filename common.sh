#!/system/bin/sh
# Shared helpers for A2DP Sink/Source Switcher (Redmi Pad yunluo, experimental).
# Markers: MODE_MARKER exists -> SOURCE; CONCURRENT_MARKER exists -> CONCURRENT (experimental); else SINK.

SELF=$0
if command -v readlink >/dev/null 2>&1; then _resolved=$(readlink -f "$SELF" 2>/dev/null) && [ -n "$_resolved" ] && SELF=$_resolved; fi
MODDIR=${MODDIR:-$(dirname "$SELF")}
case "$MODDIR" in /*) ;; *) MODDIR=$(cd "$MODDIR" 2>/dev/null && pwd) || MODDIR=${0%/*} ;; esac

LOG_FILE=${LOG_FILE:-/data/adb/a2dp_sink_yunluo.log}
MODE_MARKER=/data/adb/a2dp_sink_yunluo.disabled
CONCURRENT_MARKER=/data/adb/a2dp_sink_yunluo.concurrent
PATH=/data/adb/ksu/bin:/data/adb/ap/bin:/data/adb/magisk:/debug_ramdisk:$PATH

A2DP_SINK_AAC_BLACKLIST=${A2DP_SINK_AAC_BLACKLIST:-}
A2DP_SINK_FORCE_SBC=${A2DP_SINK_FORCE_SBC:-false}
[ -f /data/adb/a2dp_sink_yunluo.conf ] && . /data/adb/a2dp_sink_yunluo.conf
A2DP_SINK_FORCE_SBC=${A2DP_SINK_FORCE_SBC:-false}
INTEROP_STANDARD_FILE=/data/misc/bluedroid/interop_database_dynamic.conf
LEARNED_INTEROP_FILE=/data/adb/a2dp_sink_yunluo_learned.conf

ANDROID_SVC=/system/bin/svc; ANDROID_AM=/system/bin/am; ANDROID_CMD=/system/bin/cmd
ANDROID_DUMPSYS=/system/bin/dumpsys; ANDROID_GETPROP=/system/bin/getprop

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null; }
resetprop_bin() { command -v resetprop >/dev/null 2>&1 && { command -v resetprop; return 0; }; for p in /data/adb/ksu/bin/resetprop /data/adb/ap/bin/resetprop /data/adb/magisk/resetprop /debug_ramdisk/resetprop; do [ -x "$p" ] && { echo "$p"; return 0; }; done; return 1; }
set_prop() { "$_rp" "$1" "$2" 2>/dev/null || true; }

overlay_list() { "$ANDROID_CMD" overlay list --user 0 2>/dev/null; }
ensure_audio_focus_overlay() {
    [ -x "$ANDROID_CMD" ] || return 1
    _o=$("$ANDROID_CMD" overlay enable --user 0 com.android.shell:A2dpSinkFocus 2>&1) || true
    case "$_o" in *"Failed transaction"*) return 0 ;; esac
    overlay_list | grep -q 'A2dpSinkFocus' || "$ANDROID_CMD" overlay fabricate --target com.android.bluetooth --name A2dpSinkFocus com.android.bluetooth:bool/a2dp_sink_automatically_request_audio_focus 0x12 0xffffffff >> "$LOG_FILE" 2>&1 || true
    "$ANDROID_CMD" overlay enable --user 0 com.android.shell:A2dpSinkFocus >> "$LOG_FILE" 2>&1 || true
    [ "$("$ANDROID_CMD" overlay lookup --user 0 com.android.bluetooth com.android.bluetooth:bool/a2dp_sink_automatically_request_audio_focus 2>/dev/null | tail -1)" = "true" ]
}
disable_audio_focus_overlay() { [ -x "$ANDROID_CMD" ] || return 1; overlay_list | grep -q 'A2dpSinkFocus' || return 0; "$ANDROID_CMD" overlay disable --user 0 com.android.shell:A2dpSinkFocus >> "$LOG_FILE" 2>&1 || true; }

interop_perms() { [ -f "$1" ] || return 0; chown bluetooth:bluetooth "$1" 2>/dev/null || true; chmod 660 "$1" 2>/dev/null || true; [ -x /system/bin/chcon ] && /system/bin/chcon u:object_r:bluetooth_data_file:s0 "$1" 2>/dev/null || true; }
discover_sink_blacklist_addrs() {
    { [ -f /data/misc/bluedroid/bt_config.conf ] && grep -oE '^\[([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}\]' /data/misc/bluedroid/bt_config.conf 2>/dev/null | tr -d '[]'; "$ANDROID_DUMPSYS" bluetooth_manager 2>/dev/null | awk '/A2DP Sink State/{f=1} f && /Active peer:/{print $3; exit}'; } 2>/dev/null | awk 'function lc(s,r,i,c){r=""; for(i=1;i<=length(s);i++){c=substr(s,i,1); if(c>="A"&&c<="Z") c=sprintf("%c",index("ABCDEFGHIJKLMNOPQRSTUVWXYZ",c)+96); r=r c} return r} /^[0-9A-Fa-f][0-9A-Fa-f]:/ {a=lc($1); if(a=="00:00:00:00:00:00") next; n=split(a,p,":"); if(n>=3){p3=p[1]":"p[2]":"p[3]; if(!(p3 in seen)){seen[p3]=1; print p3}}}'
}
_all_sink_interop_addrs() {
    _base=$(echo "$A2DP_SINK_AAC_BLACKLIST" | tr -d ' '); _learned=""; [ -f "$LEARNED_INTEROP_FILE" ] && . "$LEARNED_INTEROP_FILE" 2>/dev/null && _learned=$(echo "$A2DP_SINK_LEARNED" | tr -d ' ')
    _disc=$(discover_sink_blacklist_addrs 2>/dev/null | tr '\n' ',' | sed 's/,$//')
    echo "${_base},${_learned},${_disc}" | awk -F, '{for(i=1;i<=NF;i++){gsub(/^[ \t]+|[ \t]+$/,"",$i); if($i!="" && !seen[$i]++){out=(out==""?$i:out "," $i)}} print out}'
}
_save_learned_interop_addrs() { _all=$(_all_sink_interop_addrs); [ -n "$_all" ] && printf 'A2DP_SINK_LEARNED=%s\n' "$_all" > "$LEARNED_INTEROP_FILE" 2>/dev/null || true; }
ensure_sink_interop() {
    [ -d /data/misc/bluedroid ] || return 1
    _f=$INTEROP_STANDARD_FILE; [ -f "$_f" ] || : > "$_f"
    _list=$(_all_sink_interop_addrs); [ -n "$_list" ] && _save_learned_interop_addrs
    if [ "$A2DP_SINK_FORCE_SBC" = "true" ] && [ -n "$_list" ]; then
        grep -q '^\[INTEROP_DISABLE_AAC_CODEC\]' "$_f" || printf '\n[INTEROP_DISABLE_AAC_CODEC]\n' >> "$_f"
        _old_ifs=$IFS; IFS=,; for _addr in $_list; do [ -n "$_addr" ] || continue; grep -q "^${_addr} = Address_Based$" "$_f" 2>/dev/null || sed -i "/^\[INTEROP_DISABLE_AAC_CODEC\]$/a ${_addr} = Address_Based" "$_f" 2>/dev/null || true; done; IFS=$_old_ifs
        interop_perms "$_f"; return 0
    fi
    interop_perms "$_f"; return 0
}
remove_sink_interop() {
    _list=$(_all_sink_interop_addrs); [ -n "$_list" ] || return 0
    _f=$INTEROP_STANDARD_FILE; [ -f "$_f" ] || return 0
    _old_ifs=$IFS; IFS=,; for _addr in $_list; do [ -n "$_addr" ] || continue; sed -i "/^${_addr} = Address_Based$/d" "$_f" 2>/dev/null || true; done; IFS=$_old_ifs
    interop_perms "$_f"; return 0
}

_apply_common_avrcp() { set_prop bluetooth.profile.avrcp.target.enabled true; set_prop bluetooth.profile.avrcp.controller.enabled false; }
set_sink_props() {
    _rp=$(resetprop_bin) || { log "ERROR: resetprop not found"; return 1; }
    # MTK/HyperOS: set BOTH runtime and persist for BOTH roles explicitly (deleting persist caused wrong role on this ROM)
    set_prop bluetooth.profile.a2dp.source.enabled false
    set_prop bluetooth.profile.a2dp.sink.enabled true
    set_prop persist.bluetooth.a2dp.source.enabled false
    set_prop persist.bluetooth.a2dp.sink.enabled true
    _apply_common_avrcp; ensure_audio_focus_overlay || true; ensure_sink_interop || true
    log "mode=sink src=$($ANDROID_GETPROP bluetooth.profile.a2dp.source.enabled) sink=$($ANDROID_GETPROP bluetooth.profile.a2dp.sink.enabled) psrc=$($ANDROID_GETPROP persist.bluetooth.a2dp.source.enabled) psink=$($ANDROID_GETPROP persist.bluetooth.a2dp.sink.enabled)"
    [ "$($ANDROID_GETPROP bluetooth.profile.a2dp.sink.enabled)" = "true" ] && [ "$($ANDROID_GETPROP bluetooth.profile.a2dp.source.enabled)" = "false" ]
}
set_source_props() {
    _rp=$(resetprop_bin) || return 1
    set_prop bluetooth.profile.a2dp.source.enabled true
    set_prop bluetooth.profile.a2dp.sink.enabled false
    set_prop persist.bluetooth.a2dp.source.enabled true
    set_prop persist.bluetooth.a2dp.sink.enabled false
    _apply_common_avrcp
    log "mode=source src=$($ANDROID_GETPROP bluetooth.profile.a2dp.source.enabled) sink=$($ANDROID_GETPROP bluetooth.profile.a2dp.sink.enabled) psrc=$($ANDROID_GETPROP persist.bluetooth.a2dp.source.enabled) psink=$($ANDROID_GETPROP persist.bluetooth.a2dp.sink.enabled)"
    [ "$($ANDROID_GETPROP bluetooth.profile.a2dp.source.enabled)" = "true" ] && [ "$($ANDROID_GETPROP bluetooth.profile.a2dp.sink.enabled)" = "false" ]
}
set_concurrent_props() {
    _rp=$(resetprop_bin) || return 1
    set_prop bluetooth.profile.a2dp.source.enabled true
    set_prop bluetooth.profile.a2dp.sink.enabled true
    set_prop persist.bluetooth.a2dp.source.enabled true
    set_prop persist.bluetooth.a2dp.sink.enabled true
    _apply_common_avrcp; ensure_audio_focus_overlay || true; ensure_sink_interop || true
    log "mode=concurrent(experimental) src=$($ANDROID_GETPROP bluetooth.profile.a2dp.source.enabled) sink=$($ANDROID_GETPROP bluetooth.profile.a2dp.sink.enabled)"
    [ "$($ANDROID_GETPROP bluetooth.profile.a2dp.source.enabled)" = "true" ] && [ "$($ANDROID_GETPROP bluetooth.profile.a2dp.sink.enabled)" = "true" ]
}

bt_service_cmd() {
    _out=$("$ANDROID_CMD" bluetooth_manager "$1" 2>&1); echo "$_out" >> "$LOG_FILE"
    echo "$_out" | grep -qi 'Success\|enabled\|disabled' && return 0
    _out=$("$ANDROID_SVC" bluetooth "$1" 2>&1); echo "$_out" >> "$LOG_FILE"
    echo "$_out" | grep -q 'Success'
}
force_stop_bluetooth() { "$ANDROID_AM" force-stop com.android.bluetooth >> "$LOG_FILE" 2>&1 || true; "$ANDROID_AM" force-stop com.xiaomi.bluetooth >> "$LOG_FILE" 2>&1 || true; killall com.android.bluetooth com.xiaomi.bluetooth >> "$LOG_FILE" 2>&1 || true; }
sink_state_is() { "$ANDROID_DUMPSYS" bluetooth_manager 2>/dev/null | grep -qi "A2DP Sink State: $1"; }
source_state_is() { "$ANDROID_DUMPSYS" bluetooth_manager 2>/dev/null | grep -qi "A2DP Source State: $1"; }
current_mode() {
    [ -f "$MODE_MARKER" ] && { echo source; return; }
    [ -f "$CONCURRENT_MARKER" ] && { echo concurrent; return; }
    [ "$($ANDROID_GETPROP bluetooth.profile.a2dp.sink.enabled)" = "true" ] && [ "$($ANDROID_GETPROP bluetooth.profile.a2dp.source.enabled)" = "true" ] && { echo concurrent; return; }
    [ "$($ANDROID_GETPROP bluetooth.profile.a2dp.sink.enabled)" = "true" ] && { echo sink; return; }
    echo source
}
_states_ok() {
    case "$1" in
        sink) sink_state_is Enabled && source_state_is Disabled ;;
        source) source_state_is Enabled && sink_state_is Disabled ;;
        concurrent) sink_state_is Enabled && source_state_is Enabled ;;
        *) return 1 ;;
    esac
}

restart_bluetooth() {
    _mode=${1:-sink}
    case "$_mode" in sink|source|concurrent) ;; enabled) _mode=sink ;; disabled) _mode=source ;; *) return 1 ;; esac
    _rp=$(resetprop_bin) || { log "ERROR: resetprop not found"; return 1; }
    _apply_mode() { case "$_mode" in sink) set_sink_props ;; source) set_source_props ;; concurrent) set_concurrent_props ;; esac; }
    _attempt=1
    while [ "$_attempt" -le 4 ]; do
        log "restarting BT for $_mode (attempt $_attempt)"
        _apply_mode >/dev/null 2>&1 || true
        bt_service_cmd disable || true; sleep 4
        force_stop_bluetooth || true; sleep 2
        _apply_mode >/dev/null 2>&1 || true
        bt_service_cmd enable || true
        sleep 4; _apply_mode >/dev/null 2>&1 || true
        sleep 4; _apply_mode >/dev/null 2>&1 || true
        sleep 4; _apply_mode >/dev/null 2>&1 || true
        _i=0; while [ "$_i" -lt 45 ]; do
            if _states_ok "$_mode"; then sleep 2; _states_ok "$_mode" && { log "BT states OK for $_mode"; return 0; }; fi
            _apply_mode >/dev/null 2>&1 || true
            sleep 1; _i=$((_i+1))
        done
        log "WARNING: states not OK for $_mode after attempt $_attempt"
        _attempt=$((_attempt+1))
    done
    log "final corrective restart for $_mode"
    _apply_mode >/dev/null 2>&1 || true; bt_service_cmd disable || true; sleep 5; force_stop_bluetooth || true; sleep 2
    _apply_mode >/dev/null 2>&1 || true; bt_service_cmd enable || true
    _i=0; while [ "$_i" -lt 35 ]; do _apply_mode >/dev/null 2>&1 || true; _states_ok "$_mode" && return 0; sleep 2; _i=$((_i+2)); done
    _states_ok "$_mode"
}

show_status() {
    _mode=$(current_mode)
    echo "=== A2DP mode status (yunluo/experimental) ==="
    case "$_mode" in sink) echo "mode:                      SINK (tablet receives audio)" ;; source) echo "mode:                      SOURCE (normal Bluetooth output)" ;; concurrent) echo "mode:                      CONCURRENT (source+sink, EXPERIMENTAL - may not route on this ROM)" ;; esac
    echo "sink codecs (stack):       SBC, AAC observed; SBC forcing=$A2DP_SINK_FORCE_SBC"
    echo "source property:           $($ANDROID_GETPROP bluetooth.profile.a2dp.source.enabled)"
    echo "sink property:             $($ANDROID_GETPROP bluetooth.profile.a2dp.sink.enabled)"
    _peer=$("$ANDROID_DUMPSYS" bluetooth_manager 2>/dev/null | awk '/A2DP Sink State/{f=1} f&&/Active peer:/{print $3; exit}')
    case "$_peer" in ""|null|00:00:00:00:00:00) _peer=none ;; esac
    echo "sink active peer:          $_peer"
    echo; "$ANDROID_DUMPSYS" bluetooth_manager 2>/dev/null | grep -E 'A2DP Source State|A2DP Sink State|SDP A2DP'
}
