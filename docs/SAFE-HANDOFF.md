# Safe handoff between Pixel and Windows

The drive has one owner at a time. A host must fully unmount and release it before it is moved to the other host.

## Pixel to Windows

1. Close Photos, file managers, camera apps, and anything viewing `the_binding`.
2. Run **Pixel USB 1 - Status**.
3. Run **Pixel USB 2 - Unmount**.
4. If busy, run **Pixel USB 4 - Close Users**, then retry **Unmount**.
5. Use **Pixel USB 5 - Force Unmount** only if normal recovery fails.
6. Wait for the explicit safe-to-disconnect message, then unplug the drive/hub.
7. Connect the drive to Windows and run `Mount-PixelUsb.cmd`.

## Windows to Pixel

1. Close every Explorer window and application using `\\wsl.localhost\Ubuntu\mnt\pixel-usb`.
2. Run `Safely-Eject-PixelUsb.cmd`.
3. If it reports busy, use its `fuser` output to close the named program and retry.
4. Wait for the explicit safe-to-disconnect message.
5. Move the drive to the powered Pixel hub.
6. Run **Pixel USB 3 - Mount**, then **Pixel USB 1 - Status**.

## Never do these

- Never hot-unplug while mounted, even if no file copy is visible.
- Never mount the filesystem on both hosts at once.
- Never use force/lazy unmount as routine eject.
- Never let Windows or Android format the ext4 drive in response to an unsupported-filesystem prompt.
- Never assume `/dev/sdX1` or `/dev/block/sdg1` still identifies the same device after reconnecting it.
