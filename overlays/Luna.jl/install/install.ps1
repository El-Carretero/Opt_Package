param([switch]$SkipSmoke)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
foreach ($part in @('downloads','logs','tools')) { New-Item -ItemType Directory -Force -Path (Join-Path $PSScriptRoot $part) | Out-Null }
Start-Transcript -Path (Join-Path $PSScriptRoot 'logs\install.log') -Append | Out-Null
try {
    $zip = Join-Path $PSScriptRoot 'downloads\julia-1.10.13-win64.zip'
    $expected = '5d584991ec6f015102fb4a2483ca73623dcef37ed44c82145eb800a02c1d4361'
    if (!(Test-Path -LiteralPath $zip)) { Invoke-WebRequest 'https://julialang-s3.julialang.org/bin/winnt/x64/1.10/julia-1.10.13-win64.zip' -OutFile $zip -UseBasicParsing }
    if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLower() -ne $expected) { throw 'Julia archive checksum mismatch' }
    $runtime = Join-Path $root 'runtime'
    $julia = Join-Path $runtime 'julia-1.10.13\bin\julia.exe'
    $extractedMarker = Join-Path $runtime '.julia-extracted'
    $runtimeValid = (Test-Path -LiteralPath $julia) -and (Test-Path -LiteralPath $extractedMarker)
    if ($runtimeValid) { $runtimeValid = ((Get-Content -LiteralPath $extractedMarker -Raw).Trim() -eq $expected) }
    if (!$runtimeValid) {
        New-Item -ItemType Directory -Force -Path $runtime | Out-Null
        if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
            & tar.exe -xf $zip -C $runtime
            if ($LASTEXITCODE) { throw 'Julia archive extraction failed' }
        } else { Expand-Archive -LiteralPath $zip -DestinationPath $runtime -Force }
        Set-Content -LiteralPath (Join-Path $runtime '.julia-extracted') -Value $expected -Encoding ascii
    }
    $uv = Join-Path $PSScriptRoot 'tools\uv.exe'
    $uvZip = Join-Path $PSScriptRoot 'downloads\uv-x86_64-pc-windows-msvc.zip'
    if (!(Test-Path -LiteralPath $uvZip)) { Invoke-WebRequest 'https://github.com/astral-sh/uv/releases/download/0.11.6/uv-x86_64-pc-windows-msvc.zip' -OutFile $uvZip -UseBasicParsing }
    if ((Get-FileHash -LiteralPath $uvZip -Algorithm SHA256).Hash -ine '99aa60edd017a256dbf378f372d1cff3292dbc6696e0ea01716d9158d773ab77') { throw 'uv ZIP checksum mismatch' }
    if (!(Test-Path -LiteralPath $uv)) { Expand-Archive -LiteralPath $uvZip -DestinationPath (Join-Path $PSScriptRoot 'tools') -Force }
    if ((Get-FileHash -LiteralPath $uv -Algorithm SHA256).Hash -ine '6eb0e7a7bc0a84c3158120d36046b48c30a29e109f718c0d25fee0701a9fc84c') { throw 'uv executable checksum mismatch' }
    $env:UV_PYTHON_INSTALL_DIR = Join-Path $root '.python'
    $env:UV_CACHE_DIR = Join-Path $root '.cache\uv'
    $env:UV_LINK_MODE = 'copy'
    $env:UV_PYTHON_PREFERENCE = 'only-managed'
    & $uv python install --no-bin --no-registry 3.11.15
    if ($LASTEXITCODE) { throw 'Isolated Python installation failed' }
    $venv = Join-Path $root '.venv'
    $python = Join-Path $venv 'Scripts\python.exe'
    $marker = Join-Path $venv '.opt_sim_root'
    $validVenv = $false
    if ((Test-Path -LiteralPath $python) -and (Test-Path -LiteralPath $marker)) {
        $validVenv = ((Get-Content -LiteralPath $marker -Raw).Trim() -eq $root)
        if ($validVenv) { & $python -c 'import sys; assert sys.version_info[:2] == (3, 11)'; $validVenv = ($LASTEXITCODE -eq 0) }
    }
    if (!$validVenv) {
        if (Test-Path -LiteralPath $venv) {
            $previousName = '.venv.previous-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
            $previousPath = Join-Path $root $previousName
            $prefix = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
            if (![IO.Path]::GetFullPath($venv).StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or ![IO.Path]::GetFullPath($previousPath).StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe environment relocation path' }
            Rename-Item -LiteralPath $venv -NewName $previousName
        }
        $basePython = Join-Path $root '.python\cpython-3.11.15-windows-x86_64-none\python.exe'
        & $uv venv --python $basePython $venv
        if ($LASTEXITCODE) { throw 'Python environment failed' }
        Set-Content -LiteralPath $marker -Value $root -Encoding UTF8
    }
    $lock = Join-Path $PSScriptRoot 'python-requirements.lock.txt'
    & $uv pip sync --require-hashes --python $python $lock
    if ($LASTEXITCODE) { throw 'Plotting Python dependency installation failed' }
    & $uv pip freeze --python $python | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'logs\installed-python.txt') -Encoding ascii
    & $uv pip check --python $python
    if ($LASTEXITCODE) { throw 'Python dependency validation failed' }
    Set-Content -LiteralPath (Join-Path $PSScriptRoot 'logs\pip-check.log') -Value 'All installed Python packages are compatible.' -Encoding UTF8
    $env:JULIA_DEPOT_PATH = Join-Path $root '.julia'
    $env:CONDA_JL_HOME = Join-Path $root '.conda'
    $env:PYTHON = $python
    $env:MPLBACKEND = 'Agg'
    $env:MPLCONFIGDIR = Join-Path $root '.cache\matplotlib'
    $env:JULIA_NUM_THREADS = '2'
    $env:JULIA_NUM_PRECOMPILE_TASKS = '1'
    $env:JULIA_PKG_PRECOMPILE_AUTO = '0'
    Push-Location $root
    try {
        & $julia --startup-file=no --project=. (Join-Path $PSScriptRoot 'setup.jl')
        if ($LASTEXITCODE) { throw 'Julia package setup failed' }
        if (!$SkipSmoke) {
            $smokeOut = Join-Path $PSScriptRoot 'logs\smoke.stdout.log'
            $smokeErr = Join-Path $PSScriptRoot 'logs\smoke.stderr.log'
            $smokeArgs = @('--startup-file=no', '--project=.', ('"' + (Join-Path $PSScriptRoot 'smoke.jl') + '"'))
            $smokeProcess = Start-Process -FilePath $julia -ArgumentList $smokeArgs -WorkingDirectory $root -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $smokeOut -RedirectStandardError $smokeErr
            $smokeText = @(Get-Content -LiteralPath $smokeOut -Encoding UTF8; Get-Content -LiteralPath $smokeErr -Encoding UTF8)
            $smokeText | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'logs\smoke.log') -Encoding UTF8
            Write-Output $smokeText
            if ($smokeProcess.ExitCode -ne 0) { throw 'Luna smoke test failed' }
        }
    } finally { Pop-Location }
    $validation = @('Julia dependencies instantiated; PyCall connected to the local Python environment')
    $status = 'installed-not-smoke-tested'
    if (!$SkipSmoke) { $validation += 'Real GNLSE propagation: finite field and energy conservation within 0.1%'; $status = 'installed-and-validated' }
    [ordered]@{
        name = 'Luna.jl'; version = '0.6.2'
        source_commit = '7bc2f156feb0df62fdd48c5678cef2ade8fedd94'
        environment = 'Windows x64 / Julia 1.10.13 private depot / Python 3.11.15 private venv'
        status = $status; validation = $validation
        limitations = @('Gain, inversion depletion, thermal models and regenerative switching require separate models', 'Only a short GNLSE smoke case was validated')
        launch = @('launch.bat'); installer = 'install/install.bat (online, pinned Julia and Python dependencies)'
        verified_at = (Get-Date).ToUniversalTime().ToString('o')
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'status.json') -Encoding UTF8
    Write-Output 'Luna installation successful. Launch with launch.bat.'
} finally { Stop-Transcript | Out-Null }
