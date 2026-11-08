# A2DP Sink/Source Switcher — Redmi Pad (yunluo) [EXPERIMENTAL]

A Magisk/KernelSU/SukiSU/APatch module that switches the tablet between:
- **SOURCE mode** (normal): tablet sends audio to Bluetooth headphones/speakers.
- **SINK mode** (receiver): tablet receives A2DP audio from a phone/PC/TV and plays it through the tablet.

## BEFORE YOU FLASH — READ THIS

- **EXPERIMENTAL. TARGETED FOR: Redmi Pad (yunluo, 22081283G) on a HyperOS 2 port (Xiaomi Pad 5 base), MTK, Android 15.** Do **NOT** assume it works on other devices, other Redmi Pad variants, stock ROMs, or different HyperOS ports without testing and accepting risk.
- **Tested environment:** **Redmi Pad (yunluo, 22081283G)**, **`AP3A.240905.015.A2`** (HyperOS 2 port / Pad 5 base), **Android 15 (SDK 35)**, MTK Bluetooth stack, rooted with **SukiSU (KernelSU-based, ksud 4.3.0-r1)**. Magisk/KernelSU/APatch-compatible layout, but test on your setup.
- **ROM/BT stack specific:** relies on A2DP role properties/persist props and Bluetooth stack behavior on this MTK/HyperOS port. The module includes hardening for MTK role-state quirks, but behavior may vary by port/ROM.
- **Root + runtime changes:** modifies Bluetooth profile/persist properties, may touch Bluetooth interop config (troubleshooting), enables an audio-focus overlay (best-effort), and restarts the Bluetooth stack. Pairings/settings may be affected during switches.
- **Codecs (tested): SBC and AAC sink observed working** (AAC negotiated/streamed). **SBC is NOT forced by default.** LDAC/aptX/aptX HD *sink* not confirmed/exposed on this ROM. (Use `learn` only as SBC-forcing troubleshooting if a device misbehaves.)
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
   su -c /data/adb/a2dp-sink-yunluo restart    # restart BT, keep current mode (auto-corrects role state)
   su -c /data/adb/a2dp-sink-yunluo learn [AA:BB:CC:DD:EE:FF]  # troubleshooting: force SBC for device
   su -c /data/adb/a2dp-sink-yunluo diag [60]  # capture logs/state
   su -c /data/adb/a2dp-sink-yunluo concurrent # EXPERIMENTAL (not reliable on tested ROM)
   ```

**Switching modes / after connecting:** changing **SOURCE ↔ SINK** (or `restart`) restarts Bluetooth — reconnection may take a moment. After connecting in SINK mode, wait a few seconds for audio to start (on the tested setup it started quickly).

## No sound / can’t connect / troubleshooting
- **Quick fix:** toggle **Bluetooth OFF and ON on both the source device and the tablet**, then reconnect and play.
- **SINK mode (no sound / source won’t connect):** tap **Restart A2DP Sink** in WebUI (SINK mode) or run `su -c /data/adb/a2dp-sink-yunluo restart`, then reconnect. `restart` keeps the current mode and re-verifies/corrects the BT role state.
- **Codec/capability stuck on the source (e.g., SBC only / “HD Audio” unavailable):** **Forget & re-pair** the tablet on the *source* device, reconnect for media audio, and check the source’s codec/HD-audio settings while connected. (The tablet advertises SBC/AAC on the tested setup; SBC is not forced by default.)
- **Problematic device (troubleshooting):** `su -c /data/adb/a2dp-sink-yunluo learn [addr]` forces SBC for learned/known sources, then reconnect.
- **Check state/codec (while playing):**
  ```sh
  su -c '/data/adb/a2dp-sink-yunluo status'
  su -c 'dumpsys bluetooth_manager 2>/dev/null | grep -E "A2DP (Source|Sink) State|Active peer|Connected|Streaming|Configured codec|SEP codec" | head -15'
  ```
- **Diagnosis:** `su -c /data/adb/a2dp-sink-yunluo diag 60` (capture while reproducing).

## Known limitations
- **Exclusive modes (not simultaneous source+sink):** the stack flag exists, but **live concurrent routing did not work reliably** in testing on this ROM — switch modes.
- **Mode switching reconnects Bluetooth** and may take a moment.
- **Experimental / port-specific:** HyperOS 2 port (Pad 5 base) behavior may vary across builds.
- **Media only (not phone calls):** A2DP sink does not route phone call audio/mic via this setup.

## Uninstall / recovery
Disable/remove the module in your root manager and reboot. Or: `su -c /data/adb/a2dp-sink-yunluo off`.

## Repo contents
- Module source (scripts, `webroot/`)
- `LICENSE` — MIT

## License / Disclaimer
MIT. Provided **as-is**, **no warranty**. **Use at your own risk. Don’t blame me.** This is experimental.
