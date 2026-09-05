# Pixel 1 USB ext4 storage with Windows/WSL2 access

This repository documents a verified way to use a powered USB-C hub and an ext4 USB drive as app-visible storage on a rooted first-generation Google Pixel (`sailfish`, Android 10). The same drive can be safely detached from Android, attached to Ubuntu under WSL2 with `usbipd-win`, and accessed from Windows through `\\wsl.localhost`.

The reference drive appears inside Android at:

```text
/storage/emulated/0/the_binding
```

It is deliberately a mapped folder, not Android adoptable storage. Android's own guidance says USB devices connected to phones or tablets should not be offered for adoption because accidental disconnection can cause data loss or corruption. The mapping also leaves the phone bootable and usable when the drive is absent.

> [!CAUTION]
> This is a root-level storage modification. A mistake in a device path or an unsafe disconnect can destroy data. Keep backups, validate the filesystem UUID before mounting, and never attach the drive to the Pixel and WSL at the same time.

## Start here

The bootloader unlock and root process is not duplicated in this repository. This phone was prepared using:

- [Unlock the bootloader](https://github.com/AtlasReid/NFS-backed-Pixel-1-via-WSL2#2-unlock-the-bootloader)
- [Root with Magisk while respecting the Pixel 1's 32 MiB boot limit](https://github.com/AtlasReid/NFS-backed-Pixel-1-via-WSL2#4-root-with-magisk-while-respecting-the-32-mib-ceiling)

That earlier repository records the important device-specific result: Magisk 30.7 produced a boot image too large for the 32 MiB partition, while the tested Magisk 30.6 image fit. Do not flash an image for a different build, device, or active slot.

After root is working, follow these documents in order:

1. [Prepare the drive and Pixel](docs/PIXEL-SETUP.md)
2. [Install and use the five Magisk actions](docs/MAGISK-ACTIONS.md)
3. [Read and write the ext4 drive from Windows through WSL2](docs/WINDOWS-WSL2.md)
4. [Use the safe handoff checklist](docs/SAFE-HANDOFF.md)
5. [Troubleshoot common failures](docs/TROUBLESHOOTING.md)

## What is included

```text
Pixel + powered USB-C hub
  ext4 UUID -> /mnt/my_drive
              └── the_binding
                    └── Android sdcardfs view
                          └── /storage/emulated/0/the_binding

Windows + usbipd-win + Ubuntu/WSL2
  same ext4 UUID -> /mnt/pixel-usb/the_binding
                    └── \\wsl.localhost\Ubuntu\mnt\pixel-usb\the_binding
```

- Five separate Magisk Action buttons: status, normal unmount, mount, close users, and force unmount.
- Device identity checks before mounting.
- Windows launchers for status, mount/open, and safe unmount/detach.
- A diagnostic script for difficult Android “target is busy” cases.

## Verified reference setup

| Item | Verified value |
|---|---|
| Phone | Google Pixel 1 `sailfish` |
| Android | `QP1A.191005.007.A3` |
| Root | Magisk 30.6 on Google's original A3 kernel |
| Hub | Powered USB-C hub |
| Drive | Kingston DataTraveler Duo, marketed as 256 GB |
| USB ID | `0951:173c` |
| Partition | 247,965,155,328 bytes (`484306944` 512-byte sectors) |
| Filesystem | ext4, label `PIXELBACKUP` |
| UUID | `abe69538-8061-4cd1-b6d8-f6e8a6132ae6` |
| Windows bridge | usbipd-win 5.3.0, Ubuntu on WSL2 |

See [the complete verification record](docs/VERIFIED-SETUP.md). The scripts intentionally contain these reference-drive identifiers. Change all documented identity constants before using a different drive.

## Upstream credit

The design was inspired by the external-drive method in [master-hax/pixel-backup-gang](https://github.com/master-hax/pixel-backup-gang/blob/master/docs/EXTERNAL_DRIVES.md), inspected at commit [`d91c366eabf44e852e66d88afcebf16a85dc27e4`](https://github.com/master-hax/pixel-backup-gang/commit/d91c366eabf44e852e66d88afcebf16a85dc27e4). The implementation here adds drive identity validation, Magisk UI actions, process diagnostics, safer unmount handling, and a Windows/WSL2 workflow.

See [ATTRIBUTION.md](ATTRIBUTION.md) for the source boundary.

## Scope

This repository does not contain Google factory images, Magisk binaries, or copied upstream scripts. It does not turn the USB drive into Android adoptable storage, automatically replace `DCIM`, or make hot-unplugging safe. The folder exposed to apps is `the_binding`; enable backup for that device folder in Google Photos if desired.
