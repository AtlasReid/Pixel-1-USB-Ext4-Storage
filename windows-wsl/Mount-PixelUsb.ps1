[CmdletBinding()]
param(
    [string]$Distro = 'Ubuntu',
    [switch]$NoExplorer
)

$ErrorActionPreference = 'Stop'

$usbId = '0951:173c'
$filesystemUuid = 'abe69538-8061-4cd1-b6d8-f6e8a6132ae6'
$mountPoint = '/mnt/pixel-usb'
$usbipdPath = 'C:\Program Files\usbipd-win\usbipd.exe'

function Get-PixelUsbDevice {
    if (-not (Test-Path -LiteralPath $usbipdPath)) {
        throw "usbipd-win is not installed at $usbipdPath"
    }

    $listing = & $usbipdPath list
    if ($LASTEXITCODE -ne 0) {
        throw 'usbipd list failed.'
    }

    $lines = @($listing | Where-Object { $_ -match [regex]::Escape($usbId) })
    if ($lines.Count -eq 0) {
        throw 'The Kingston DataTraveler Duo is not connected to Windows.'
    }
    if ($lines.Count -ne 1) {
        throw "More than one USB device matched $usbId; refusing to choose automatically."
    }

    if ($lines[0] -notmatch '^\s*(?<busid>\d+-\d+)\s+0951:173c\s+.*?\s+(?<state>Not shared|Shared|Attached)\s*$') {
        throw "Could not parse the Kingston usbipd entry: $($lines[0])"
    }

    [pscustomobject]@{
        BusId = $Matches.busid
        State = $Matches.state
        Line  = $lines[0]
    }
}

$device = Get-PixelUsbDevice
Write-Host "Kingston detected at BUSID $($device.BusId), state: $($device.State)"

if ($device.State -eq 'Not shared') {
    throw "The Kingston is not shared. In Administrator PowerShell run: & `"$usbipdPath`" bind --busid $($device.BusId)"
}

# Start the user's WSL distribution before requesting USB/IP attachment.
& wsl.exe -d $Distro -- true
if ($LASTEXITCODE -ne 0) {
    throw "Could not start WSL distribution '$Distro'."
}

if ($device.State -ne 'Attached') {
    & $usbipdPath attach --wsl --busid $device.BusId
    if ($LASTEXITCODE -ne 0) {
        throw 'usbipd could not attach the Kingston drive to WSL.'
    }
}

$linuxScriptWindowsPath = Join-Path $PSScriptRoot 'linux\mount-pixel-usb.sh'
if (-not (Test-Path -LiteralPath $linuxScriptWindowsPath)) {
    throw "Missing Linux helper: $linuxScriptWindowsPath"
}

$linuxScriptPath = (& wsl.exe -d $Distro -- wslpath -a $linuxScriptWindowsPath).Trim()
if ($LASTEXITCODE -ne 0 -or -not $linuxScriptPath) {
    throw 'Could not translate the Linux helper path for WSL.'
}

& wsl.exe -d $Distro -u root -- sh $linuxScriptPath $filesystemUuid $mountPoint
if ($LASTEXITCODE -ne 0) {
    throw 'The Kingston drive could not be mounted safely in WSL.'
}

$windowsPath = "\\wsl.localhost\$Distro" + ($mountPoint -replace '/', '\') + '\the_binding'
Write-Host "Windows path: $windowsPath"

if (-not $NoExplorer) {
    Start-Process -FilePath explorer.exe -ArgumentList $windowsPath
}
