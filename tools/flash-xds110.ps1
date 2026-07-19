param(
    [string]$Image = "build/firmware.out",
    [string]$DSLiteExe = "D:/ti/ccs/ccs_base/DebugServer/bin/DSLite.exe"
)

$ErrorActionPreference = "Stop"
$workspace = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$imagePath = [System.IO.Path]::GetFullPath((Join-Path $workspace $Image))
$configPath = Join-Path $PSScriptRoot "mspm0g3507_xds110.ccxml"
$dslitePath = [System.IO.Path]::GetFullPath($DSLiteExe)

if (-not (Test-Path -LiteralPath $imagePath -PathType Leaf)) {
    throw "Firmware image not found: $imagePath"
}
if (-not (Test-Path -LiteralPath $dslitePath -PathType Leaf)) {
    throw "DSLite not found: $dslitePath"
}
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "XDS110 target configuration not found: $configPath"
}

& $dslitePath flash --config=$configPath --flash --verify --run $imagePath
if ($LASTEXITCODE -ne 0) {
    throw "DSLite programming failed with exit code $LASTEXITCODE"
}
