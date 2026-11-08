# A2DP Sink/Source Switcher — Redmi Pad (yunluo) [EXPERIMENTAL]

A Magisk/KernelSU/SukiSU/APatch module that switches the tablet between:
- **SOURCE mode** (normal): tablet sends audio to Bluetooth headphones/speakers.
- **SINK mode** (receiver): tablet receives A2DP audio from a phone/PC/TV and plays it through the tablet.

## BEFORE YOU FLASH — READ THIS

- **EXPERIMENTAL. THIS MODULE IS TARGETED FOR: Redmi Pad (yunluo, 22081283G) on a HyperOS 2 port (Xiaomi Pad 5 base), MTK, Android 15.** Do **NOT** assume it works on other devices, other Redmi Pad variants, stock ROMs, or different HyperOS ports without testing and accepting risk.
- **Tested environment:** **Redmi Pad (yunluo, 22081283G)**, **`AP3A.240905.015.A2`** (HyperOS 2 port / Pad 5 base), **Android 15 (SDK 35)**, MTK Bluetooth stack, rooted with **SukiSU (KernelSU-based, ksud 4.3.0-r1)**. Magisk/KernelSU/APatch-compatible layout, but test on your setup.
- **ROM/BT stack specific:** relies on A2DP role properties and Bluetooth stack behavior on this MTK/HyperOS port. Other ROMs/ports may behave differently.
- **Root + system-level changes:** modifies Bluetooth profile/persist properties, can touch Bluetooth interop config, enables an overlay (best-effort), and restarts the Bluetooth stack. Pairings/settings may be affected during switches.
- **SBC & AAC:** on this tested setup, **SBC and AAC sink were observed working** (AAC negotiated/streamed). **SBC is NOT forced by default.** LDAC/aptX/aptX HD sink not confirmed/exposed here.
- **Concurrent sink+source:** stack flag exists, but **live concurrent routing did not work in testing** on this ROM — module uses **exclusive** switching (sink **or** source).
- **Have recovery ready:** know how to disable/remove root modules (safe mode / module removal) if Bluetooth or behavior becomes problematic. **Back up important data.**

## ⚠️ WARNING — DO THIS AT YOUR OWN RISK

You are choosing to flash root-level code from the internet onto your device.

- **Do this at your own risk. Don’t blame me.**
- I am not responsible for bootloops, broken Bluetooth, lost pairings, bad audio, weird bugs, corrupted data, dead devices, or any other chaos.
- **This is experimental.** Only proceed if you understand what you’re doing.

## Install & control (easy)
1. Download the flashable zip from [**Releases**](../../releases) (if published) and install in **SukiSU/KernelSU/Magisk/APatch**. **Reboot recommended.**
2. **WebUI** (if your manager supports it): *Toggle Source/Sink* and *Restart A2DP Sink* (shown only in **SINK** mode).
3. **Action button** (if supported): toggles mode.
4. **Commands (root):**
   ```sh
   su -c /data/adb/a2dp-sink-yunluo status
   su -c /data/adb/a2dp-sink-yunluo toggle
   su -c /data/adb/a2dp-sink-yunluo on        # SINK (receive audio)
   su -c /data/adb/a2dp-sink-yunluo off       # SOURCE (normal BT output)
   su -c /data/adb/a2dp-sink-yunluo restart   # restart BT, keep current mode
   su -c /data/adb/a2dp-sink-yunluo learn [AA:BB:CC:DD:EE:FF]  # troubleshooting: force SBC for device
   su -c /data/adb/a2dp-sink-yunluo diag 60
   su -c /data/adb/a2dp-sink-yunluo concurrent  # EXPERIMENTAL (not reliable on tested ROM)
   ```

**After connecting in SINK mode:** audio may start after a short moment (on this tested setup it started quickly).

## No sound / can’t connect / troubleshooting
- **Quick fix:** toggle **Bluetooth OFF and ON on both the source and the tablet**, then reconnect.
- **Still no sound / source can’t connect in SINK:** run `su -c /data/adb/a2dp-sink-yunluo restart`, then reconnect.
- **Problematic device:** `su -c /data/adb/a2dp-sink-yunluo learn [addr]` (forces SBC for troubleshooting), then reconnect.
- **Check state/codec (while playing):**
  ```sh
  su -c '/data/adb/a2dp-sink-yunluo status'
  su -c 'dumpsys bluetooth_manager 2>/dev/null | grep -E "Configured codec|SEP codec|Streaming|A2DP Source State|A2DP Sink State" | head -12'
  ```
- If mode switching gets stuck on this ROM, `restart` re-applies the correct role props and verifies BT state.

## Known limitations
- **Exclusive mode:** true simultaneous source+sink did **not** work reliably in testing here (despite stack flag). Switch modes.
- **Experimental / port-specific:** HyperOS 2 port behavior may vary.
- **Not for phone calls:** A2DP sink is media-only; it does not route phone call audio/mic via this setup.

## Uninstall / recovery
Disable/remove the module in your root manager and reboot. Or: `su -c /data/adb/a2dp-sink-yunluo off`.

## Repo contents
- `module.prop`, scripts, `webroot/` — module source
- `LICENSE` — MIT

## License
MIT. Provided **as-is**, **no warranty**. Use at your own risk.
