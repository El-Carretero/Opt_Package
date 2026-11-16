param([int]$Jobs=2)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'build.ps1') -Jobs $Jobs
$stage=Join-Path $root 'build-output\runtime'
$runtime=Join-Path $root 'runtime'
$prefix=[IO.Path]::GetFullPath($root).TrimEnd('\')+'\'
foreach($path in @($stage,$runtime)) { if (![IO.Path]::GetFullPath($path).StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'Runtime path must remain in project.' } }
if(Test-Path -LiteralPath $runtime) { Rename-Item -LiteralPath $runtime -NewName ('runtime-before-build-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')) }
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
Get-ChildItem -LiteralPath $stage -Force | Copy-Item -Destination $runtime -Recurse -Force
& (Join-Path $PSScriptRoot 'smoke.ps1') -RuntimePath $runtime -ExpectedTests 532
Write-Host 'reZonator 2.3.0+opt-sim-fix1 built from source; all 532 tests passed.'
