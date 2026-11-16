[CmdletBinding()]
param(
    [string]$Destination = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Opt_sim'),
    [string]$PackageDirectory = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Opt_Package'),
    [string]$Ref = 'main',
    [string[]]$Projects = @(),
    [switch]$Plan,
    [switch]$PrepareOnly,
    [switch]$SkipWSL,
    [switch]$Reinstall,
    [switch]$InstallPrerequisites,
    [string]$WslDistro = 'Ubuntu-24.04'
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$repository='El-Carretero/Opt_Package'
if ($Ref -notmatch '^[A-Za-z0-9_.-]+$') { throw 'Use a branch/tag name without slashes, or a full commit SHA.' }
$packagePath=[IO.Path]::GetFullPath($PackageDirectory).TrimEnd('\','/')
if (Test-Path -LiteralPath $packagePath) {
    throw "Package directory already exists: $packagePath. Run its install.ps1 to resume, or choose a new -PackageDirectory."
}
$parent=Split-Path $packagePath -Parent
New-Item -ItemType Directory -Force -Path $parent | Out-Null
$work=Join-Path $parent ('.Opt_Package-bootstrap-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
(Get-Item -LiteralPath $work -Force).Attributes = (Get-Item -LiteralPath $work -Force).Attributes -bor [IO.FileAttributes]::Hidden
$archive=Join-Path $work 'package.zip'
$previousProgress=$ProgressPreference; $ProgressPreference='SilentlyContinue'
try {
    # Resolve once, then fetch exactly that commit. No Git installation or GitHub login is needed.
    if ($Ref -match '^[0-9a-fA-F]{40}$') { $commit=$Ref.ToLowerInvariant() }
    else {
        $resolved=Invoke-RestMethod -Uri "https://api.github.com/repos/$repository/commits/$Ref" -Headers @{Accept='application/vnd.github+json';'User-Agent'='Opt-Package-bootstrap'}
        $commit=$resolved.sha
    }
    if ($commit -notmatch '^[0-9a-f]{40}$') { throw 'GitHub did not return a valid commit.' }
    Invoke-WebRequest -UseBasicParsing -Uri "https://codeload.github.com/$repository/zip/$commit" -OutFile $archive
    if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
        & tar.exe -xf $archive -C $work
        if ($LASTEXITCODE -ne 0) { throw 'Package extraction failed.' }
    } else { Expand-Archive -LiteralPath $archive -DestinationPath $work }
    $unpacked=Join-Path $work ('Opt_Package-'+$commit)
    if (!(Test-Path -LiteralPath (Join-Path $unpacked 'packages.lock.json'))) { throw 'Downloaded package is incomplete.' }
    $workPrefix=[IO.Path]::GetFullPath($work).TrimEnd('\')+'\'
    if (!([IO.Path]::GetFullPath($unpacked)).StartsWith($workPrefix,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetDirectoryName($packagePath) -ne [IO.Path]::GetFullPath($parent)) { throw 'Unsafe package destination.' }
    Move-Item -LiteralPath $unpacked -Destination $packagePath
    [IO.File]::WriteAllText((Join-Path $packagePath '.downloaded-commit'),$commit)
    # Only our temporary archive and now-empty staging directory are removed.
    Remove-Item -LiteralPath $archive -Force
    Remove-Item -LiteralPath $work -Force
} finally { $ProgressPreference=$previousProgress }
$installArgs=@{Destination=$Destination;Projects=$Projects;WslDistro=$WslDistro;Plan=$Plan;PrepareOnly=$PrepareOnly;SkipWSL=$SkipWSL;Reinstall=$Reinstall;InstallPrerequisites=$InstallPrerequisites}
Write-Host "Downloaded Opt_Package commit $commit to $packagePath"
& (Join-Path $packagePath 'install.ps1') @installArgs
