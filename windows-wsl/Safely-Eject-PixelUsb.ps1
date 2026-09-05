[CmdletBinding()]
param(
    [string]$Distro = 'Ubuntu'
)

$ErrorActionPreference = 'Stop'

$usbId = '0951:173c'
$mountPoint = '/mnt/pixel-usb'
$usbipdPath = 'C:\Program Files\usbipd-win\usbipd.exe'

if (-not (Test-Path -LiteralPath $usbipdPath)) {
    throw "usbipd-win is not installed at $usbipdPath"
}

$linuxScript = @'
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
'@

$linuxScript | & wsl.exe -d $Distro -u root -- sh -s -- $mountPoint
if ($LASTEXITCODE -ne 0) {
    throw 'Safe unmount failed. The USB device remains attached; do not unplug it.'
}

$listing = & $usbipdPath list
if ($LASTEXITCODE -ne 0) {
    throw 'usbipd list failed after unmounting.'
}

$lines = @($listing | Where-Object { $_ -match [regex]::Escape($usbId) })
if ($lines.Count -eq 0) {
    Write-Host 'The Kingston is no longer connected to Windows.'
    exit 0
}
if ($lines.Count -ne 1) {
    throw "More than one USB device matched $usbId; refusing to detach automatically."
}
if ($lines[0] -notmatch '^\s*(?<busid>\d+-\d+)\s+0951:173c\s+.*?\s+(?<state>Not shared|Shared|Attached)\s*$') {
    throw "Could not parse the Kingston usbipd entry: $($lines[0])"
}

if ($Matches.state -eq 'Attached') {
    & $usbipdPath detach --busid $Matches.busid
    if ($LASTEXITCODE -ne 0) {
        throw 'The filesystem is unmounted, but usbipd could not detach the USB device.'
    }
}

Write-Host 'Safe to disconnect the Kingston drive from Windows.'
