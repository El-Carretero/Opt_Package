$ErrorActionPreference = 'Stop'
$exampleRoot = $PSScriptRoot
$sourceRoot = Split-Path $exampleRoot -Parent
$runtime = Join-Path $sourceRoot 'runtime'
$exe = Join-Path $runtime 'rezonator.exe'
if (!(Test-Path -LiteralPath $exe)) { throw 'Install reZonator first using ..\install\install.bat.' }
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$output = Join-Path $exampleRoot ('validation\runs\'+$stamp)
New-Item -ItemType Directory -Path $output -Force | Out-Null
$projectFile = Join-Path $exampleRoot '01_symmetric_cavity.rez'
$project = Get-Content -LiteralPath $projectFile -Raw -Encoding UTF8 | ConvertFrom-Json
$code = [IO.File]::ReadAllText((Join-Path $exampleRoot 'validation\native_report.py'),[Text.Encoding]::UTF8)
$custom = [pscustomobject]@{
    type='CustomPlot'; function=[pscustomobject]@{code=$code}; window=[pscustomobject]@{
        cursor_enabled=$false; cursor_mode='Both'; graphs=@{}; t_title='{func_name}';
        x_min=0; x_max=100; x_unit='mm'; x_title='{default_title} {(unit)}';
        y_min=0.12; y_max=0.16; y_unit='mm'; y_title='{default_title} {(unit)}'
    }
}
$project.windows = @($project.windows) + @($custom)
$validationFile = Join-Path $output 'native_validation.rez'
$report = Join-Path $output 'native_report.json'
[IO.File]::WriteAllText($validationFile,($project | ConvertTo-Json -Depth 50),$utf8)
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $exe
$psi.Arguments = '--example "'+$validationFile+'"'
$psi.WorkingDirectory = $runtime
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.EnvironmentVariables['OPT_SIM_LEARNING_REPORT'] = $report
# Use the same Qt version's optional offscreen plugin when its SDK is present.
# A copied runtime without the SDK uses the installed Windows plugin instead.
$platforms = Join-Path $sourceRoot 'toolchain\Qt\6.9.3\mingw_64\plugins\platforms'
if (Test-Path -LiteralPath (Join-Path $platforms 'qoffscreen.dll')) {
    $psi.EnvironmentVariables['QT_QPA_PLATFORM'] = 'offscreen'
    $psi.EnvironmentVariables['QT_QPA_PLATFORM_PLUGIN_PATH'] = $platforms
} else {
    $psi.EnvironmentVariables['QT_QPA_PLATFORM'] = 'windows'
}
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi
$started = $false
try {
    $started = $process.Start()
    if (!$started) { throw 'Failed to start the native reZonator process.' }
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    $deadline = [DateTime]::UtcNow.AddSeconds(40)
    while (!(Test-Path -LiteralPath $report) -and !$process.HasExited -and [DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 100
    }
    if (!(Test-Path -LiteralPath $report)) { throw 'Native calculation did not produce a report within 40 seconds. See the run logs.' }
    $result = Get-Content -LiteralPath $report -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($result.status -ne 'PASS') { throw ('Native example validation failed: '+$result.error) }
    $provenance = [ordered]@{
        status='PASS'; native_executable='runtime/rezonator.exe';
        executable_sha256=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant();
        example='01_symmetric_cavity.rez';
        example_sha256=(Get-FileHash -LiteralPath $projectFile -Algorithm SHA256).Hash.ToLowerInvariant();
        verified_at_utc=[DateTime]::UtcNow.ToString('o');
        run=('validation/runs/'+$stamp); report='native_report.json';
        checks='Native .rez reader, T/S ABCD stability and determinant, 202 Gaussian radius samples and 451 stability sweep samples vs analytic reference.'
    }
    [IO.File]::WriteAllText((Join-Path $output 'provenance.json'),($provenance | ConvertTo-Json -Depth 10),$utf8)
    [IO.File]::WriteAllText((Join-Path $exampleRoot 'validation\latest.json'),($provenance | ConvertTo-Json -Depth 10),$utf8)
    Write-Host ('PASS: native reZonator calculation. Output: '+$output)
    Write-Host ('Waist radius [um]: '+($result.analytic.waist_radius_m*1e6))
    Write-Host ('Mirror radius [um]: '+($result.analytic.mirror_radius_m*1e6))
} finally {
    if ($started) {
        # Terminate only this validation process, never another user's window.
        if (!$process.HasExited) { $process.Kill(); $process.WaitForExit() }
        [IO.File]::WriteAllText((Join-Path $output 'stdout.log'),$stdout.Result,$utf8)
        [IO.File]::WriteAllText((Join-Path $output 'stderr.log'),$stderr.Result,$utf8)
    }
    $process.Dispose()
}
