[CmdletBinding()]
param(
    [string]$Distro = 'Ubuntu'
)

$ErrorActionPreference = 'Stop'

$usbId = '0951:173c'
$mountPoint = '/mnt/pixel-usb'
$usbipdPath = 'C:\Program Files\usbipd-win\usbipd.exe'

function ConvertTo-WslDrivePath {
    param([Parameter(Mandatory)][string]$WindowsPath)

    $fullPath = [System.IO.Path]::GetFullPath($WindowsPath)
    if ($fullPath -notmatch '^(?<drive>[A-Za-z]):\\(?<tail>.*)$') {
        throw "The helper must be stored on a Windows drive: $fullPath"
    }

    $drive = $Matches.drive.ToLowerInvariant()
    $tail = $Matches.tail -replace '\\', '/'
    "/mnt/$drive/$tail"
}

if (-not (Test-Path -LiteralPath $usbipdPath)) {
    throw "usbipd-win is not installed at $usbipdPath"
}

$linuxScriptWindowsPath = Join-Path $PSScriptRoot 'linux\safely-unmount-pixel-usb.sh'
if (-not (Test-Path -LiteralPath $linuxScriptWindowsPath)) {
    throw "Missing Linux helper: $linuxScriptWindowsPath"
}

$linuxScriptPath = ConvertTo-WslDrivePath -WindowsPath $linuxScriptWindowsPath

& wsl.exe -d $Distro -u root -- sh $linuxScriptPath $mountPoint
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
