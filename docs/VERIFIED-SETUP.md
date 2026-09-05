# Verified setup record

This record captures the configuration that was exercised end to end on 2026-09-05. Values are evidence for this particular setup, not universal defaults.

## Pixel

- Google Pixel 1 `sailfish`
- Android 10 build `QP1A.191005.007.A3`
- Bootloader unlocked
- Magisk 30.6 root
- Google A3 kernel; the earlier NFS-enabled kernel had been removed
- Powered USB-C hub
- Wi-Fi ADB used during setup because the phone has one USB-C port

The unlock and rooting history is documented in [AtlasReid/NFS-backed-Pixel-1-via-WSL2](https://github.com/AtlasReid/NFS-backed-Pixel-1-via-WSL2). Its observed Magisk image sizes were 34,301,226 bytes for 30.7 (too large) and 31,814,954 bytes for 30.6 (fits the 33,554,432-byte boot partition).

## Drive

- Kingston DataTraveler Duo
- USB ID `0951:173c`
- Raw device capacity 247,967,252,480 bytes (230.9 GiB)
- First partition starts at sector 2048
- Partition sector count `484306944`
- ext4 label `PIXELBACKUP`
- UUID `abe69538-8061-4cd1-b6d8-f6e8a6132ae6`
- Formatted with ext4 features `^metadata_csum,^64bit`

Android verified the drive at a dynamically assigned block path and mapped its `the_binding` directory to `/storage/emulated/0/the_binding`. All five Magisk actions were installed and exercised. The force-unmount path was tested with a synthetic app-UID process holding a file and successfully closed the user before unmounting.

## Windows and WSL2

- Windows 11
- WSL 2.7.12
- WSL kernel 6.18.3
- Ubuntu distribution on WSL2
- usbipd-win 5.3.0
- Linux mount `/mnt/pixel-usb`
- Windows path `\\wsl.localhost\Ubuntu\mnt\pixel-usb\the_binding`

The drive appeared in Ubuntu as a removable 230.9 GiB Kingston USB disk with the expected UUID. It mounted read-write using `rw,nosuid,nodev,noexec,noatime`; `findmnt` and `df` reported the expected filesystem, and a create/read/delete test under `the_binding` succeeded.

No personal IP addresses, phone serials, passwords, or machine-specific workspace paths are part of this record.
