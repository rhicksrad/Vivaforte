# Build VIVAFORTE NES ROM (ca65/ld65 from tools/cc65)
$ErrorActionPreference = "Stop"
$root  = Split-Path -Parent $PSScriptRoot
$ca65  = Join-Path $root "tools\cc65\bin\ca65.exe"
$ld65  = Join-Path $root "tools\cc65\bin\ld65.exe"
$src   = Join-Path $PSScriptRoot "src"
$build = Join-Path $PSScriptRoot "build"

if (-not (Test-Path $build)) { New-Item -ItemType Directory $build | Out-Null }

& $ca65 -I $src (Join-Path $src "main.s") -g -o (Join-Path $build "main.o")
if ($LASTEXITCODE -ne 0) { exit 1 }

& $ld65 -C (Join-Path $PSScriptRoot "vivaforte.cfg") (Join-Path $build "main.o") `
    -o (Join-Path $build "vivaforte.nes") `
    -Ln (Join-Path $build "labels.txt") --dbgfile (Join-Path $build "vivaforte.dbg")
if ($LASTEXITCODE -ne 0) { exit 1 }

$rom = Get-Item (Join-Path $build "vivaforte.nes")
Write-Host ("OK: {0} ({1} bytes)" -f $rom.FullName, $rom.Length)
