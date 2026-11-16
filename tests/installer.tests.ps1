$ErrorActionPreference='Stop'
$repositoryRoot=Split-Path $PSScriptRoot -Parent
$testRoot=Join-Path ([IO.Path]::GetTempPath()) ('Opt-Package-tests-'+[guid]::NewGuid().ToString('N'))
$fixture=Join-Path $testRoot 'package'
$target=Join-Path $testRoot 'installed with spaces'
New-Item -ItemType Directory -Force -Path $fixture,$target | Out-Null
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'install.ps1') -Destination $fixture
$utf8=New-Object Text.UTF8Encoding($false)
function Put($Path,$Text) {
    New-Item -ItemType Directory -Force -Path (Split-Path $Path -Parent) | Out-Null
    [IO.File]::WriteAllText($Path,$Text,$utf8)
}
function Assert($Condition,$Message) { if (!$Condition) { throw "FAIL: $Message" }; Write-Host "PASS: $Message" }
function Run-Installer([string[]]$Arguments) {
    $old=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fixture 'install.ps1') -Destination $target @Arguments *> (Join-Path $testRoot 'last-run.log')
        return $LASTEXITCODE
    } finally { $ErrorActionPreference=$old }
}
$src=Join-Path $testRoot 'source'
Put (Join-Path $src 'upstream/README.md') 'UPSTREAM README'
Put (Join-Path $src 'upstream/original.txt') 'UPSTREAM SOURCE'
$zip=Join-Path $testRoot 'source.zip'
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($src,$zip)
$update=[IO.Compression.ZipFile]::Open($zip,[IO.Compression.ZipArchiveMode]::Update)
try {
    $link=$update.CreateEntry('upstream/source-link.txt')
    $link.ExternalAttributes=-1577123840
    $writer=New-Object IO.StreamWriter($link.Open(),$utf8)
    try { $writer.Write('original.txt') } finally { $writer.Dispose() }
} finally { $update.Dispose() }
$hash=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
$commit='0123456789012345678901234567890123456789'
$entries=@()
foreach ($name in @('First','Second')) {
    $entry=[ordered]@{name=$name;version='test';platform='windows';repo='fixture/source';commit=$commit;sourceUrl='https://invalid.example/never-downloaded.zip';sourceSha256=$hash;overlay=('overlays/'+$name);installer='install/install.ps1'}
    $entries+=$entry
    $overlay=Join-Path $fixture ('overlays/'+$name)
    Put (Join-Path $overlay 'README.md') 'PACKAGE GUIDE'
    Put (Join-Path $overlay 'install/install.ps1') @'
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if (Test-Path -LiteralPath (Join-Path $root 'fail.flag')) { Write-Error 'Intentional test failure'; exit 7 }
$counter=Join-Path $root 'count.txt'
$count=0
if (Test-Path -LiteralPath $counter) { $count=[int](Get-Content -LiteralPath $counter -Raw) }
[IO.File]::WriteAllText($counter,[string]($count+1))
[Console]::Error.WriteLine('A successful native dependency may write stderr.')
Write-Host 'Fixture installation passed.'
exit 0
'@
    $cache=Join-Path $target '.opt-package/downloads'
    New-Item -ItemType Directory -Force -Path $cache | Out-Null
    Copy-Item -LiteralPath $zip -Destination (Join-Path $cache ($name+'-'+$commit+'.zip'))
}
$manifest=[ordered]@{snapshot='fixture';packages=$entries}
Put (Join-Path $fixture 'packages.lock.json') ($manifest | ConvertTo-Json -Depth 10)
Assert ((Run-Installer @('-PrepareOnly')) -eq 0) 'PrepareOnly creates source and overlay without running installers'
Assert (!(Test-Path -LiteralPath (Join-Path $target 'First/count.txt'))) 'PrepareOnly does not install runtime'
Assert ((Get-Content -LiteralPath (Join-Path $target 'First/README.upstream.md') -Raw) -eq 'UPSTREAM README') 'Upstream README is preserved'
Assert ((Get-Content -LiteralPath (Join-Path $target 'First/README.md') -Raw) -eq 'PACKAGE GUIDE') 'Overlay README is applied'
Assert ((Get-Content -LiteralPath (Join-Path $target 'First/source-link.txt') -Raw) -eq 'UPSTREAM SOURCE') 'Unix file symlink is materialized without Windows elevation'
Put (Join-Path $target 'First/fail.flag') 'intentional'
Assert ((Run-Installer @()) -ne 0) 'One failed installer causes overall nonzero exit'
Assert ((Get-Content -LiteralPath (Join-Path $target 'Second/count.txt') -Raw) -eq '1') 'Later projects still run after an earlier failure'
Remove-Item -LiteralPath (Join-Path $target 'First/fail.flag')
Assert ((Run-Installer @()) -eq 0) 'Retry resumes failed project and accepts successful child stderr'
Assert ((Get-Content -LiteralPath (Join-Path $target 'First/count.txt') -Raw) -eq '1') 'Retry installed failed project once'
Assert ((Get-Content -LiteralPath (Join-Path $target 'Second/count.txt') -Raw) -eq '1') 'Retry skips completed project'
Assert ((Run-Installer @()) -eq 0) 'Repeated completed run succeeds'
Assert ((Get-Content -LiteralPath (Join-Path $target 'First/count.txt') -Raw) -eq '1') 'Repeated run is idempotent'
Assert ((Run-Installer @('-Reinstall')) -eq 0) 'Explicit reinstall succeeds'
Assert ((Get-Content -LiteralPath (Join-Path $target 'Second/count.txt') -Raw) -eq '2') 'Explicit reinstall runs selected installers'
Assert ((Run-Installer @('-Projects','Unknown')) -ne 0) 'Unknown project names are rejected'
$target=Join-Path $testRoot 'existing-unmanaged'
Put (Join-Path $target 'First/keep.txt') 'USER DATA'
Assert ((Run-Installer @('-Projects','First','-PrepareOnly')) -ne 0) 'Unmanaged existing folder is rejected'
Assert ((Get-Content -LiteralPath (Join-Path $target 'First/keep.txt') -Raw) -eq 'USER DATA') 'Existing user data is preserved'
$target=Join-Path $testRoot 'bad-checksum'
Put (Join-Path $target ('.opt-package/downloads/First-'+$commit+'.zip')) 'CORRUPTED CACHE'
Assert ((Run-Installer @('-Projects','First','-PrepareOnly')) -ne 0) 'Corrupted cached download is rejected'
Assert (!(Test-Path -LiteralPath (Join-Path $target 'First'))) 'Corrupted archive is never extracted'
$target=Join-Path $testRoot 'installed with spaces'
$entries[0].commit='1111111111111111111111111111111111111111'
Put (Join-Path $fixture 'packages.lock.json') ($manifest | ConvertTo-Json -Depth 10)
Assert ((Run-Installer @('-Projects','First')) -ne 0) 'Different snapshot cannot overwrite an existing installation'
Assert ((Get-Content -LiteralPath (Join-Path $target 'First/count.txt') -Raw) -eq '2') 'Snapshot rejection leaves the environment untouched'
Write-Host "ALL INSTALLER TESTS PASSED. Test evidence: $testRoot"
