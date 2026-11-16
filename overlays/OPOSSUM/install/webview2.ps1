$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'download.ps1')
# Evergreen WebView2 is a Windows GUI prerequisite, separate from OPOSSUM's
# portable files. Reuse an existing installation and never force a downgrade.
$installed=$false
foreach($key in @('HKCU:\Software\Microsoft\EdgeUpdate\Clients',
                  'HKLM:\Software\Microsoft\EdgeUpdate\Clients',
                  'HKLM:\Software\WOW6432Node\Microsoft\EdgeUpdate\Clients')) {
    if(Test-Path $key) {
        foreach($child in (Get-ChildItem $key -ErrorAction SilentlyContinue)) {
            $values=Get-ItemProperty $child.PSPath -ErrorAction SilentlyContinue
            if(($values.name -like '*WebView2*') -and $values.pv -and $values.pv -ne '0.0.0.0') {$installed=$true}
        }
    }
}
if($installed){Write-Host 'Existing Microsoft WebView2 Runtime detected.';return}
$file=Join-Path $PSScriptRoot 'downloads\MicrosoftEdgeWebView2RuntimeInstallerX64.exe'
Get-VerifiedFile 'https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/52cfd0a8-f256-48d4-9b18-467f2b3cda78/MicrosoftEdgeWebView2RuntimeInstallerX64.exe' $file 'd3cbe8fedb104282d745fff106993efead51ae94f5595a4e75804446a974f9c3'
$signature=Get-AuthenticodeSignature -LiteralPath $file
if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {throw 'Microsoft WebView2 signature validation failed'}
Write-Host 'Installing the Microsoft WebView2 GUI prerequisite for the current user.'
$process=Start-Process -FilePath $file -ArgumentList @('/silent','/install') -WindowStyle Hidden -Wait -PassThru
if($process.ExitCode -notin @(0,3010)){throw "WebView2 installation failed: $($process.ExitCode)"}
