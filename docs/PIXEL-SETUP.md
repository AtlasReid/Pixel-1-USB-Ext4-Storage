# Prepare the drive and Pixel

## 1. Root the matching Pixel build

This setup assumes a Pixel 1 (`sailfish`) already rooted with Magisk. Use the separate, tested instructions for [bootloader unlock](https://github.com/AtlasReid/NFS-backed-Pixel-1-via-WSL2#2-unlock-the-bootloader) and [Magisk root under the 32 MiB boot limit](https://github.com/AtlasReid/NFS-backed-Pixel-1-via-WSL2#4-root-with-magisk-while-respecting-the-32-mib-ceiling).

The verified phone runs `QP1A.191005.007.A3` with Magisk 30.6 and Google's original kernel. Back up both boot partitions before changing boot images.

## 2. Use a powered hub

The Pixel has one USB-C port. During normal storage use, connect a powered USB-C OTG hub, then connect the USB stick to the hub. External power reduces the chance that the phone browns out or disconnects the storage under load.

During setup, Wi-Fi ADB leaves the USB-C port available for the hub:

```powershell
adb tcpip 5555
adb connect PIXEL_IP:5555
adb devices
```

Use this only on a trusted private network. The address can change unless reserved in the router.

## 3. Create the ext4 filesystem

Formatting is destructive. Identify the whole USB disk by model and capacity in Linux, unmount any existing partitions, then create one Linux partition and format that partition. The reference filesystem was created as:

```sh
sudo mkfs.ext4 \
  -L PIXELBACKUP \
  -O ^metadata_csum,^64bit \
  /dev/sdX1
```

Replace `/dev/sdX1` only after checking `lsblk -o NAME,PATH,SIZE,MODEL,TRAN,RM,FSTYPE,LABEL,UUID,MOUNTPOINTS`. The feature flags match the compatibility approach in the upstream [External Drives guide](https://github.com/master-hax/pixel-backup-gang/blob/master/docs/EXTERNAL_DRIVES.md).

Create the content directory:

```sh
sudo mkdir -p /mnt/pixel-usb
sudo mount /dev/sdX1 /mnt/pixel-usb
sudo mkdir -p /mnt/pixel-usb/the_binding
sudo chmod 0777 /mnt/pixel-usb/the_binding
sudo sync
sudo umount /mnt/pixel-usb
```

## 4. Record immutable identity values

Do not rely on `/dev/sdg1`; the block-device name changes. Record these values:

```sh
sudo blkid /dev/sdX1
cat /sys/class/block/sdX/device/vendor
cat /sys/class/block/sdX/device/model
cat /sys/class/block/sdX/removable
cat /sys/class/block/sdX1/size
```

Update the constants in all of these files if your drive differs:

- `magisk-modules/pixel_usb_1_status/action.sh`: `DRIVE_UUID`
- `magisk-modules/pixel_usb_3_mount/action.sh`: `DRIVE_UUID`, `EXPECTED_MODEL`, and `EXPECTED_SECTORS`; also update the vendor comparison if needed
- `windows-wsl/Mount-PixelUsb.ps1`: `$usbId`, `$filesystemUuid`, `expected_model`, `expected_sectors`, and vendor comparison
- `windows-wsl/Safely-Eject-PixelUsb.ps1`: `$usbId`
- `windows-wsl/Status-PixelUsb.ps1`: `$usbId`

The checked-in values identify only the verified reference Kingston drive.

## 5. Install the controls

Continue with [MAGISK-ACTIONS.md](MAGISK-ACTIONS.md). Ignore Android's unsupported-drive notification; do not let Android or Windows reformat the ext4 drive.
