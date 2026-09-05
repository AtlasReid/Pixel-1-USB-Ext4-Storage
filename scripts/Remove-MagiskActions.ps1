[CmdletBinding()]
param(
    [string]$AdbPath = 'adb.exe'
)

$ErrorActionPreference = 'Stop'

$moduleIds = @(
    'pixel_usb_1_status',
    'pixel_usb_2_unmount',
    'pixel_usb_3_mount',
    'pixel_usb_4_close_users',
    'pixel_usb_5_force_unmount'
)

& $AdbPath get-state | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'ADB does not report a connected device.'
}

$mounted = & $AdbPath shell su -c 'nsenter -t 1 -m -- grep -qs " /mnt/my_drive " /proc/mounts; echo $?'
if (($mounted | Select-Object -Last 1).Trim() -eq '0') {
    throw 'The USB drive is mounted on the Pixel. Unmount it before removing the controls.'
}

foreach ($moduleId in $moduleIds) {
    Write-Host "Removing $moduleId ..."
    & $AdbPath shell su -c "rm -rf /data/adb/modules/$moduleId /data/adb/modules_update/$moduleId /data/local/tmp/$moduleId"
    if ($LASTEXITCODE -ne 0) {
        throw "Removal failed for $moduleId."
    }
}

Write-Host 'Pixel USB Magisk actions removed. Reopen Magisk or reboot to refresh its module list.'
