#!/system/bin/sh

MODDIR=${0%/*}
BB=/data/adb/magisk/busybox
MOUNT_POINT=/mnt/my_drive

is_mounted() {
  "$BB" nsenter -t 1 -m -- /system/bin/grep -qs " $MOUNT_POINT " /proc/mounts
}

if ! is_mounted; then
  echo 'Pixel USB Storage is already unmounted.'
  echo 'It is safe to disconnect the drive.'
  exit 0
fi

echo 'Synchronizing pending writes...'
if ! "$BB" nsenter -t 1 -m -- /system/bin/sh "$MODDIR/unmount_drive.sh"; then
  echo 'ERROR: Unmount failed. A process may still be using the drive.'
  echo 'Run Pixel USB 1 - Status, then Pixel USB 4 - Close Users.'
  exit 1
fi

if is_mounted; then
  echo 'ERROR: The drive is still mounted.'
  exit 1
fi

echo 'Unmount complete. It is now safe to disconnect the Kingston drive.'
