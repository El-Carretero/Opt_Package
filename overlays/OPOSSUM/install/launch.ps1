$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$dot = Get-ChildItem -LiteralPath (Join-Path $root 'runtime\Graphviz') -Filter 'dot.exe' -Recurse | Select-Object -First 1
if ($dot) { $env:PATH = $dot.DirectoryName + ';' + $env:PATH }
$runtime = Join-Path $root 'runtime\OpossumGui'
Set-Location -LiteralPath $runtime
& (Join-Path $runtime 'opossum_gui.exe')
