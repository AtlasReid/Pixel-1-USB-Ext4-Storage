# Safety and security notes

- Treat every script in this repository as privileged code. Read it before installing it.
- The Android actions run as root and can mount, unmount, relabel, and terminate app processes.
- The Windows mount script runs Linux operations as WSL root. The one-time `usbipd bind` command requires an elevated PowerShell.
- Device identity is checked with a filesystem UUID plus vendor, model, removable flag, partition size, filesystem type, and USB ID where available. These checks reduce—not eliminate—the risk of selecting the wrong disk.
- Never enter a raw `/dev/block/...` or `/dev/sdX` name copied from an earlier connection without rechecking it. Enumeration names can change.
- Keep irreplaceable photos in at least one independent backup. ext4 journaling does not make unsafe removal harmless.
- Never accept Windows' offer to format the ext4 drive.
- Do not expose ADB over Wi-Fi on an untrusted network. Disable it when maintenance is complete with `adb usb` or by turning off USB debugging.
- This repository intentionally contains no device serials, passwords, private keys, boot images, or personal network addresses.

There is no warranty. You are responsible for reviewing commands and maintaining backups.
