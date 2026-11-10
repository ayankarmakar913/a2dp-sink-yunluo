#!/system/bin/sh
ui_print "- A2DP Sink/Source Switcher (Redmi Pad yunluo)"
ui_print "- Target: Redmi Pad (yunluo, 22081283G), HyperOS 2 port, MTK, Android 15"
ui_print "- For Magisk / KernelSU / SukiSU / APatch. Use at your own risk."
ui_print "- Modes: SOURCE=normal BT output, SINK=receive audio."
if [ -d /data/adb/modules_update/a2dp_sink_yunluo ]; then
  ui_print "- Existing config preserved where possible."
else
  touch /data/adb/a2dp_sink_yunluo.disabled 2>/dev/null || true
fi
ui_print "- WebUI/Action available if your manager supports it."
ui_print "- Commands: su -c /data/adb/a2dp-sink-yunluo [toggle|on|off|status|restart|diag]"
