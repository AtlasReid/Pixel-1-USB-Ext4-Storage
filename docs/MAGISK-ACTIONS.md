# Install and use the Magisk actions

Each directory in `magisk-modules` is a deliberately small Magisk module. Magisk displays its `action.sh` as an **Action** button, giving five separate controls instead of an automatic boot mount or an ambiguous toggle.

## Install

Connect ADB, approve the root prompt on the phone if requested, and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-MagiskActions.ps1 -AdbPath C:\path\to\adb.exe
```

The installer pushes only the five known module directories, sets their permissions, and restarts Magisk. Reboot the phone if the modules do not immediately appear in the Magisk app.

Manual equivalent for one module:

```powershell
adb push .\magisk-modules\pixel_usb_1_status /data/local/tmp/pixel_usb_1_status
adb shell su -c "rm -rf /data/adb/modules/pixel_usb_1_status && cp -a /data/local/tmp/pixel_usb_1_status /data/adb/modules/pixel_usb_1_status && chmod -R 0755 /data/adb/modules/pixel_usb_1_status"
```

## Actions

1. **Pixel USB 1 - Status** shows whether the expected filesystem is connected and mounted, its capacity, the mapped Android views, and detected users.
2. **Pixel USB 2 - Unmount** calls `sync`, normally unmounts the Android mappings and ext4 parent, and refuses to claim success if the parent remains mounted.
3. **Pixel USB 3 - Mount** waits up to 20 seconds for USB enumeration, locates the partition by UUID, verifies its hardware and filesystem identity, mounts ext4 at `/mnt/my_drive`, and exposes `the_binding` at `/storage/emulated/0/the_binding`.
4. **Pixel USB 4 - Close Users** force-stops ordinary app processes using the mapping. It refuses to kill root or core Android UIDs below 10000.
5. **Pixel USB 5 - Force Unmount** combines closing app users, syncing, and unmounting every known view. It uses lazy detach only when normal unmount fails and reports when it did so.

## Normal operating sequence

1. Attach the powered hub and drive.
2. Ignore the Android unsupported-drive/format notification.
3. In Magisk, run **Pixel USB 3 - Mount**.
4. Confirm with **Pixel USB 1 - Status**.
5. Use files under **Internal storage/the_binding**.
6. Close apps displaying files from that folder.
7. Run **Pixel USB 2 - Unmount**.
8. Disconnect only after the success message.

If normal unmount says the target is busy, run **Status**, then **Close Users**, then **Unmount** again. Use **Force Unmount** only as the last resort; after a lazy detach, wait at least five seconds before disconnecting.

## Remove

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Remove-MagiskActions.ps1 -AdbPath C:\path\to\adb.exe
```

Unmount the drive first. Removal deletes only the five exact module IDs used by this repository and does not delete files on the USB drive.
