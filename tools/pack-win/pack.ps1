param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..' '..')
$project = Join-Path $repoRoot 'src/Game'
$distRoot = Join-Path $repoRoot 'dist'
$bundleRoot = Join-Path $distRoot 'win64/lifeforce-2025-mg'
$zipPath = Join-Path $distRoot 'lifeforce-2025-mg-win64.zip'

if (Test-Path $bundleRoot) {
    Remove-Item $bundleRoot -Recurse -Force
}

if (!(Test-Path $distRoot)) {
    New-Item -ItemType Directory -Path $distRoot | Out-Null
}

$publishArgs = @('publish', $project, '-c', 'Release', '-r', 'win-x64', '--self-contained', 'false', '--no-restore')
& dotnet @publishArgs

$publishDir = Join-Path $project 'bin/Release/net8.0/win-x64/publish'
if (!(Test-Path $publishDir)) {
    throw "Publish output not found at $publishDir"
}

New-Item -ItemType Directory -Path $bundleRoot -Force | Out-Null
Copy-Item -Path (Join-Path $publishDir '*') -Destination $bundleRoot -Recurse -Force

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Push-Location (Split-Path $bundleRoot -Parent)
try {
    Compress-Archive -Path (Split-Path $bundleRoot -Leaf) -DestinationPath $zipPath
}
finally {
    Pop-Location
}
