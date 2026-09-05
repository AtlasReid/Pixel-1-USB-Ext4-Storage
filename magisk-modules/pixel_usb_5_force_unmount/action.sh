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

is_mounted_at() {
  "$BB" nsenter -t 1 -m -- /system/bin/grep -qs " $1 " /proc/mounts
}

if ! is_mounted_at "$MOUNT_POINT"; then
  echo 'Pixel USB Storage is already unmounted.'
  echo 'It is safe to disconnect the drive.'
  exit 0
fi

echo 'Step 1/3: closing app processes using the drive...'
pids=$(get_users)
protected=0

for process_id in $pids; do
  [ -d "/proc/$process_id" ] || continue
  process_uid=$("$BB" awk '/^Uid:/ { print $2; exit }' "/proc/$process_id/status")
  process_command=$(tr '\000' ' ' < "/proc/$process_id/cmdline" 2>/dev/null)
  first_word=${process_command%% *}
  package_name=${first_word%%:*}

  if [ -z "$process_uid" ] || [ "$process_uid" -lt 10000 ]; then
    process_name=$(cat "/proc/$process_id/comm" 2>/dev/null)
    echo "  protected PID $process_id, UID $process_uid, $process_name"
    protected=$((protected + 1))
    continue
  fi

  if [ -n "$package_name" ] && pm path "$package_name" >/dev/null 2>&1; then
    echo "  force-stopping app $package_name"
    am force-stop "$package_name"
  else
    echo "  terminating app-UID process $process_id"
    kill -TERM "$process_id" 2>/dev/null || true
  fi
done

sleep 2
remaining=$(get_users)
for process_id in $remaining; do
  [ -d "/proc/$process_id" ] || continue
  process_uid=$("$BB" awk '/^Uid:/ { print $2; exit }' "/proc/$process_id/status")
  if [ -n "$process_uid" ] && [ "$process_uid" -ge 10000 ]; then
    echo "  force-closing remaining app-UID process $process_id"
    kill -KILL "$process_id" 2>/dev/null || true
  fi
done

echo 'Step 2/3: synchronizing pending writes...'
"$BB" nsenter -t 1 -m -- sync

echo 'Step 3/3: unmounting Android mappings and ext4 parent...'
lazy_used=0

for target in \
  /storage/emulated/0/the_binding \
  /mnt/runtime/full/emulated/0/the_binding \
  /mnt/runtime/default/emulated/0/the_binding \
  /mnt/runtime/read/emulated/0/the_binding \
  /mnt/runtime/write/emulated/0/the_binding \
  /mnt/pass_through/0/emulated/0/the_binding
do
  if is_mounted_at "$target"; then
    if ! "$BB" nsenter -t 1 -m -- "$BB" umount "$target"; then
      echo "  normal unmount failed for $target; lazily detaching it"
      "$BB" nsenter -t 1 -m -- "$BB" umount -l "$target" || exit 1
      lazy_used=1
    fi
  fi
done

if is_mounted_at "$MOUNT_POINT"; then
  if ! "$BB" nsenter -t 1 -m -- "$BB" umount "$MOUNT_POINT"; then
    echo '  normal ext4 unmount failed; lazily detaching it'
    "$BB" nsenter -t 1 -m -- "$BB" umount -l "$MOUNT_POINT" || exit 1
    lazy_used=1
  fi
fi

"$BB" nsenter -t 1 -m -- sync

if is_mounted_at "$MOUNT_POINT"; then
  echo 'ERROR: The ext4 parent is still present after forced detachment.'
  exit 1
fi

if [ "$lazy_used" -eq 1 ]; then
  echo 'Force detach complete. Lazy unmount fallback was required.'
  echo 'Wait five seconds before physically disconnecting the drive.'
else
  echo 'Unmount complete without requiring lazy detachment.'
  echo 'It is safe to disconnect the drive.'
fi

if [ "$protected" -gt 0 ]; then
  echo "Note: $protected protected root/core process(es) were not terminated."
fi
