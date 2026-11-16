[CmdletBinding()]
param(
    [string]$Destination = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Opt_sim'),
    [string[]]$Projects = @(),
    [switch]$List,
    [switch]$Plan,
    [switch]$PrepareOnly,
    [switch]$SkipWSL,
    [switch]$Reinstall,
    [switch]$InstallPrerequisites,
    [string]$WslDistro = 'Ubuntu-24.04'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$packageRoot = $PSScriptRoot
$lockPath = Join-Path $packageRoot 'packages.lock.json'
$lock = Get-Content -LiteralPath $lockPath -Raw -Encoding UTF8 | ConvertFrom-Json
$manifestHash = (Get-FileHash -LiteralPath $lockPath -Algorithm SHA256).Hash.ToLowerInvariant()
$selected = @($lock.packages)
if ($Projects.Count -gt 0) {
    $names = @($Projects | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    foreach ($name in $names) { if ($name -notin @($lock.packages.name)) { throw "Unknown project: $name. Use -List." } }
    $selected = @($selected | Where-Object { $_.name -in $names })
}
if ($SkipWSL) { $selected = @($selected | Where-Object { $_.platform -ne 'wsl' }) }
if ($List -or $Plan) {
    $selected | Select-Object name, version, platform, commit | Format-Table -AutoSize
    Write-Host "Destination: $Destination"
    Write-Host 'Full installation: allow at least 80 GiB free space; reZonator builds from source.'
    Write-Host 'WSL tools require initialized WSL2 Ubuntu-24.04. GPU checks require a compatible NVIDIA device.'
    return
}
if ($selected.Count -eq 0) { throw 'No projects selected.' }
if (![Environment]::Is64BitOperatingSystem -or ![Environment]::Is64BitProcess) { throw 'Run 64-bit Windows PowerShell on Windows x64.' }
if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { throw 'This snapshot targets Windows x64, not Windows ARM64.' }
$destinationRoot = [IO.Path]::GetFullPath($Destination).TrimEnd('\','/')
if ($destinationRoot -eq [IO.Path]::GetPathRoot($destinationRoot).TrimEnd('\','/')) { throw 'Destination must be a dedicated folder, not a drive root.' }
if ($destinationRoot -eq [IO.Path]::GetFullPath($packageRoot).TrimEnd('\','/')) { throw 'Keep the package repository and installed projects in separate folders.' }
New-Item -ItemType Directory -Force -Path $destinationRoot | Out-Null
$stateRoot = Join-Path $destinationRoot '.opt-package'
$cacheRoot = Join-Path $stateRoot 'downloads'
$logRoot = Join-Path $stateRoot ('logs\'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Force -Path $stateRoot,$cacheRoot,$logRoot | Out-Null
$utf8 = New-Object Text.UTF8Encoding($false)
function Write-JsonFile($Path, $Value) {
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 30), $utf8)
}
function Get-VerifiedDownload($Url, $Path, $Hash) {
    if ($Hash -notmatch '^[0-9a-fA-F]{64}$') { throw "Missing SHA256: $Url" }
    if (Test-Path -LiteralPath $Path) {
        if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -eq $Hash) { return }
        throw "Cached file checksum mismatch: $Path. Move that file aside and retry."
    }
    $partial = $Path + '.partial'
    $previousProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        $success = $false
        for ($attempt=1; $attempt -le 3; $attempt++) {
            try { Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $partial; $success=$true; break }
            catch { if ($attempt -eq 3) { throw }; Write-Warning "Download attempt $attempt failed; retrying." }
        }
        if (!$success -or (Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash -ne $Hash) { throw "Downloaded file checksum mismatch: $Url" }
        Move-Item -LiteralPath $partial -Destination $Path
    } finally { $ProgressPreference = $previousProgress }
}
function Expand-Source($Archive, $Target, $Name) {
    $work = Join-Path $stateRoot ('work\'+$Name+'-'+[guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    $prefix = [IO.Path]::GetFullPath($work).TrimEnd('\')+'\'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    $symbolicLinks = @()
    try {
        foreach ($entry in $zip.Entries) {
            $entryPath = [IO.Path]::GetFullPath((Join-Path $work $entry.FullName))
            if (!$entryPath.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe path in source archive.' }
            $unixType = ($entry.ExternalAttributes -shr 16) -band 61440
            if ($unixType -eq 40960) {
                $reader = New-Object IO.StreamReader($entry.Open())
                try { $linkText = $reader.ReadToEnd() } finally { $reader.Dispose() }
                if ([IO.Path]::IsPathRooted($linkText)) { throw 'Absolute symbolic link in source archive.' }
                $linkTarget = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetDirectoryName($entryPath)) $linkText))
                if (!$linkTarget.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'Symbolic link escapes source archive.' }
                $symbolicLinks += [pscustomobject]@{entry=$entry.FullName;path=$entryPath;target=$linkTarget}
            }
        }
    } finally { $zip.Dispose() }
    if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
        $tarArgs = @('-xf',$Archive,'-C',$work)
        foreach ($link in $symbolicLinks) { $tarArgs += @('--exclude',$link.entry) }
        & tar.exe @tarArgs
        if ($LASTEXITCODE -ne 0) { throw "Source extraction failed: $Name" }
    } else {
        if ($symbolicLinks.Count -gt 0) { throw 'Windows tar.exe is required for this source archive.' }
        Expand-Archive -LiteralPath $Archive -DestinationPath $work
    }
    # Windows often cannot create Unix symlinks without elevation. Preserve the
    # referenced file contents instead, after verifying all targets stay inside.
    $pending = @($symbolicLinks)
    while ($pending.Count -gt 0) {
        $unresolved = @(); $resolvedCount = 0
        foreach ($link in $pending) {
            if (Test-Path -LiteralPath $link.target -PathType Leaf) {
                New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($link.path)) | Out-Null
                Copy-Item -LiteralPath $link.target -Destination $link.path
                $resolvedCount++
            } elseif (Test-Path -LiteralPath $link.target -PathType Container) {
                throw 'Directory symbolic links require explicit handling; refusing unsafe recursion.'
            } else { $unresolved += $link }
        }
        if ($resolvedCount -eq 0) { throw 'Missing or cyclic symbolic link target in source archive.' }
        $pending = @($unresolved)
    }
    $children = @(Get-ChildItem -LiteralPath $work -Force)
    if ($children.Count -ne 1 -or !$children[0].PSIsContainer) { throw "Unexpected source archive structure: $Name" }
    $sourcePath = [IO.Path]::GetFullPath($children[0].FullName)
    $targetPath = [IO.Path]::GetFullPath($Target)
    if (!$sourcePath.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetDirectoryName($targetPath) -ne $destinationRoot) { throw 'Unsafe source move rejected.' }
    Move-Item -LiteralPath $sourcePath -Destination $targetPath
}
function Apply-Overlay($Package, $Target) {
    $overlayPath = Join-Path $packageRoot $Package.overlay
    if (!(Test-Path -LiteralPath $overlayPath -PathType Container)) { throw "Missing overlay: $($Package.name)" }
    # Preserve the upstream README before adding the Korean package guide.
    $readme = @(Get-ChildItem -LiteralPath $Target -File | Where-Object { $_.Name -ieq 'README.md' })
    $preserved = Join-Path $Target 'README.upstream.md'
    if ($readme.Count -gt 0 -and !(Test-Path -LiteralPath $preserved)) { Copy-Item -LiteralPath $readme[0].FullName -Destination $preserved }
    foreach ($item in Get-ChildItem -LiteralPath $overlayPath -Force) { Copy-Item -LiteralPath $item.FullName -Destination $Target -Recurse -Force }
}
$results = New-Object System.Collections.Generic.List[object]
foreach ($package in $selected) {
    $name = $package.name
    if ($name -notmatch '^[A-Za-z0-9_.-]+$' -or $name -in @('.','..')) { throw 'Invalid project folder name.' }
    $target = Join-Path $destinationRoot $name
    $markerPath = Join-Path $target '.opt-package.json'
    $projectLog = Join-Path $logRoot ($name+'.log')
    Write-Host "`n[$name] $($package.version)"
    try {
        $marker = $null
        if (Test-Path -LiteralPath $target) {
            if (!(Test-Path -LiteralPath $markerPath)) { throw "Existing unmanaged folder preserved: $target. Choose a new -Destination." }
            $marker = Get-Content -LiteralPath $markerPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($marker.commit -ne $package.commit -or $marker.manifest_sha256 -ne $manifestHash) { throw "Existing snapshot differs for $name. Choose a new -Destination to preserve it." }
            if ($marker.state -eq 'installed' -and !$Reinstall) {
                Write-Host 'Already installed with this snapshot; skipped. Use -Reinstall to re-run the installer.'
                $results.Add([pscustomobject]@{name=$name;status='already_installed';log=$null}); continue
            }
        } else {
            $archive = Join-Path $cacheRoot ($name+'-'+$package.commit+'.zip')
            Get-VerifiedDownload $package.sourceUrl $archive $package.sourceSha256
            Expand-Source $archive $target $name
            $marker = [ordered]@{name=$name;commit=$package.commit;manifest_sha256=$manifestHash;state='source_ready';snapshot=$lock.snapshot;updated_utc=[DateTime]::UtcNow.ToString('o')}
            Write-JsonFile $markerPath $marker
            Apply-Overlay $package $target
            $marker.state = 'prepared'
            Write-JsonFile $markerPath $marker
        }
        if ($marker.state -eq 'source_ready') { Apply-Overlay $package $target; $marker.state='prepared'; Write-JsonFile $markerPath $marker }
        if ($PrepareOnly) {
            Write-Host 'Sources and setup files prepared; runtime installation not requested.'
            $results.Add([pscustomobject]@{name=$name;status='prepared';log=$null}); continue
        }
        $env:OPT_PACKAGE_WSL_DISTRO = $WslDistro
        $installer = Join-Path $target $package.installer
        if (!(Test-Path -LiteralPath $installer)) { throw "Installer missing: $installer" }
        # A child PowerShell isolates each installer's environment variables and exit code.
        $previousErrorAction = $ErrorActionPreference
        try {
            # PowerShell 5.1 turns native stderr into ErrorRecords; judge failure by the child exit code.
            $ErrorActionPreference = 'Continue'
            $childArguments = @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$installer)
            if ($InstallPrerequisites -and $name -eq 'NPAmp') { $childArguments += '-InstallPrerequisites' }
            & powershell.exe @childArguments *>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { $_ }
            } | Tee-Object -FilePath $projectLog
            $installExit = $LASTEXITCODE
        } finally { $ErrorActionPreference = $previousErrorAction }
        if ($installExit -ne 0) { throw "Installer exited with code $installExit. See $projectLog" }
        $marker.state='installed'; $marker.updated_utc=[DateTime]::UtcNow.ToString('o')
        Write-JsonFile $markerPath $marker
        $results.Add([pscustomobject]@{name=$name;status='installed';log=$projectLog})
    } catch {
        $failure = $_.Exception.Message
        Write-Warning "[$name] $failure"
        $results.Add([pscustomobject]@{name=$name;status='failed';error=$failure;log=$projectLog})
    }
}
$reportPath = Join-Path $logRoot 'summary.json'
Write-JsonFile $reportPath ([ordered]@{snapshot=$lock.snapshot;manifest_sha256=$manifestHash;destination=$destinationRoot;finished_utc=[DateTime]::UtcNow.ToString('o');results=@($results.ToArray())})
$results | Select-Object name,status | Format-Table -AutoSize
Write-Host "Report: $reportPath"
if (@($results | Where-Object { $_.status -eq 'failed' }).Count -gt 0) { throw 'One or more projects failed. Completed projects are retained; fix the cause and run the same command again.' }
Write-Host 'Completed all selected projects.'
