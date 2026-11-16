$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$runtime = Join-Path $root 'runtime\elmerfem-nompi-devel-26.2-11c118114-20260917_Windows-AMD64'
$env:PATH = (Join-Path $runtime 'bin') + ';' + $env:PATH
$env:ELMER_HOME = $runtime
$env:OMP_NUM_THREADS = '2'
$work = Join-Path $PSScriptRoot 'smoke-HeatAniso'
New-Item -ItemType Directory -Path $work -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'fem\tests\HeatAniso\case.sif') -Destination $work -Force
Copy-Item -LiteralPath (Join-Path $root 'fem\tests\HeatAniso\cross.grd') -Destination $work -Force
Push-Location $work
try {
  & (Join-Path $runtime 'bin\ElmerGrid.exe') 1 2 cross.grd 2>&1 | Tee-Object -FilePath 'mesh.log'
  if ($LASTEXITCODE -ne 0) { throw "ElmerGrid failed: $LASTEXITCODE" }
  & (Join-Path $runtime 'bin\ElmerSolver.exe') case.sif 2>&1 | Tee-Object -FilePath 'solver.log'
  if ($LASTEXITCODE -ne 0) { throw "ElmerSolver failed: $LASTEXITCODE" }
  if (!(Get-ChildItem -LiteralPath $work -Filter 'case*.vtu' -Recurse)) { throw 'Elmer output missing' }
  if (!(Select-String -LiteralPath 'solver.log' -SimpleMatch 'PASSED all 2 tests!')) { throw 'Elmer reference comparison did not pass' }
} finally { Pop-Location }
Write-Host 'PASS: Elmer anisotropic heat conduction and flux solve completed.'
