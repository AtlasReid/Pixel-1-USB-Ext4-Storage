# Attribution and source boundary

## Root and bootloader preparation

The tested Pixel was unlocked and rooted using the procedure recorded in [AtlasReid/NFS-backed-Pixel-1-via-WSL2](https://github.com/AtlasReid/NFS-backed-Pixel-1-via-WSL2):

- [Bootloader unlock](https://github.com/AtlasReid/NFS-backed-Pixel-1-via-WSL2#2-unlock-the-bootloader)
- [Magisk root and the 32 MiB boot-partition limit](https://github.com/AtlasReid/NFS-backed-Pixel-1-via-WSL2#4-root-with-magisk-while-respecting-the-32-mib-ceiling)

This repository links to that work instead of duplicating it.

## External-drive design

The Android storage layout and the `the_binding` convention were inspired by:

- [master-hax/pixel-backup-gang](https://github.com/master-hax/pixel-backup-gang)
- [External Drives guide](https://github.com/master-hax/pixel-backup-gang/blob/master/docs/EXTERNAL_DRIVES.md)
- Revision inspected: [`d91c366eabf44e852e66d88afcebf16a85dc27e4`](https://github.com/master-hax/pixel-backup-gang/commit/d91c366eabf44e852e66d88afcebf16a85dc27e4)

No license file was present in that upstream checkout at the inspected revision. For that reason, this repository does not redistribute its scripts verbatim. The scripts here were written separately around the documented behavior and verified system interfaces.

## Platform documentation

- [Android adoptable storage](https://source.android.com/docs/core/storage/adoptable)
- [Android Debug Bridge](https://developer.android.com/tools/adb)
- [Magisk developer guides](https://topjohnwu.github.io/Magisk/guides.html)
- [Connect USB devices to WSL](https://learn.microsoft.com/en-us/windows/wsl/connect-usb)
- [Mount a Linux disk in WSL 2](https://learn.microsoft.com/en-us/windows/wsl/wsl2-mount-disk)
- [usbipd-win](https://github.com/dorssel/usbipd-win)
