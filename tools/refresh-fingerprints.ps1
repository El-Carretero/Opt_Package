# Maintainer helper: update local overlay/setup fingerprints without changing any source pin.
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$path=Join-Path $root 'packages.lock.json'
$lock=Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
$utf8=New-Object Text.UTF8Encoding($false)
function Hash-Lines([string[]]$Lines) {
    [Array]::Sort($Lines,[StringComparer]::Ordinal)
    $sha=[Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($utf8.GetBytes(($Lines -join "`n"))))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function Get-ContentFingerprint($Path) {
    if ([IO.Path]::GetExtension($Path) -eq '.png') { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
    # Git checkouts/source archives may use CRLF for Windows scripts. Fingerprint
    # canonical UTF-8/LF text so the snapshot identity is independent of EOL style.
    $value=[IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8).Replace("`r`n","`n")
    $sha=[Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($utf8.GetBytes($value)))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
foreach ($package in $lock.packages) {
    $overlay=Join-Path $root $package.overlay
    $rows=@(Get-ChildItem -LiteralPath $overlay -Recurse -File | ForEach-Object {
        $_.FullName.Substring($overlay.Length+1).Replace('\','/')+' '+(Get-ContentFingerprint $_.FullName)
    })
    $package | Add-Member -Force -NotePropertyName overlaySha256 -NotePropertyValue (Hash-Lines $rows)
}
$setupRows=@('install.ps1','bootstrap.ps1' | ForEach-Object { $_+' '+(Get-ContentFingerprint (Join-Path $root $_)) })
$lock | Add-Member -Force -NotePropertyName setupSha256 -NotePropertyValue (Hash-Lines $setupRows)
[IO.File]::WriteAllText($path,($lock | ConvertTo-Json -Depth 20)+"`n",$utf8)
Write-Host 'Updated fingerprints. Existing destinations intentionally reject this changed snapshot; validate in a new folder.'
