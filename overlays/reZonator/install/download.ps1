# Shared only within this project: no global installation or PATH edits.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
function Get-VerifiedFile([string]$Uri,[string]$Path,[string]$Sha256) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    if (!(Test-Path -LiteralPath $Path)) { Invoke-WebRequest -UseBasicParsing $Uri -OutFile $Path }
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ine $Sha256) { throw "SHA256 mismatch: $Path" }
}
function Install-SourceDependency([string]$Uri,[string]$Name,[string]$Sha256,[string]$RelativePath) {
    $destination = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
    $prefix = [IO.Path]::GetFullPath($root).TrimEnd('\')+'\'
    if (!$destination.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'Source dependency must stay inside the project.' }
    $marker = Join-Path $destination '.opt-package-source-sha256'
    if ((Test-Path -LiteralPath $marker) -and ((Get-Content -LiteralPath $marker -Raw).Trim() -eq $Sha256)) { return }
    $archive = Join-Path $PSScriptRoot ('downloads\'+$Name)
    Get-VerifiedFile $Uri $archive $Sha256
    $stage = Join-Path $PSScriptRoot ('source-stage-'+[guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage,$destination -Force | Out-Null
    & tar.exe -xf $archive -C $stage
    if ($LASTEXITCODE -ne 0) { throw "Source dependency extraction failed: $Name" }
    $top = @(Get-ChildItem -LiteralPath $stage -Directory)
    if ($top.Count -ne 1) { throw 'Expected exactly one top-level source folder.' }
    Get-ChildItem -LiteralPath $top[0].FullName -Force | Copy-Item -Destination $destination -Recurse -Force
    Set-Content -LiteralPath $marker -Value $Sha256 -Encoding ascii
}
