param(
    [string]$Image = "build/firmware.out",
    [string]$Device = "MSPM0G3507",
    [string]$JLinkExe = "C:/Program Files/SEGGER/JLink_V930a/JLink.exe",
    [int]$SpeedKHz = 4000
)

$ErrorActionPreference = "Stop"
$workspace = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$imagePath = [System.IO.Path]::GetFullPath((Join-Path $workspace $Image))
$jlinkPath = [System.IO.Path]::GetFullPath($JLinkExe)

if (-not (Test-Path -LiteralPath $imagePath -PathType Leaf)) {
    throw "Firmware image not found: $imagePath"
}
if (-not (Test-Path -LiteralPath $jlinkPath -PathType Leaf)) {
    throw "J-Link Commander not found: $jlinkPath"
}

$commandFile = Join-Path ([System.IO.Path]::GetDirectoryName($imagePath)) "flash.jlink"
$jlinkImagePath = $imagePath.Replace("\", "/")
@(
    "r"
    "h"
    "loadfile `"$jlinkImagePath`""
    "r"
    "g"
    "exit"
) | Set-Content -LiteralPath $commandFile -Encoding ASCII

& $jlinkPath -NoGui 1 -ExitOnError 1 -Device $Device -If SWD -Speed $SpeedKHz -AutoConnect 1 -CommandFile $commandFile
if ($LASTEXITCODE -ne 0) {
    throw "J-Link programming failed with exit code $LASTEXITCODE"
}
