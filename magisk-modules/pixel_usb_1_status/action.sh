#!/system/bin/sh

BB=/data/adb/magisk/busybox
DRIVE_UUID=abe69538-8061-4cd1-b6d8-f6e8a6132ae6
MOUNT_POINT=/mnt/my_drive

get_users() {
  for usage_point in \
    /mnt/my_drive \
    /storage/emulated/0/the_binding \
    /mnt/runtime/write/emulated/0/the_binding \
    /mnt/runtime/read/emulated/0/the_binding \
    /mnt/runtime/default/emulated/0/the_binding \
    /mnt/runtime/full/emulated/0/the_binding
  do
    "$BB" nsenter -t 1 -m -- "$BB" fuser -m "$usage_point" 2>/dev/null
  done \
    | "$BB" tr ' ' '\n' \
    | "$BB" grep -E '^[0-9][0-9]*$' \
    | "$BB" sort -nu
}

device=$(
  /system/bin/blkid -t UUID="$DRIVE_UUID" 2>/dev/null \
    | "$BB" awk '{ sub(/:$/, "", $1); print $1; exit }'
)

echo 'Pixel USB Storage status'
echo '------------------------'

if [ -n "$device" ] && [ -b "$device" ]; then
  echo "Drive: connected at $device"
  /system/bin/blkid "$device"
else
  echo 'Drive: not connected'
fi

if "$BB" nsenter -t 1 -m -- /system/bin/grep -qs " $MOUNT_POINT " /proc/mounts; then
  echo 'Mount: active at Internal storage/the_binding'
  "$BB" nsenter -t 1 -m -- /system/bin/df -h "$MOUNT_POINT" | "$BB" tail -n 1
  mapped_views=$("$BB" nsenter -t 1 -m -- grep -c 'the_binding' /proc/mounts)
  echo "Mapped views: $mapped_views"
  pids=$(get_users)
  if [ -z "$pids" ]; then
    echo 'Users: none detected'
  else
    echo 'Processes using the drive:'
    for process_id in $pids; do
      [ -d "/proc/$process_id" ] || continue
      process_uid=$("$BB" awk '/^Uid:/ { print $2; exit }' "/proc/$process_id/status")
      process_name=$(cat "/proc/$process_id/comm" 2>/dev/null)
      process_command=$(tr '\000' ' ' < "/proc/$process_id/cmdline" 2>/dev/null)
      echo "  PID $process_id, UID $process_uid, $process_name, $process_command"
    done
  fi
else
  echo 'Mount: inactive; safe to disconnect'
fi
