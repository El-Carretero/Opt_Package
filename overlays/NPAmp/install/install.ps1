param([switch]$InstallPrerequisites)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'download.ps1')
$Archive = Get-LegacyPinnedFile 'npamp'
$ExtractZip = Get-LegacyPinnedFile 'innoextract'
$tools = Join-Path $PSScriptRoot 'tools'
$Extract = Join-Path $tools 'innoextract.exe'
if (!(Test-Path -LiteralPath $Extract)) { Expand-Archive -LiteralPath $ExtractZip -DestinationPath $tools -Force }
if ((Get-FileHash -LiteralPath $Extract -Algorithm SHA256).Hash -ine '946bd06d8b3722a791fea4d84f496139eef6faef61640924cb72f5f1998a68e1') { throw 'innoextract.exe hash mismatch' }
$runtime = Join-Path $Root '.runtime'
New-Item -ItemType Directory -Force -Path $runtime | Out-Null
Invoke-LegacyNative $Extract @('--silent','--extract','--output-dir',$runtime,$Archive)
$exe = Join-Path $runtime 'app\NPAmp.exe'
$redist = Join-Path $runtime 'tmp\vcredist_x86.exe'
if ((Get-FileHash -LiteralPath $redist -Algorithm SHA256).Hash -ine '41f45a46ee56626ff2699d525bb56a3bb4718c5ca5f4fb5b3b38add64584026b') { throw 'Bundled VC2008 x86 redistributable hash mismatch' }
function Test-NPAmpSmoke {
    $script:NPAmpPrerequisiteMissing = $false
    for ($attempt=1; $attempt -le 5; $attempt++) {
        try {
            $proc = Start-Process -FilePath $exe -ArgumentList ('"'+(Join-Path $PSScriptRoot 'smoke.npc')+'"') -WorkingDirectory $Root -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $PSScriptRoot 'smoke-test.log') -RedirectStandardError (Join-Path $PSScriptRoot 'smoke-stderr.log')
            if ($proc.ExitCode -ne 0) {
                $script:NPAmpPrerequisiteMissing = $proc.ExitCode -in @(-1072365566,-1073741515)
                return $false
            }
            $log = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'smoke-test.log') -Raw
            return ($log -match '1\.32532784093')
        } catch {
            $errorCode = 0
            $exception = $_.Exception
            while ($exception) {
                if ($exception -is [ComponentModel.Win32Exception]) { $errorCode = $exception.NativeErrorCode; break }
                $exception = $exception.InnerException
            }
            # A freshly extracted executable can briefly remain locked by scanning.
            # Access/sharing failures are not evidence of a missing system CRT.
            if ($errorCode -in @(5,32) -and $attempt -lt 5) { Start-Sleep -Seconds 1; continue }
            $script:NPAmpPrerequisiteMissing = $errorCode -in @(126,14001,14003,14004)
            Write-Warning ('NPAmp launch failed (Win32 '+$errorCode+'): '+$_.Exception.Message)
            return $false
        }
    }
}
if (!(Test-NPAmpSmoke)) {
    if (!$InstallPrerequisites) {
        throw 'NPAmp could not complete its smoke test. On a fresh PC the Microsoft VC++2008 x86 runtime may be missing (side-by-side / VC90 error). Run install\install-prerequisites.bat, or powershell.exe -NoProfile -ExecutionPolicy Bypass -File install\install.ps1 -InstallPrerequisites. This explicitly permits the official system prerequisite installer and may request administrator approval. Check smoke-stderr.log for other calculation errors.'
    }
    if (!$script:NPAmpPrerequisiteMissing) { throw 'NPAmp failed for a reason other than an identified missing/invalid runtime dependency. The system prerequisite installer was not run. See smoke logs and launch error above.' }
    Write-Host 'Installing the official bundled Microsoft VC++2008 x86 prerequisite. Windows may request administrator approval.'
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    # VC++2008 uses /r:n to suppress reboot (later VC++ versions use /norestart).
    $params = @{FilePath=$redist;ArgumentList=@('/q','/r:n');WindowStyle='Hidden';Wait=$true;PassThru=$true}
    if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $params.Verb = 'RunAs' }
    $proc = Start-Process @params
    if ($proc.ExitCode -notin @(0,3010)) { throw ('VC++2008 prerequisite installer failed, exit code '+$proc.ExitCode) }
    if (!(Test-NPAmpSmoke)) { throw 'NPAmp still failed after prerequisite installation. If Windows requested a restart, restart and run install.bat again. See smoke-stderr.log.' }
}
Write-LegacyStatus 'Official Windows app-local Python 2.7 runtime; Microsoft VC++2008 x86 system CRT prerequisite' 'Single-pulse amplifier calculation passed: energy gain 1.32532784093.'
Write-Host 'NPAmp 1.2.18 installed and numerically validated.'
