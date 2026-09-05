# Pixel USB Storage Magisk actions

These five modules provide separate Action buttons in the Magisk app:

1. **Pixel USB 1 - Status** reports connection, mount, capacity, and process-use state.
2. **Pixel USB 2 - Unmount** synchronizes pending writes and safely unmounts the drive.
3. **Pixel USB 3 - Mount** locates and validates the Kingston drive, then mounts it at `/storage/emulated/0/the_binding`.
4. **Pixel USB 4 - Close Users** closes app processes using the drive. It intentionally refuses to kill root or core Android processes.
5. **Pixel USB 5 - Force Unmount** combines Close Users with a full child-mapping and parent-filesystem unmount. If normal unmounting fails, it uses a lazy detach and reports that fallback clearly.

The mount action identifies the filesystem by UUID and validates the USB vendor, model, removable flag, and partition size. Its independently written mount implementation follows the method documented by `master-hax/pixel-backup-gang`; see the repository-level attribution and source links.
