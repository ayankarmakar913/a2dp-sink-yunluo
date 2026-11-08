# A2DP Sink/Source Switcher — Redmi Pad (yunluo) [EXPERIMENTAL]

A Magisk/KernelSU/SukiSU/APatch module that switches the tablet between:
- **SOURCE mode** (normal): tablet sends audio to Bluetooth headphones/speakers.
- **SINK mode** (receiver): tablet receives A2DP audio from a phone/PC/TV and plays it through the tablet.

## BEFORE YOU FLASH — READ THIS

- **EXPERIMENTAL. TARGETED FOR: Redmi Pad (yunluo, 22081283G) on a HyperOS 2 port, MTK, Android 15.** Do **NOT** assume it works on other devices, other Redmi Pad variants, stock ROMs, or different ROM ports without testing and accepting risk.
- **Tested environment:** **Redmi Pad (yunluo, 22081283G)**, **`AP3A.240905.015.A2`** (HyperOS 2 port), **Android 15 (SDK 35)**, MTK Bluetooth stack, rooted with **SukiSU (KernelSU-based)**. Magisk/KernelSU/APatch-compatible layout, but test on your setup.
- **ROM/BT stack specific:** relies on A2DP role properties and Bluetooth stack behavior on this MTK/HyperOS port. The module includes hardening for role-state quirks, but behavior may vary by ROM/port.
- **Root + runtime changes:** modifies Bluetooth profile/persist properties, may touch Bluetooth config/state (troubleshooting), enables an audio-focus overlay (best-effort), and restarts the Bluetooth stack. Pairings/settings may be affected during switches.
- **Codecs (tested):** SBC and AAC sink observed working on the tested setup.
- **Have recovery ready:** know how to disable/remove root modules if Bluetooth/behavior becomes problematic. **Back up important data.**

## ⚠️ WARNING — DO THIS AT YOUR OWN RISK

You are choosing to flash root-level code from the internet onto your device.
- **Do this at your own risk. Don’t blame me.**
- I am not responsible for bootloops, broken Bluetooth, lost pairings, bad audio, weird bugs, corrupted data, dead devices, or any other chaos.
- **This is experimental.** You are the captain now — only proceed if you understand what you’re doing.

## Install & control
1. Download the zip from [**Releases**](../../releases/latest) and install in **SukiSU/KernelSU/Magisk/APatch**. **Reboot recommended.**
2. **WebUI** (if supported): module → **WebUI**.
   - **Toggle Source / Sink**
   - **Restart A2DP Sink** appears **only in SINK mode** — use when reconnecting/switching the source device or if the sink gets stuck
   - *If your manager’s WebUI exec isn’t supported, buttons may not run; use Action or commands below.*
3. **Action button** (if supported): toggles Source/Sink.
4. **Commands (root fallback):**
   ```sh
   su -c /data/adb/a2dp-sink-yunluo status
   su -c /data/adb/a2dp-sink-yunluo toggle     # Source <-> Sink
   su -c /data/adb/a2dp-sink-yunluo on         # SINK (receiver)
   su -c /data/adb/a2dp-sink-yunluo off        # SOURCE (normal BT output)
   su -c /data/adb/a2dp-sink-yunluo restart    # restart BT, keep current mode
   su -c /data/adb/a2dp-sink-yunluo learn [AA:BB:CC:DD:EE:FF]  # troubleshooting for a problematic device
   su -c /data/adb/a2dp-sink-yunluo diag [60]  # capture logs/state
   su -c /data/adb/a2dp-sink-yunluo concurrent # EXPERIMENTAL (not reliable on tested ROM)
   ```

**Switching modes / after connecting:** changing **SOURCE ↔ SINK** (or `restart`) restarts Bluetooth — reconnection may take a moment. After connecting in SINK mode, wait a few seconds for audio to start.

## No sound / can’t connect / troubleshooting
- **Quick fix:** toggle **Bluetooth OFF and ON on both the source device and the tablet**, then reconnect and play.
- **SINK mode (no sound / source won’t connect):** tap **Restart A2DP Sink** in WebUI (SINK mode) or run `su -c /data/adb/a2dp-sink-yunluo restart`, then reconnect. `restart` keeps the current mode and re-verifies/corrects the BT role state.
- **Codec/capability stuck on the source:** **Forget & re-pair** the tablet on the *source* device, reconnect for media audio, and check the source’s codec/audio settings while connected.
- **Problematic device:** `su -c /data/adb/a2dp-sink-yunluo learn [addr]` can help as troubleshooting, then reconnect.
- **Check state/codec (while playing):**
  ```sh
  su -c '/data/adb/a2dp-sink-yunluo status'
  su -c 'dumpsys bluetooth_manager 2>/dev/null | grep -E "A2DP (Source|Sink) State|Active peer|Connected|Streaming|Configured codec|SEP codec" | head -15'
  ```
- **Diagnosis:** `su -c /data/adb/a2dp-sink-yunluo diag 60` (capture while reproducing).

## Known limitations
- **Exclusive modes (not simultaneous source+sink):** live concurrent routing did not work reliably in testing on this ROM — switch modes.
- **Mode switching reconnects Bluetooth** and may take a moment.
- **Experimental / port-specific:** behavior may vary across ROM builds.
- **Media only (not phone calls):** A2DP sink does not route phone call audio/mic via this setup.

## Uninstall / recovery
Disable/remove the module in your root manager and reboot. Or: `su -c /data/adb/a2dp-sink-yunluo off`.

## Repo contents
- Module source (scripts, `webroot/`)
- `LICENSE` — MIT

## License / Disclaimer
MIT. Provided **as-is**, **no warranty**. **Use at your own risk. Don’t blame me.** This is experimental.
