param([switch]$Shell,[string]$Distro=$env:OPT_PACKAGE_WSL_DISTRO,[string]$LinuxUser=$env:OPT_PACKAGE_WSL_USER)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
if(!$Distro){$Distro='Ubuntu-24.04'}
$wslArgs=@('-d',$Distro)
if($LinuxUser){$wslArgs+=@('-u',$LinuxUser)}
$linuxRootRaw=& wsl.exe @wslArgs --exec wslpath -a $root.Replace('\','/')
if($LASTEXITCODE -ne 0 -or !$linuxRootRaw){throw 'WSL2 is required. Run prepare-wsl.bat as administrator on a new PC, reboot if requested, initialize a Linux user, then rerun. OPT_PACKAGE_WSL_DISTRO selects an existing distro.'}
$linuxRoot=($linuxRootRaw -join '').Trim()
$script=if($Shell){'launch-wsl.sh'}else{'install-wsl.sh'}
$command=@('--exec','env')
if($env:OPT_PACKAGE_STATE_ROOT){$command+=('OPT_PACKAGE_STATE_ROOT='+$env:OPT_PACKAGE_STATE_ROOT)}
$command+=@('bash',"$linuxRoot/install/$script")
& wsl.exe @wslArgs @command
if($LASTEXITCODE -ne 0){throw "WSL task failed with exit code $LASTEXITCODE"}
