#!/bin/sh

set -eu

uuid=$1
mount_point=$2
expected_model='DataTraveler Duo'
expected_sectors=484306944

device=''
attempt=0
while [ "$attempt" -lt 20 ]; do
  device=$(blkid -U "$uuid" 2>/dev/null || true)
  [ -n "$device" ] && [ -b "$device" ] && break
  attempt=$((attempt + 1))
  sleep 1
done

if [ -z "$device" ] || [ ! -b "$device" ]; then
  echo "ERROR: ext4 filesystem UUID $uuid did not appear in WSL." >&2
  exit 20
fi

partition_name=${device##*/}
disk_name=${partition_name%[0-9]*}
vendor=$(tr -d '[:space:]' < "/sys/class/block/$disk_name/device/vendor")
model=$(sed 's/[[:space:]]*$//' "/sys/class/block/$disk_name/device/model")
removable=$(cat "/sys/class/block/$disk_name/removable")
sectors=$(cat "/sys/class/block/$partition_name/size")
filesystem_type=$(blkid -s TYPE -o value "$device")

if [ "$vendor" != Kingston ] \
  || [ "$model" != "$expected_model" ] \
  || [ "$removable" != 1 ] \
  || [ "$sectors" != "$expected_sectors" ] \
  || [ "$filesystem_type" != ext4 ]; then
  echo "ERROR: identity validation failed for $device; refusing to mount it." >&2
  exit 21
fi

mkdir -p "$mount_point"

if mountpoint -q "$mount_point"; then
  current_source=$(findmnt -rn -o SOURCE --mountpoint "$mount_point")
  current_uuid=$(blkid -s UUID -o value "$current_source" 2>/dev/null || true)
  if [ "$current_uuid" != "$uuid" ]; then
    echo "ERROR: $mount_point already contains a different filesystem." >&2
    exit 22
  fi
else
  mount -t ext4 -o rw,nosuid,nodev,noexec,noatime UUID="$uuid" "$mount_point"
fi

mkdir -p "$mount_point/the_binding"
chmod 0777 "$mount_point/the_binding"

echo 'WSL mount ready:'
findmnt "$mount_point"
df -h "$mount_point"
