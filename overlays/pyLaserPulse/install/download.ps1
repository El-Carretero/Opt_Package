# Runtime downloads are versioned and checked before extraction or execution.
function Get-LegacyPinnedFile([string]$Id) {
    $entries = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'downloads.json') -Raw | ConvertFrom-Json
    $spec = @($entries | Where-Object { $_.id -eq $Id })
    if ($spec.Count -ne 1) { throw "Unknown download ID: $Id" }
    $spec = $spec[0]
    $file = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot $spec.file))
    $allowed = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')+'\'
    if (!$file.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)) { throw 'Download path escapes install directory.' }
    New-Item -ItemType Directory -Force -Path (Split-Path $file -Parent) | Out-Null
    if (!(Test-Path -LiteralPath $file)) {
        Write-Host ('Downloading '+$Id)
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -UseBasicParsing -Uri $spec.url -OutFile ($file+'.part')
        if ((Get-FileHash -LiteralPath ($file+'.part') -Algorithm SHA256).Hash -ine $spec.sha256) { throw "SHA256 mismatch: $Id" }
        Move-Item -LiteralPath ($file+'.part') -Destination $file
    }
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ine $spec.sha256) { throw "SHA256 mismatch: $file" }
    return $file
}
function Invoke-LegacyNative([string]$Exe,[string[]]$Arguments) {
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed ($LASTEXITCODE): $Exe" }
}
function Write-LegacyStatus([string]$Environment,[string]$Validation) {
    $package = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'package.json') -Raw | ConvertFrom-Json
    $status = [ordered]@{name=$package.name;version=$package.version;source_commit=$package.commit;
        environment=$Environment;status='installed-and-validated';validation=$Validation;
        launch='launch.bat';installer='install/install.ps1';verified_at_utc=[DateTime]::UtcNow.ToString('o')}
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'status.json'),($status|ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding($false)))
}
