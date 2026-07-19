param(
    [string]$Image = "build/firmware.out",
    [string]$OpenOcdExe = "",
    [int]$SpeedKHz = 1000
)

$ErrorActionPreference = "Stop"
$workspace = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$imagePath = [System.IO.Path]::GetFullPath((Join-Path $workspace $Image))

if (-not (Test-Path -LiteralPath $imagePath -PathType Leaf)) {
    throw "Firmware image not found: $imagePath"
}

$candidates = @()
if ($OpenOcdExe) {
    $candidates += $OpenOcdExe
}
if ($env:OPENOCD_EXE) {
    $candidates += $env:OPENOCD_EXE
}
$candidates += @(
    "D:/ti/openocd-b56339c/bin/openocd.exe",
    "$env:LOCALAPPDATA/Texas Instruments/ti-embedded-debug/openocd/1.3.1.50/bin/openocd.exe"
)

$openOcdPath = $candidates |
    Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } |
    Select-Object -First 1

if (-not $openOcdPath) {
    throw "OpenOCD not found. Install b56339c under D:/ti/openocd-b56339c or set OPENOCD_EXE."
}

$openOcdPath = [System.IO.Path]::GetFullPath($openOcdPath)
$openOcdRoot = [System.IO.Path]::GetFullPath((Join-Path (Split-Path $openOcdPath -Parent) ".."))
$scriptsPath = Join-Path $openOcdRoot "share/openocd/scripts"

$modernTarget = Join-Path $scriptsPath "target/ti/mspm0.cfg"
$tiTarget = Join-Path $scriptsPath "target/ti_mspm0.cfg"
if (Test-Path -LiteralPath $modernTarget) {
    $targetConfig = "target/ti/mspm0.cfg"
} elseif (Test-Path -LiteralPath $tiTarget) {
    $targetConfig = "target/ti_mspm0.cfg"
} else {
    throw "This OpenOCD build does not contain an MSPM0 target configuration: $scriptsPath"
}

$openOcdImagePath = $imagePath.Replace("\", "/")
& $openOcdPath `
    -s $scriptsPath `
    -f "interface/cmsis-dap.cfg" `
    -f $targetConfig `
    -c "adapter speed $SpeedKHz" `
    -c "program {$openOcdImagePath} verify reset exit"

if ($LASTEXITCODE -ne 0) {
    throw "OpenOCD programming failed with exit code $LASTEXITCODE"
}
