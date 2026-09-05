# Windows and WSL2 access

Windows does not natively mount this ext4 USB flash drive. Microsoft's `wsl --mount` documentation also notes that USB flash drives are not currently supported by that path. The working bridge is [usbipd-win](https://github.com/dorssel/usbipd-win), following Microsoft's [USB devices with WSL](https://learn.microsoft.com/en-us/windows/wsl/connect-usb) workflow.

## Prerequisites

- Windows 11
- WSL2 and an Ubuntu distribution
- `usbipd-win`
- The drive safely unmounted and physically disconnected from the Pixel

Check them:

```powershell
wsl --version
wsl --list --verbose
& "C:\Program Files\usbipd-win\usbipd.exe" --version
& "C:\Program Files\usbipd-win\usbipd.exe" list
```

## One-time USB sharing registration

Connect the Kingston drive directly to the PC. Find its current BUSID with `usbipd list`. In an **Administrator PowerShell**, bind that exact entry once:

```powershell
& "C:\Program Files\usbipd-win\usbipd.exe" bind --busid BUSID
```

Binding persists; the BUSID can change when a different physical port is used. The included scripts discover it from USB ID `0951:173c` and refuse ambiguous matches.

## Mount and open

Double-click `windows-wsl/Mount-PixelUsb.cmd`, or run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows-wsl\Mount-PixelUsb.ps1
```

It starts Ubuntu, attaches the shared USB device to WSL, waits for the expected filesystem UUID, validates the physical identity, mounts it read-write with conservative options, and opens:

```text
\\wsl.localhost\Ubuntu\mnt\pixel-usb\the_binding
```

The Linux location is `/mnt/pixel-usb/the_binding`. Do not accept any Windows format prompt.

## Check status

Double-click `Status-PixelUsb.cmd`, or run its PowerShell counterpart. It reports the usbipd state plus WSL mount and capacity information when attached.

## Safely eject

Close Explorer windows and applications using the UNC path. Double-click `Safely-Eject-PixelUsb.cmd`. It:

1. flushes writes with `sync`;
2. attempts a normal ext4 unmount;
3. refuses to proceed if Linux reports the mount busy;
4. detaches the device from usbipd only after unmount succeeds.

Do not unplug until it prints `Safe to disconnect the Kingston drive from Windows.`

## Manual reference

The verified manual sequence was:

```powershell
& "C:\Program Files\usbipd-win\usbipd.exe" attach --wsl --busid BUSID
wsl -d Ubuntu -u root -- mkdir -p /mnt/pixel-usb
wsl -d Ubuntu -u root -- mount -t ext4 -o rw,nosuid,nodev,noexec,noatime UUID=abe69538-8061-4cd1-b6d8-f6e8a6132ae6 /mnt/pixel-usb
wsl -d Ubuntu -- findmnt /mnt/pixel-usb
wsl -d Ubuntu -- df -h /mnt/pixel-usb
```

To unmount and detach:

```powershell
wsl -d Ubuntu -u root -- sync
wsl -d Ubuntu -u root -- umount /mnt/pixel-usb
& "C:\Program Files\usbipd-win\usbipd.exe" detach --busid BUSID
```
