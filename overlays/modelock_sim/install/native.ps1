$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Archive = Get-LegacyPinnedFile 'w64devkit'
$Compiler = Join-Path $Root '.runtime\w64devkit\bin\gcc.exe'
if (!(Test-Path -LiteralPath $Compiler)) {
    $process = Start-Process -FilePath $Archive -ArgumentList '-y',('-o"'+(Join-Path $Root '.runtime')+'"') -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw 'Compiler extraction failed' }
}
$env:Path = (Split-Path $Compiler -Parent)+';'+$env:Path
New-Item -ItemType Directory -Force -Path (Join-Path $Root 'cfuncs\libs') | Out-Null
Push-Location -LiteralPath $Root
try { Invoke-LegacyNative $Compiler @('-O2','-shared','-o','cfuncs/libs/libdiode.dll','cfuncs/diode_actions.c','-lm') }
finally { Pop-Location }
Write-Host 'CPU DLL built. GPU Maxwell-Bloch diode paths are unsupported.'
