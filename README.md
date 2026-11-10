# A2DP Sink/Source Switcher — Redmi Pad (yunluo)

A Magisk/KernelSU/SukiSU/APatch module that switches the tablet between:
- **SOURCE mode** (normal): tablet sends audio to Bluetooth headphones/speakers.
- **SINK mode** (receiver): tablet receives A2DP audio from a phone/PC/TV and plays it through the tablet like a normal Bluetooth speaker.

## BEFORE YOU FLASH — READ THIS

- **TARGETED FOR: Redmi Pad (yunluo, 22081283G) on a HyperOS 2 port, MTK, Android 15.** Do **NOT** flash this on other devices or different ROMs unless you know exactly what you are doing and accept the risk.
- **Tested on:** **Redmi Pad (yunluo, 22081283G)**, **`AP3A.240905.015.A2`** (HyperOS 2 port), **Android 15 (SDK 35)**, MTK Bluetooth stack, rooted with **SukiSU (KernelSU-based)**. Magisk/KernelSU/APatch-compatible layout.
- **ROM/BT stack specific:** relies on this device/ROM’s Bluetooth stack behavior (A2DP role properties, service handling). Other ROMs/ports may not work.
- **Root + runtime changes:** modifies Bluetooth profile/persist properties, may touch Bluetooth config/state, enables an audio-focus overlay, and manages the Bluetooth stack when switching modes.
- **Have recovery ready:** know how to disable/remove root modules if Bluetooth/behavior becomes problematic. Back up important data.

## ⚠️ WARNING — DO THIS AT YOUR OWN RISK

You are choosing to flash root-level code from the internet onto your device.
- **Do this at your own risk. Don’t blame me.**
- I am not responsible for bootloops, broken Bluetooth, lost pairings, bad audio, weird bugs, corrupted data, dead devices, thermonuclear incidents, alien invasions, timeline splits, or any other chaos.
- **If you somehow start a nuclear war because of an A2DP sink module, I don’t care — I will laugh at you.**
- You are the captain now. Only proceed if you understand what you’re doing.

## Install & control
1. Download the zip from [**Releases**](../../releases/latest) and install in **SukiSU/KernelSU/Magisk/APatch**. Reboot if needed.
2. **WebUI** (if supported): module → **WebUI**.
   - **Toggle Source / Sink**
   - **Restart A2DP Sink** appears **only in SINK mode** (useful if reconnecting gets stuck)
   - *If your manager’s WebUI exec isn’t supported, the buttons may not run; use the Action button or commands below.*
3. **Action button** (if supported): toggles Source/Sink.
4. **Commands (root fallback):**
   ```sh
   su -c /data/adb/a2dp-sink-yunluo status
   su -c /data/adb/a2dp-sink-yunluo toggle     # Source <-> Sink
   su -c /data/adb/a2dp-sink-yunluo on         # SINK (receiver)
   su -c /data/adb/a2dp-sink-yunluo off        # SOURCE (normal BT output)
   su -c /data/adb/a2dp-sink-yunluo restart    # restart BT, keep current mode
   su -c /data/adb/a2dp-sink-yunluo diag [60]  # capture logs/state
   ```

**SINK mode:** connect a phone/PC/TV to the tablet and play audio — it works like a normal Bluetooth speaker. To switch to a different source device, disconnect the current device and connect the other one.

## No sound / troubleshooting
- **Quick fix:** toggle **Bluetooth OFF and ON on both the source device and the tablet**, then reconnect and play.
- **SINK mode (if a connection gets stuck):** open **WebUI** and tap **Restart A2DP Sink** (SINK mode), then reconnect. Fallback: `su -c /data/adb/a2dp-sink-yunluo restart`.
- **Source-side codec/capability issue:** **Forget & re-pair** the tablet on the source device, reconnect for media audio, and check the source’s audio/codec settings while connected.
- **Check state/codec (while playing):**
  ```sh
  su -c '/data/adb/a2dp-sink-yunluo status'
  su -c 'dumpsys bluetooth_manager 2>/dev/null | grep -E "A2DP (Source|Sink) State|Active peer|Connected|Streaming|Configured codec|SEP codec" | head -15'
  ```
- **Diagnosis:** `su -c /data/adb/a2dp-sink-yunluo diag 60` (capture while reproducing).

## Known limitations
- **Exclusive modes:** SOURCE and SINK are used separately (switch modes). Media audio only (not phone calls).
- **Device/ROM specific:** behavior may vary on different ROMs/ports.

## Uninstall / recovery
Disable/remove the module in your root manager and reboot. Or: `su -c /data/adb/a2dp-sink-yunluo off`.

## Repo contents
- Module source (scripts, `webroot/`)
- `LICENSE` — MIT

## Disclaimer
Provided **as-is**, with **no warranty**. **Use at your own risk. Don’t blame me.** If international diplomacy collapses over a Bluetooth codec negotiation, I will still laugh at you.
