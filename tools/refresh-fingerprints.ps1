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
foreach ($package in $lock.packages) {
    $overlay=Join-Path $root $package.overlay
    $rows=@(Get-ChildItem -LiteralPath $overlay -Recurse -File | ForEach-Object {
        $_.FullName.Substring($overlay.Length+1).Replace('\','/')+' '+(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    })
    $package | Add-Member -Force -NotePropertyName overlaySha256 -NotePropertyValue (Hash-Lines $rows)
}
$setupRows=@('install.ps1','bootstrap.ps1' | ForEach-Object { $_+' '+(Get-FileHash -LiteralPath (Join-Path $root $_) -Algorithm SHA256).Hash.ToLowerInvariant() })
$lock | Add-Member -Force -NotePropertyName setupSha256 -NotePropertyValue (Hash-Lines $setupRows)
[IO.File]::WriteAllText($path,($lock | ConvertTo-Json -Depth 20)+"`n",$utf8)
Write-Host 'Updated fingerprints. Existing destinations intentionally reject this changed snapshot; validate in a new folder.'
