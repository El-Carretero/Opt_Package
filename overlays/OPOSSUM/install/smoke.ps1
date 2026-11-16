$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$runtime = Join-Path $root 'runtime\OpossumGui'
$dot = Get-ChildItem -LiteralPath (Join-Path $root 'runtime\Graphviz') -Filter 'dot.exe' -Recurse | Select-Object -First 1
if ($dot) { $env:PATH = $dot.DirectoryName + ';' + $env:PATH }
$reports = Join-Path $PSScriptRoot 'smoke-reports'
New-Item -ItemType Directory -Path $reports -Force | Out-Null
Push-Location $runtime
try {
  & '.\opossum_cli.exe' --version
  & '.\opossum_cli.exe' -s false -f '.\workshop_00_kepler_paraxial.opm' -r $reports 2>&1 | Tee-Object -FilePath (Join-Path $PSScriptRoot 'smoke.log')
  if ($LASTEXITCODE -ne 0) { throw "OPOSSUM calculation failed: $LASTEXITCODE" }
} finally { Pop-Location }
Write-Host 'PASS: OPOSSUM Kepler telescope model analyzed.'
