$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'download.ps1')
$package = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'package.json') -Raw | ConvertFrom-Json
Push-Location -LiteralPath $Root
try {
    $env:UV_CACHE_DIR = Join-Path $PSScriptRoot 'cache'
    $env:UV_LINK_MODE = 'copy'
    $env:UV_PYTHON_DOWNLOADS = 'never'
    $env:UV_PYTHON_INSTALL_DIR = Join-Path $Root '.runtime\managed'
    $zip = Get-LegacyPinnedFile 'uv'
    $tools = Join-Path $PSScriptRoot 'tools'
    $Uv = Join-Path $tools 'uv.exe'
    if (!(Test-Path -LiteralPath $Uv)) { Expand-Archive -LiteralPath $zip -DestinationPath $tools -Force }
    if ((Get-FileHash -LiteralPath $Uv -Algorithm SHA256).Hash -ine '6eb0e7a7bc0a84c3158120d36046b48c30a29e109f718c0d25fee0701a9fc84c') { throw 'uv.exe hash mismatch' }
    $archive = Get-LegacyPinnedFile 'python'
    $runtime = Join-Path $Root '.runtime'
    $Python = Join-Path $runtime 'python\python.exe'
    if (!(Test-Path -LiteralPath $Python)) {
        New-Item -ItemType Directory -Force -Path $runtime | Out-Null
        $tar = (Get-Command tar.exe -ErrorAction Stop).Source
        Invoke-LegacyNative $tar @('-xzf',$archive,'-C',$runtime)
    }
    $actualPython = & $Python -c 'import platform; print(platform.python_version())'
    if ($LASTEXITCODE -ne 0 -or $actualPython.Trim() -ne $package.python) { throw 'Unexpected project Python version' }
    $venv = Join-Path $Root '.venv'
    $venvConfig = Join-Path $venv 'pyvenv.cfg'
    if (Test-Path -LiteralPath $venvConfig) {
        $match = Select-String -LiteralPath $venvConfig -Pattern '^home\s*=\s*(.+)$' | Select-Object -First 1
        $expectedHome = [IO.Path]::GetFullPath((Split-Path $Python -Parent))
        if (!$match -or [IO.Path]::GetFullPath($match.Matches[0].Groups[1].Value.Trim()) -ine $expectedHome) {
            $original = [IO.Path]::GetFullPath($venv)
            $backup = [IO.Path]::GetFullPath((Join-Path $Root ('.venv.previous-'+(Get-Date -Format 'yyyyMMddHHmmssfff'))))
            $allowed = [IO.Path]::GetFullPath($Root).TrimEnd('\')+'\'
            if (!$original.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase) -or !$backup.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected environment path' }
            Move-Item -LiteralPath $original -Destination $backup
        }
    }
    $venvPython = Join-Path $venv 'Scripts\python.exe'
    if (!(Test-Path -LiteralPath $venvPython)) { Invoke-LegacyNative $Uv @('venv','--python',$Python,$venv) }
    Invoke-LegacyNative $Uv @('pip','install','--python',$venvPython,'--require-hashes','-r',(Join-Path $PSScriptRoot 'requirements-hashed.txt'))
    if ($package.editable) { Invoke-LegacyNative $Uv @('pip','install','--python',$venvPython,'--no-build-isolation','--no-deps','-e','.') }
    if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'native.ps1')) { & (Join-Path $PSScriptRoot 'native.ps1') }
    Invoke-LegacyNative $Uv @('pip','check','--python',$venvPython)
    $smoke = Start-Process -FilePath $venvPython -ArgumentList ('"'+(Join-Path $PSScriptRoot 'smoke.py')+'"') -WorkingDirectory $Root -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $PSScriptRoot 'smoke-test.log') -RedirectStandardError (Join-Path $PSScriptRoot 'smoke-stderr.log')
    if ($smoke.ExitCode -ne 0) { Get-Content -LiteralPath (Join-Path $PSScriptRoot 'smoke-stderr.log'); throw 'Numerical smoke test failed' }
    Write-LegacyStatus ('Windows x64 local CPython '+$package.python+' + .venv') 'Dependency consistency and numerical smoke test passed; see smoke-test.log.'
    Write-Host ($package.name+' installation completed. See Readme.md.')
} finally { Pop-Location }
