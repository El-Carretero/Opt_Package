$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'download.ps1')
$uri = 'https://github.com/opossum-labs/opossum/releases/download/0.8.1/OpossumGui_0.8.1_x64.msi'
$package = Join-Path $PSScriptRoot 'OpossumGui_0.8.1_x64.msi'
if (!(Test-Path -LiteralPath $package)) { Invoke-WebRequest $uri -OutFile $package }
$hashFile = Join-Path $PSScriptRoot 'package.sha256'
$hash = (Get-FileHash -LiteralPath $package -Algorithm SHA256).Hash
if (!(Test-Path -LiteralPath $hashFile)) { throw 'Pinned package.sha256 is missing' }
if ((Get-Content -LiteralPath $hashFile -Raw).Trim() -ne $hash) { throw 'Installer SHA256 mismatch' }
$runtime = Join-Path $root 'runtime'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
$log = Join-Path $PSScriptRoot 'msi-extraction.log'
$proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/a', ('"'+$package+'"'), '/qn', ('TARGETDIR="'+$runtime+'"'), '/L*v', ('"'+$log+'"')) -PassThru -Wait -WindowStyle Hidden
if ($proc.ExitCode -ne 0) { throw "MSI extraction failed: $($proc.ExitCode). See $log" }
Get-ChildItem -LiteralPath $runtime -Filter '*.exe' -Recurse | Select-Object FullName
Write-Host 'OPOSSUM 0.8.1 extracted into isolated runtime folder.'
$graphviz = Join-Path $PSScriptRoot 'graphviz-14.1.5-win64.zip'
$gvUri = 'https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/14.1.5/windows_10_cmake_Release_Graphviz-14.1.5-win64.zip'
if (!(Test-Path -LiteralPath $graphviz)) { Invoke-WebRequest $gvUri -OutFile $graphviz }
$gvHashPath = Join-Path $PSScriptRoot 'graphviz.sha256'
if (!(Test-Path -LiteralPath $gvHashPath)) { throw 'Pinned graphviz.sha256 is missing' }
$expectedHash = ((Get-Content -LiteralPath $gvHashPath -Raw).Trim() -split '\s+')[0]
if ((Get-FileHash -LiteralPath $graphviz -Algorithm SHA256).Hash -ne $expectedHash) { throw 'Graphviz SHA256 mismatch' }
Expand-Archive -LiteralPath $graphviz -DestinationPath (Join-Path $runtime 'Graphviz') -Force
& (Join-Path $PSScriptRoot 'webview2.ps1')
& (Join-Path $PSScriptRoot 'smoke.ps1')
