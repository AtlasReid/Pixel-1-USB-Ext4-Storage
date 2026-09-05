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

$linuxScript = @'
set -eu

uuid=$1
mount_point=$2
expected_model='DataTraveler Duo'
expected_sectors=484306944

device=''
attempt=0
while [ "$attempt" -lt 20 ]; do
  device=$(blkid -U "$uuid" 2>/dev/null || true)
  [ -n "$device" ] && [ -b "$device" ] && break
  attempt=$((attempt + 1))
  sleep 1
done

if [ -z "$device" ] || [ ! -b "$device" ]; then
  echo "ERROR: ext4 filesystem UUID $uuid did not appear in WSL." >&2
  exit 20
fi

partition_name=${device##*/}
disk_name=${partition_name%[0-9]*}
vendor=$(tr -d '[:space:]' < "/sys/class/block/$disk_name/device/vendor")
model=$(sed 's/[[:space:]]*$//' "/sys/class/block/$disk_name/device/model")
removable=$(cat "/sys/class/block/$disk_name/removable")
sectors=$(cat "/sys/class/block/$partition_name/size")
filesystem_type=$(blkid -s TYPE -o value "$device")

if [ "$vendor" != Kingston ] \
  || [ "$model" != "$expected_model" ] \
  || [ "$removable" != 1 ] \
  || [ "$sectors" != "$expected_sectors" ] \
  || [ "$filesystem_type" != ext4 ]; then
  echo "ERROR: identity validation failed for $device; refusing to mount it." >&2
  exit 21
fi

mkdir -p "$mount_point"

if mountpoint -q "$mount_point"; then
  current_source=$(findmnt -rn -o SOURCE --mountpoint "$mount_point")
  current_uuid=$(blkid -s UUID -o value "$current_source" 2>/dev/null || true)
  if [ "$current_uuid" != "$uuid" ]; then
    echo "ERROR: $mount_point already contains a different filesystem." >&2
    exit 22
  fi
else
  mount -t ext4 -o rw,nosuid,nodev,noexec,noatime UUID="$uuid" "$mount_point"
fi

mkdir -p "$mount_point/the_binding"
chmod 0777 "$mount_point/the_binding"

echo 'WSL mount ready:'
findmnt "$mount_point"
df -h "$mount_point"
'@

$linuxScript | & wsl.exe -d $Distro -u root -- sh -s -- $filesystemUuid $mountPoint
if ($LASTEXITCODE -ne 0) {
    throw 'The Kingston drive could not be mounted safely in WSL.'
}

$windowsPath = "\\wsl.localhost\$Distro" + ($mountPoint -replace '/', '\') + '\the_binding'
Write-Host "Windows path: $windowsPath"

if (-not $NoExplorer) {
    Start-Process -FilePath explorer.exe -ArgumentList $windowsPath
}
