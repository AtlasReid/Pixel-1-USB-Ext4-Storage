#!/system/bin/sh

MODDIR=${0%/*}
BB=/data/adb/magisk/busybox
DRIVE_UUID=abe69538-8061-4cd1-b6d8-f6e8a6132ae6
EXPECTED_MODEL='DataTraveler Duo'
EXPECTED_SECTORS=484306944
MOUNT_POINT=/mnt/my_drive

is_mounted() {
  "$BB" nsenter -t 1 -m -- /system/bin/grep -qs " $MOUNT_POINT " /proc/mounts
}

if is_mounted; then
  echo 'Pixel USB Storage is already mounted.'
  echo 'Location: Internal storage/the_binding'
  exit 0
fi

echo 'Waiting up to 20 seconds for the PIXELBACKUP filesystem...'
device=''
attempt=0
while [ "$attempt" -lt 20 ]; do
  device=$(
    /system/bin/blkid -t UUID="$DRIVE_UUID" 2>/dev/null \
      | "$BB" awk '{ sub(/:$/, "", $1); print $1; exit }'
  )
  if [ -n "$device" ] && [ -b "$device" ]; then
    break
  fi
  attempt=$((attempt + 1))
  sleep 1
done

if [ -z "$device" ] || [ ! -b "$device" ]; then
  echo 'ERROR: The PIXELBACKUP drive did not appear within 20 seconds.'
  exit 1
fi

block_name=${device##*/}
disk_name=${block_name%[0-9]*}
vendor=$(tr -d '[:space:]' < "/sys/class/block/$disk_name/device/vendor")
model=$(sed 's/[[:space:]]*$//' "/sys/class/block/$disk_name/device/model")
removable=$(cat "/sys/class/block/$disk_name/removable")
sectors=$(cat "/sys/class/block/$block_name/size")

if [ "$vendor" != Kingston ] \
  || [ "$model" != "$EXPECTED_MODEL" ] \
  || [ "$removable" != 1 ] \
  || [ "$sectors" != "$EXPECTED_SECTORS" ]; then
  echo "ERROR: Identity check failed for $device; refusing to mount it."
  exit 1
fi

if ! /system/bin/blkid "$device" | /system/bin/grep -q 'TYPE="ext4"'; then
  echo "ERROR: $device is not the expected ext4 filesystem."
  exit 1
fi

echo "Mounting the verified Kingston drive at $device..."
"$BB" nsenter -t 1 -m -- /system/bin/sh "$MODDIR/mount_ext4.sh" "$device"

if ! is_mounted; then
  echo 'ERROR: Mount script returned without creating the drive mount.'
  exit 1
fi

echo 'Mount complete: Internal storage/the_binding'
