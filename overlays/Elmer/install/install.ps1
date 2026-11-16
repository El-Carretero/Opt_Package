$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'download.ps1')
$uri = 'https://www.nic.funet.fi/pub/sci/physics/elmer/bin/windows/elmerfem-nompi-devel-26.2-11c118114-20260917_Windows-AMD64.zip'
$package = Join-Path $PSScriptRoot 'elmerfem-nompi-devel-26.2-11c118114-20260917_Windows-AMD64.zip'
if (!(Test-Path -LiteralPath $package)) { Invoke-WebRequest $uri -OutFile $package }
$hashFile = Join-Path $PSScriptRoot 'package.sha256'
$hash = (Get-FileHash -LiteralPath $package -Algorithm SHA256).Hash
if (Test-Path -LiteralPath $hashFile) { if ((Get-Content -LiteralPath $hashFile -Raw).Trim() -ne $hash) { throw 'Installer SHA256 mismatch' } } else { throw 'Pinned package.sha256 is missing' }
Expand-Archive -LiteralPath $package -DestinationPath (Join-Path $root 'runtime') -Force
Write-Host 'Elmer 26.2 development binary (11c118114) installed in isolated runtime.'

Install-SourceDependency 'https://codeload.github.com/ElmerCSC/Zoltan/zip/d81e6a0aed26fbfe36087fd266801d90b99990da' 'Zoltan-d81e6a0a.zip' '34b5fd3ce11dcf3b478ecbf76fdd41c202bad0a972ff51fb5ba1dc0416368956' 'contrib/Zoltan_v3.83'
& (Join-Path $PSScriptRoot 'smoke.ps1')
