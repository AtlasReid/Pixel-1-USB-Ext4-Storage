#!/system/bin/sh

BB=/data/adb/magisk/busybox
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

if ! "$BB" nsenter -t 1 -m -- /system/bin/grep -qs " $MOUNT_POINT " /proc/mounts; then
  echo 'Pixel USB Storage is not mounted; there are no users to close.'
  exit 0
fi

pids=$(get_users)
if [ -z "$pids" ]; then
  echo 'No processes are currently using the USB drive.'
  exit 0
fi

echo 'Closing app processes using the USB drive...'
closed=0
skipped=0

for process_id in $pids; do
  [ -d "/proc/$process_id" ] || continue
  process_uid=$("$BB" awk '/^Uid:/ { print $2; exit }' "/proc/$process_id/status")
  process_name=$(cat "/proc/$process_id/comm" 2>/dev/null)
  process_command=$(tr '\000' ' ' < "/proc/$process_id/cmdline" 2>/dev/null)
  first_word=${process_command%% *}
  package_name=${first_word%%:*}

  echo "PID $process_id, UID $process_uid, $process_name"

  if [ -z "$process_uid" ] || [ "$process_uid" -lt 10000 ]; then
    echo '  skipped: root/core Android process'
    skipped=$((skipped + 1))
    continue
  fi

  if [ -n "$package_name" ] && pm path "$package_name" >/dev/null 2>&1; then
    echo "  force-stopping app $package_name"
    am force-stop "$package_name"
  else
    echo '  sending TERM to app-UID helper process'
    kill -TERM "$process_id" 2>/dev/null || true
  fi
  closed=$((closed + 1))
done

sleep 2
remaining=$(get_users)

if [ -n "$remaining" ]; then
  echo 'Some app processes did not exit; force-closing those app processes...'
  for process_id in $remaining; do
    [ -d "/proc/$process_id" ] || continue
    process_uid=$("$BB" awk '/^Uid:/ { print $2; exit }' "/proc/$process_id/status")
    if [ -n "$process_uid" ] && [ "$process_uid" -ge 10000 ]; then
      kill -KILL "$process_id" 2>/dev/null || true
    fi
  done
  sleep 1
  remaining=$(get_users)
fi

echo "Close requests sent: $closed; protected processes skipped: $skipped"
if [ -n "$remaining" ]; then
  echo "Processes still using the drive: $remaining"
  echo 'Use Pixel USB 1 - Status for details. The utility will not kill core services.'
  exit 1
fi

echo 'No processes are now using the USB drive. You can run Pixel USB 2 - Unmount.'
