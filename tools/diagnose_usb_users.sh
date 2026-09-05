#!/system/bin/sh

BB=/data/adb/magisk/busybox
OUTPUT=/data/local/tmp/diagnose_usb_users.out
DONE=/data/local/tmp/diagnose_usb_users.done

rm -f "$OUTPUT" "$DONE"
exec >"$OUTPUT" 2>&1

echo '==== GLOBAL MOUNTS ===='
"$BB" nsenter -t 1 -m -- mount | grep -E '/mnt/my_drive|the_binding'

echo '==== FUSER ALL VIEWS ===='
for usage_point in \
  /mnt/my_drive \
  /storage/emulated/0/the_binding \
  /mnt/runtime/write/emulated/0/the_binding \
  /mnt/runtime/read/emulated/0/the_binding \
  /mnt/runtime/default/emulated/0/the_binding \
  /mnt/runtime/full/emulated/0/the_binding
do
  printf '%s: ' "$usage_point"
  "$BB" nsenter -t 1 -m -- "$BB" fuser -m "$usage_point" 2>/dev/null
  echo
done

echo '==== OPEN FILE DESCRIPTORS ===='
for descriptor in /proc/[0-9]*/fd/*; do
  target=$("$BB" readlink "$descriptor" 2>/dev/null) || continue
  case "$target" in
    *the_binding*|/mnt/my_drive/*)
      process_id=${descriptor#/proc/}
      process_id=${process_id%%/*}
      process_uid=$("$BB" awk '/^Uid:/ { print $2; exit }' "/proc/$process_id/status" 2>/dev/null)
      process_name=$(cat "/proc/$process_id/comm" 2>/dev/null)
      echo "PID=$process_id UID=$process_uid COMM=$process_name FD=$descriptor TARGET=$target"
      ;;
  esac
done

echo '==== MOUNT NAMESPACES WITH BINDING ===='
count=0
for mount_info in /proc/[0-9]*/mountinfo; do
  if grep -q 'the_binding' "$mount_info" 2>/dev/null; then
    process_id=${mount_info#/proc/}
    process_id=${process_id%%/*}
    process_name=$(cat "/proc/$process_id/comm" 2>/dev/null)
    namespace=$("$BB" readlink "/proc/$process_id/ns/mnt" 2>/dev/null)
    echo "PID=$process_id COMM=$process_name NS=$namespace"
    count=$((count + 1))
  fi
done
echo "NAMESPACE_COUNT=$count"
touch "$DONE"
