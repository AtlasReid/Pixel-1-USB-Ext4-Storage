# Windows/WSL quick reference

For installation, safety details, and the manual fallback, read [the full Windows/WSL2 guide](../docs/WINDOWS-WSL2.md). These utilities expose the Pixel's ext4-formatted Kingston drive to Windows through WSL2 and Ubuntu.

## Use

1. Safely unmount and disconnect the drive from the Pixel.
2. Connect it to the Windows computer.
3. Double-click `Mount-PixelUsb.cmd`.
4. Work with files in `\\wsl.localhost\Ubuntu\mnt\pixel-usb\the_binding`.
5. Close programs using that location and double-click `Safely-Eject-PixelUsb.cmd`.
6. Wait for the safe-to-disconnect message before unplugging the drive.

The Kingston USB device must be shared with usbipd once from an elevated PowerShell:

```powershell
& "C:\Program Files\usbipd-win\usbipd.exe" bind --busid BUSID
```

The sharing registration persists. USB/IP attachment and the WSL mount do not persist after disconnection or reboot, which is why the mount utility performs both operations each time.

Never accept a Windows prompt to format this drive. Windows does not natively recognize its ext4 filesystem.
