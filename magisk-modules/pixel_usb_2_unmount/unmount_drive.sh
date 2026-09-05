#!/system/bin/sh

set -e

is_mounted_at() {
  /system/bin/grep -qs " $1 " /proc/mounts
}

sync

for target in \
  /storage/emulated/0/the_binding \
  /mnt/runtime/full/emulated/0/the_binding \
  /mnt/runtime/default/emulated/0/the_binding \
  /mnt/runtime/read/emulated/0/the_binding \
  /mnt/runtime/write/emulated/0/the_binding \
  /mnt/pass_through/0/emulated/0/the_binding
do
  if is_mounted_at "$target"; then
    umount "$target"
  fi
done

if is_mounted_at /mnt/my_drive; then
  umount /mnt/my_drive
fi

sync
