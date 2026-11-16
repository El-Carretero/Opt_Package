param([string]$RuntimePath = '', [int]$ExpectedTests = 532, [switch]$AllowFailures)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (!$RuntimePath) { $RuntimePath = Join-Path $root 'runtime' }
$RuntimePath = [IO.Path]::GetFullPath($RuntimePath)
$exe = Join-Path $RuntimePath 'rezonator.exe'
if (!(Test-Path -LiteralPath $exe)) { throw "Missing executable: $exe" }
$baselinePath = Join-Path $PSScriptRoot 'baseline-test-names.txt'
if (!(Test-Path -LiteralPath $baselinePath)) { throw 'The public 528-case baseline name list is required.' }
$runName = 'run-' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss-fff')
$runDir = Join-Path (Join-Path $PSScriptRoot 'validation') $runName
New-Item -ItemType Directory -Path $runDir -Force | Out-Null
$stdout = Join-Path $runDir 'stdout.log'
$stderr = Join-Path $runDir 'stderr.log'
$process = Start-Process -FilePath $exe -ArgumentList @('--test','nogui') -WorkingDirectory $runDir -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$testLog = Join-Path $runDir 'test.log'
if (!(Test-Path -LiteralPath $testLog)) { throw "No new test log was produced. Exit code: $($process.ExitCode); see $runDir" }
$text = Get-Content -LiteralPath $testLog -Raw -Encoding UTF8
$summaries = [regex]::Matches($text, '(?m)^STAT: tests: (\d+), passed: (\d+), failed: (\d+)\s*$')
if ($summaries.Count -ne 1) { throw "Expected one complete test summary; found $($summaries.Count). See $testLog" }
$summary = $summaries[0]
$total = [int]$summary.Groups[1].Value
$passed = [int]$summary.Groups[2].Value
$failed = [int]$summary.Groups[3].Value
$namePattern = '(?m)^\*+ TEST \*+\r?\n([^\r\n]+)'
$names = @([regex]::Matches($text, $namePattern) | ForEach-Object { $_.Groups[1].Value.Trim() })
$failedNames = @()
foreach ($block in [regex]::Split($text, '(?m)^\*+ TEST \*+\r?\n')) {
    if ($block -match '(?m)^\*+ FAILED \*+\s*$') { $failedNames += ($block -split '\r?\n')[0].Trim() }
}
$baselineNames = @()
if (Test-Path -LiteralPath $baselinePath) {
    $baselineNames = @(Get-Content -LiteralPath $baselinePath -Encoding UTF8 | Where-Object { $_.Trim() })
}
if ($baselineNames.Count -ne 528) { throw "Expected the 528-case original baseline, found $($baselineNames.Count)" }
$missingBaseline = @($baselineNames | Where-Object { $_ -notin $names })
$result = [ordered]@{
    verified_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    executable = $exe
    executable_sha256 = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLower()
    exit_code = $process.ExitCode
    tests = $total; passed = $passed; failed = $failed
    failed_tests = $failedNames
    baseline_tests = $baselineNames.Count
    missing_baseline_tests = $missingBaseline
    new_tests = @($names | Where-Object { $_ -notin $baselineNames })
    log_directory = $runDir
}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runDir 'result.json') -Encoding UTF8
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'validation-latest.json') -Encoding UTF8
Copy-Item -LiteralPath $testLog -Destination (Join-Path $PSScriptRoot 'test.log') -Force
Write-Host $summary.Value.Trim()
Write-Host "Original cases retained: $($baselineNames.Count - $missingBaseline.Count)/$($baselineNames.Count)"
Write-Host "Full log: $testLog"
if ($process.ExitCode -ne 0) { throw "Test process failed with exit code $($process.ExitCode)" }
if (($total -le 0) -or ($total -ne $names.Count) -or ($total -ne $passed + $failed)) { throw 'Incomplete or inconsistent test results' }
if (($ExpectedTests -gt 0) -and ($total -ne $ExpectedTests)) { throw "Expected $ExpectedTests tests, observed $total" }
if ($missingBaseline.Count -gt 0) { throw 'Some original test cases were omitted; see result.json' }
if (($failed -gt 0) -and !$AllowFailures) { throw "$failed tests failed; see $testLog" }
