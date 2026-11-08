$ErrorActionPreference = "Stop"
$repo = "https://github.com/nrmu9/Ro2DEngine.git"
$commit = "f97a2711e869caa2b29fbf810e5f60d60e63ca10"
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root "vendor/Ro2DEngine"
if (!(Test-Path (Join-Path $path ".git"))) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    git clone $repo $path
    if ($LASTEXITCODE -ne 0) { throw "Could not clone Ro2DEngine (Git required)." }
}
git -C $path fetch origin $commit
if ($LASTEXITCODE -ne 0) { throw "Could not fetch pinned Ro2DEngine commit." }
git -C $path checkout --detach $commit
if ($LASTEXITCODE -ne 0) { throw "Could not switch Ro2DEngine revision." }
Write-Host "Installed pinned Ro2DEngine into vendor/Ro2DEngine" -ForegroundColor Green
