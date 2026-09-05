#!/system/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /dev/block/DEVICE_PARTITION" >&2
  exit 2
fi

block_device=$1
raw_mount=/mnt/my_drive
android_mount=/mnt/runtime/write/emulated/0/the_binding

if [ "$(readlink /proc/self/ns/mnt)" != "$(readlink /proc/1/ns/mnt)" ]; then
  echo 'ERROR: mount action must run in Android global mount namespace.' >&2
  exit 3
fi

if [ ! -b "$block_device" ]; then
  echo "ERROR: block device does not exist: $block_device" >&2
  exit 4
fi

if grep -qs " $raw_mount " /proc/mounts; then
  echo "ERROR: $raw_mount is already occupied." >&2
  exit 5
fi

mkdir -p "$raw_mount" "$android_mount"

if ! mount -t ext4 -o rw,nosuid,nodev,noexec,noatime "$block_device" "$raw_mount"; then
  echo 'ERROR: ext4 mount failed.' >&2
  exit 6
fi

cleanup_raw_mount() {
  umount "$raw_mount" 2>/dev/null || true
}
trap cleanup_raw_mount EXIT

mkdir -p "$raw_mount/the_binding"
chmod -R 0777 "$raw_mount/the_binding"
chown -R sdcard_rw:sdcard_rw "$raw_mount/the_binding"
chcon -R u:object_r:media_rw_data_file:s0 "$raw_mount/the_binding"

if ! mount \
  -t sdcardfs \
  -o rw,nosuid,nodev,noexec,noatime,gid=9997 \
  "$raw_mount/the_binding" \
  "$android_mount"; then
  echo 'ERROR: Android storage mapping failed.' >&2
  exit 7
fi

trap - EXIT

am broadcast \
  -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
  -d file:///storage/emulated/0/the_binding/ >/dev/null

echo 'Mount complete: Internal storage/the_binding'
