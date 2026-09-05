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

$listing = & $usbipdPath list
$line = @($listing | Where-Object { $_ -match [regex]::Escape($usbId) })
if ($line.Count -eq 0) {
    Write-Host 'Kingston: not connected to Windows'
    exit 0
}

Write-Host "Kingston: $($line[0].Trim())"

if ($line[0] -match '\sAttached\s*$') {
    $linuxCommand = 'if mountpoint -q "$1"; then findmnt "$1"; df -h "$1"; else echo "WSL filesystem: not mounted"; fi'
    & wsl.exe -d $Distro -u root -- sh -c $linuxCommand sh $mountPoint
}
