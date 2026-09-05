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

$repoRoot = Split-Path -Parent $PSScriptRoot
$moduleRoot = Join-Path $repoRoot 'magisk-modules'

& $AdbPath get-state | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'ADB does not report a connected device.'
}

$rootIdentity = & $AdbPath shell su -c id
if ($LASTEXITCODE -ne 0 -or $rootIdentity -notmatch 'uid=0') {
    throw 'ADB shell did not receive Magisk root. Approve its root request on the phone.'
}

foreach ($moduleId in $moduleIds) {
    $source = Join-Path $moduleRoot $moduleId
    if (-not (Test-Path -LiteralPath (Join-Path $source 'module.prop'))) {
        throw "Missing module source: $source"
    }

    $temporary = "/data/local/tmp/$moduleId"
    Write-Host "Installing $moduleId ..."
    & $AdbPath shell rm -rf $temporary
    & $AdbPath push $source $temporary
    if ($LASTEXITCODE -ne 0) {
        throw "ADB push failed for $moduleId."
    }

    $install = "rm -rf /data/adb/modules/$moduleId && cp -a $temporary /data/adb/modules/$moduleId && chmod -R 0755 /data/adb/modules/$moduleId && rm -rf $temporary"
    & $AdbPath shell su -c $install
    if ($LASTEXITCODE -ne 0) {
        throw "Magisk module installation failed for $moduleId."
    }
}

Write-Host 'Five Pixel USB Magisk actions installed. Reopen Magisk or reboot if they are not yet visible.'
