# Troubleshooting

## Android says the drive is unsupported

Expected: stock Android does not present this ext4 filesystem as ordinary removable media. Dismiss the notification and use the Magisk mount action. Do not choose Format.

## Mount says the drive is not connected

- Confirm the powered hub is receiving power.
- Reconnect the stick and wait a few seconds.
- Run `adb shell su -c blkid` and confirm the configured UUID appears.
- If the UUID changed because the drive was reformatted, update both the Android and Windows scripts.

## Identity check failed

This is a safety stop. Compare UUID, vendor, model, removable flag, filesystem type, and sector count with [PIXEL-SETUP.md](PIXEL-SETUP.md). Do not weaken the check merely to make an unknown disk mount.

## Normal Android unmount says busy

Run **Pixel USB 1 - Status**, close the reported application, and retry. **Pixel USB 4 - Close Users** closes app UIDs but intentionally protects Android/root processes. If status shows no users yet unmount still fails, collect deeper evidence:

```powershell
adb push .\tools\diagnose_usb_users.sh /data/local/tmp/
adb shell su -c "chmod 0755 /data/local/tmp/diagnose_usb_users.sh && /data/local/tmp/diagnose_usb_users.sh"
adb shell su -c "cat /data/local/tmp/diagnose_usb_users.out"
```

Use **Pixel USB 5 - Force Unmount** only after ordinary unmount recovery fails.

## WSL cannot see the USB device

- Confirm `usbipd list` reports the device as Shared or Attached.
- Run the one-time `bind` command from an elevated PowerShell.
- Start Ubuntu before attaching.
- Update WSL with `wsl --update` and check the official [USB/WSL instructions](https://learn.microsoft.com/en-us/windows/wsl/connect-usb).

## WSL unmount reports busy

Close Explorer windows rooted at the UNC share, terminals whose current directory is under `/mnt/pixel-usb`, editors, photo viewers, and file-indexing tools. Then run:

```powershell
wsl -d Ubuntu -u root -- fuser -vm /mnt/pixel-usb
```

Close the listed users and retry the safe-eject script. It intentionally does not use a lazy unmount on Windows.

## Files are not immediately visible in Google Photos

The mount action sends a media-scan broadcast, but indexing can still take time. Force-close and reopen Google Photos, then enable backup for the `the_binding` device folder. This setup does not replace `DCIM`.

## Recovery principle

If the phone cannot boot, restore the known-good boot image for the current slot using the procedure in the [rooting repository](https://github.com/AtlasReid/NFS-backed-Pixel-1-via-WSL2). The modules in this repository do not alter the boot image or mount automatically during boot.
