#!/bin/sh

set -u

mount_point=$1

if mountpoint -q "$mount_point"; then
  echo 'Synchronizing pending writes...'
  sync
  if ! umount "$mount_point"; then
    echo "ERROR: $mount_point is busy. Close Explorer and applications using it." >&2
    echo 'Processes reported by Linux:' >&2
    fuser -vm "$mount_point" >&2 || true
    exit 30
  fi
  sync
  echo 'The ext4 filesystem is unmounted.'
else
  echo 'The ext4 filesystem is already unmounted.'
fi
