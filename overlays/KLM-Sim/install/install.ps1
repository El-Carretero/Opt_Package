$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'download.ps1')
$Archive = Get-LegacyPinnedFile 'octave'
$Extract = Get-LegacyPinnedFile '7zr'
$runtime = Join-Path $Root '.runtime'
$bin = Join-Path $runtime 'octave-11.3.0-w64\mingw64\bin'
$Octave = Join-Path $bin 'octave-cli.exe'
if (!(Test-Path -LiteralPath $Octave)) {
    New-Item -ItemType Directory -Force -Path $runtime | Out-Null
    Invoke-LegacyNative $Extract @('x','-y',$Archive,('-o'+$runtime))
}
if (!(Test-Path -LiteralPath $Octave)) { throw 'Pinned Octave executable not found after extraction' }
$env:Path = $bin+';'+$env:Path
$Proc = Start-Process -FilePath $Octave -ArgumentList '--no-gui','--quiet',('"'+(Join-Path $PSScriptRoot 'smoke.m')+'"') -WorkingDirectory $Root -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $PSScriptRoot 'smoke-test.log') -RedirectStandardError (Join-Path $PSScriptRoot 'smoke-stderr.log')
if ($Proc.ExitCode -ne 0) { throw 'KLM-Sim/Octave smoke test failed; see install/smoke-stderr.log' }
Write-LegacyStatus 'Windows x64 isolated GNU Octave 11.3.0' 'settings, MLSpatial, NLloss and SatGain passed. Full oscillator GUI run is not covered.'
Write-Host 'KLM-Sim installed with isolated GNU Octave 11.3.0.'
