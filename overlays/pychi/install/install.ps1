$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$bootstrap = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'bootstrap.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not [Environment]::Is64BitOperatingSystem) { throw 'This package requires Windows x64.' }
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$uv = Join-Path $PSScriptRoot 'bin\uv.exe'
$env:UV_PYTHON_INSTALL_DIR = Join-Path $root '.runtime\python'
$env:UV_CACHE_DIR = Join-Path $root '.runtime\uv-cache'
$env:UV_LINK_MODE = 'copy'
$env:UV_NO_CONFIG = 'true'
$env:PYTHONNOUSERSITE = '1'
$env:PYTHONUTF8 = '1'
$env:PYTHONDONTWRITEBYTECODE = '1'
$env:SETUPTOOLS_SCM_PRETEND_VERSION = $config.version
$env:MPLBACKEND = 'Agg'
$env:MPLCONFIGDIR = Join-Path $root '.runtime\matplotlib'
New-Item -ItemType Directory -Force -Path (Join-Path $PSScriptRoot 'logs') | Out-Null
Start-Transcript -Path (Join-Path $PSScriptRoot 'logs\install.log') -Force | Out-Null
function Assert-Sha256([string]$Path, [string]$Expected) {
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -ne $Expected) { throw "SHA256 mismatch: $Path. Expected $Expected; received $actual." }
}
function Run-UV { & $uv @args; if ($LASTEXITCODE -ne 0) { throw "uv failed: $args" } }
try {
    if (-not (Test-Path -LiteralPath $uv)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $uv) | Out-Null
        $zip = Join-Path $PSScriptRoot 'bin\uv.zip'
        Invoke-WebRequest -UseBasicParsing -Uri $bootstrap.url -OutFile $zip
        Assert-Sha256 $zip $bootstrap.archiveSha256
        Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $PSScriptRoot 'bin') -Force
        if (-not (Test-Path -LiteralPath $uv)) { throw 'uv.exe missing after bootstrap.' }
    }
    # Verify a cached executable too, before executing it.
    Assert-Sha256 $uv $bootstrap.executableSha256
    Run-UV python install --no-bin --no-registry $config.python
    $venv = Join-Path $root '.venv'
    $venvCfg = Join-Path $venv 'pyvenv.cfg'
    if (Test-Path -LiteralPath $venv) {
        $stale = -not (Test-Path -LiteralPath $venvCfg)
        if (-not $stale) {
            $baseLine = @(Get-Content -LiteralPath $venvCfg | Where-Object { $_ -match '^home\s*=' } | Select-Object -First 1)
            $basePath = if ($baseLine.Count) { ($baseLine[0] -replace '^home\s*=\s*','').Trim() } else { '' }
            $expectedBase = [IO.Path]::GetFullPath((Join-Path $root '.runtime\python')) + [IO.Path]::DirectorySeparatorChar
            $stale = (-not $basePath.StartsWith($expectedBase, [StringComparison]::OrdinalIgnoreCase)) -or (-not (Test-Path -LiteralPath (Join-Path $basePath 'python.exe')))
        }
        if ($stale) {
            $resolvedVenv = [IO.Path]::GetFullPath($venv)
            if ([IO.Path]::GetDirectoryName($resolvedVenv) -ne [IO.Path]::GetFullPath($root)) { throw 'Unexpected venv path; refusing to move.' }
            $backup = Join-Path $root ('.venv.previous-' + (Get-Date -Format 'yyyyMMddHHmmssfff'))
            Write-Host "Moved environment detected; preserving old environment as $backup"
            Move-Item -LiteralPath $resolvedVenv -Destination $backup
        }
    }
    $python = Join-Path $venv 'Scripts\python.exe'
    $managedPython = Join-Path $env:UV_PYTHON_INSTALL_DIR ('cpython-' + $config.python + '-windows-x86_64-none\python.exe')
    if (-not (Test-Path -LiteralPath $python)) { Run-UV venv --seed --python $managedPython $venv }
    $lock = Join-Path $PSScriptRoot 'requirements.lock.txt'
    if (-not (Test-Path -LiteralPath $lock)) { throw 'Pinned requirements.lock.txt is missing.' }
    if ($config.name -eq 'TorchOptics') {
        Run-UV pip install --python $python -r $lock --extra-index-url 'https://download.pytorch.org/whl/cu128' --index-strategy unsafe-best-match
    } else { Run-UV pip install --python $python -r $lock }
    if ($config.mode -eq 'source') {
        $target = $root
        if ($config.extras) { $target += '[' + $config.extras + ']' }
        Run-UV pip install --python $python --no-deps --reinstall-package $config.package -e $target
    }
    if ($config.name -eq 'Diffractio') { New-Item -ItemType Directory -Force -Path (Join-Path $root 'work') | Out-Null }
    Run-UV pip check --python $python
    & $python -I (Join-Path $PSScriptRoot 'smoke_test.py')
    if ($LASTEXITCODE -ne 0) { throw 'Computation smoke test failed.' }
    & $python -I (Join-Path $PSScriptRoot 'record_environment.py')
    if ($LASTEXITCODE -ne 0) { throw 'Environment record failed.' }
    Write-Host 'SUCCESS: installation, dependency check and computation completed.'
} finally { Stop-Transcript | Out-Null }
