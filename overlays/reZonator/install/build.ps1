param([switch]$ConfigureOnly, [int]$Jobs = 2)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'download.ps1')
foreach ($dependency in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'source-dependencies.json') -Raw | ConvertFrom-Json)) {
  Install-SourceDependency $dependency.url $dependency.name $dependency.sha256 $dependency.destination
}
$downloads = Join-Path $PSScriptRoot 'build-downloads'
$toolchain = Join-Path $root 'toolchain'
$stage = Join-Path $root 'build-output\runtime'
$build = Join-Path $root 'build-native'
$existingCache = Join-Path $build 'CMakeCache.txt'
if (Test-Path -LiteralPath $existingCache) {
  $homeLine = Select-String -LiteralPath $existingCache -Pattern '^CMAKE_HOME_DIRECTORY:INTERNAL=(.+)$' | Select-Object -First 1
  if ($homeLine -and ([IO.Path]::GetFullPath($homeLine.Matches[0].Groups[1].Value) -ine [IO.Path]::GetFullPath($root))) {
    $hasher = [Security.Cryptography.SHA256]::Create()
    try { $suffix = [BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($root))).Replace('-','').Substring(0,12).ToLowerInvariant() } finally { $hasher.Dispose() }
    $build = Join-Path $root ('build-native-'+$suffix)
    Write-Host ('Copied CMake cache belongs to another path; preserving it and using '+$build)
  }
}
New-Item -ItemType Directory -Path $downloads,$toolchain,$stage,$build -Force | Out-Null
$env:PIP_CACHE_DIR = Join-Path $downloads 'pip-cache'

function Invoke-Native([string]$Exe, [string[]]$Arguments) {
  & $Exe @Arguments
  if ($LASTEXITCODE -ne 0) { throw "Native command failed ($LASTEXITCODE): $Exe $($Arguments -join ' ')" }
}
function Get-PinnedFile([string]$Uri, [string]$File, [string]$Sha256) {
  if (!(Test-Path -LiteralPath $File)) { Invoke-WebRequest $Uri -OutFile $File }
  if ((Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash -ne $Sha256) { throw "SHA256 mismatch: $File" }
}

$pythonPackage = Join-Path $downloads 'python.3.12.10.nupkg'
Get-PinnedFile 'https://api.nuget.org/v3-flatcontainer/python/3.12.10/python.3.12.10.nupkg' $pythonPackage '0EB85C2DFCCCCF1B17352DE4C397F69194035B7D37149EACC16F1147D93DE3B8'
$pythonSdk = Join-Path $toolchain 'python-sdk\tools'
if (!(Test-Path -LiteralPath (Join-Path $pythonSdk 'python.exe'))) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory($pythonPackage,(Join-Path $toolchain 'python-sdk'))
}
$buildPython = Join-Path $root '.build-venv\Scripts\python.exe'
$venv = Join-Path $root '.build-venv'
$venvConfig = Join-Path $venv 'pyvenv.cfg'
if (Test-Path -LiteralPath $venvConfig) {
  $venvHome = Select-String -LiteralPath $venvConfig -Pattern '^home\s*=\s*(.+)$' | Select-Object -First 1
  if ($venvHome -and ([IO.Path]::GetFullPath($venvHome.Matches[0].Groups[1].Value.Trim()) -ine [IO.Path]::GetFullPath($pythonSdk))) {
    $oldVenv = [IO.Path]::GetFullPath($venv)
    $savedVenv = [IO.Path]::GetFullPath((Join-Path $root ('.build-venv-before-relocation-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))))
    $allowedRoot = [IO.Path]::GetFullPath($root).TrimEnd('\')+'\'
    if (!$oldVenv.StartsWith($allowedRoot,[StringComparison]::OrdinalIgnoreCase) -or !$savedVenv.StartsWith($allowedRoot,[StringComparison]::OrdinalIgnoreCase)) { throw 'Relocated virtual-environment paths must remain inside the project.' }
    Move-Item -LiteralPath $oldVenv -Destination $savedVenv
    Write-Host ('Preserved copied virtual environment at '+$savedVenv)
  }
}
if (!(Test-Path -LiteralPath $buildPython)) { Invoke-Native (Join-Path $pythonSdk 'python.exe') @('-m','venv',$venv) }
Invoke-Native $buildPython @('-m','pip','install','--require-hashes','-r',(Join-Path $PSScriptRoot 'build-requirements.lock.txt'))
$qt = Join-Path $toolchain 'Qt\6.9.3\mingw_64'
$compiler = Join-Path $toolchain 'Qt\Tools\mingw1310_64\bin'
if (!(Test-Path -LiteralPath (Join-Path $qt 'bin\windeployqt.exe'))) {
  Invoke-Native $buildPython @('-m','aqt','install-qt','windows','desktop','6.9.3','win64_mingw','--archives','qtbase','qttools','qtsvg','qttranslations','MinGW','d3dcompiler_47','opengl32sw','-O',(Join-Path $toolchain 'Qt'),'-k','-d',$downloads)
}
if (!(Test-Path -LiteralPath (Join-Path $compiler 'g++.exe'))) {
  Invoke-Native $buildPython @('-m','aqt','install-tool','windows','desktop','tools_mingw1310','qt.tools.win64_mingw1310','-O',(Join-Path $toolchain 'Qt'),'-k','-d',$downloads)
}
$env:PATH = $compiler + ';' + (Join-Path $qt 'bin') + ';' + (Join-Path $root '.build-venv\Scripts') + ';' + $env:PATH

$luaPackage = Join-Path $downloads 'lua-5.4.8.tar.gz'
Get-PinnedFile 'https://www.lua.org/ftp/lua-5.4.8.tar.gz' $luaPackage '4F18DDAE154E793E46EEAB727C59EF1C0C0C2B744E7B94219710D76F530629AE'
$hashManifest = Join-Path $PSScriptRoot 'build-downloads.sha256.json'
if (Test-Path -LiteralPath $hashManifest) {
  foreach ($entry in (Get-Content -LiteralPath $hashManifest -Raw | ConvertFrom-Json)) {
    $path = Join-Path $downloads $entry.name
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Build download hash mismatch: $path" }
  }
}
$luaSource = Join-Path $toolchain 'lua-5.4.8\src'
if (!(Test-Path -LiteralPath (Join-Path $luaSource 'lua.h'))) { Invoke-Native 'tar.exe' @('-xzf',$luaPackage,'-C',$toolchain) }
$luaBuild = Join-Path $toolchain 'lua-build'
New-Item -ItemType Directory -Path $luaBuild -Force | Out-Null
$luaLibrary = Join-Path $luaBuild 'liblua.a'
if (!(Test-Path -LiteralPath $luaLibrary)) {
  foreach ($source in (Get-ChildItem -LiteralPath $luaSource -Filter '*.c' | Where-Object {$_.Name -notin @('lua.c','luac.c')})) {
    Invoke-Native (Join-Path $compiler 'gcc.exe') @('-O2','-DLUA_USE_WINDOWS','-c',$source.FullName,'-o',(Join-Path $luaBuild ($source.BaseName+'.o')))
  }
  $objects = @(Get-ChildItem -LiteralPath $luaBuild -Filter '*.o' | ForEach-Object {$_.FullName})
  Invoke-Native (Join-Path $compiler 'ar.exe') (@('rcs',$luaLibrary) + $objects)
}
$cmake = Join-Path $root '.build-venv\Lib\site-packages\cmake\data\bin\cmake.exe'
Invoke-Native $cmake @('-S',$root,'-B',$build,'-G','Ninja','-DCMAKE_BUILD_TYPE=Release',('-DCMAKE_MAKE_PROGRAM='+(Join-Path $root '.build-venv\Scripts\ninja.exe')),('-DCMAKE_C_COMPILER='+(Join-Path $compiler 'gcc.exe')),('-DCMAKE_CXX_COMPILER='+(Join-Path $compiler 'g++.exe')),('-DCMAKE_PREFIX_PATH='+$qt),('-DCMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE='+$stage),('-DPython3_ROOT_DIR='+$pythonSdk),('-DPython3_INCLUDE_DIR='+(Join-Path $pythonSdk 'include')),('-DPython3_LIBRARY='+(Join-Path $pythonSdk 'libs\python312.lib')),('-DLUA_INCLUDE_DIR='+$luaSource),('-DLUA_LIBRARY='+$luaLibrary),('-DCMAKE_EXE_LINKER_FLAGS=-L"'+$luaBuild.Replace('\','/')+'"'))
if ($ConfigureOnly) { Write-Host 'Native Windows build configured.'; exit 0 }
Invoke-Native $cmake @('--build',$build,'--parallel',([string]$Jobs))
$exe = Join-Path $stage 'rezonator.exe'
if (!(Test-Path -LiteralPath $exe)) { throw 'Expected staged executable was not produced.' }
$assistantExe = Join-Path $stage 'assistant.exe'
Copy-Item -LiteralPath (Join-Path $qt 'bin\assistant.exe') -Destination $assistantExe -Force
Invoke-Native (Join-Path $qt 'bin\windeployqt.exe') @('--release','--compiler-runtime','--dir',$stage,$exe,$assistantExe)
foreach ($name in 'python312.dll','python3.dll','vcruntime140.dll','vcruntime140_1.dll','LICENSE.txt') { Copy-Item -LiteralPath (Join-Path $pythonSdk $name) -Destination $stage -Force }
$runtimePython = Join-Path $stage 'python'
New-Item -ItemType Directory -Path $runtimePython -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $pythonSdk 'Lib') -Destination $runtimePython -Recurse -Force
Copy-Item -LiteralPath (Join-Path $pythonSdk 'DLLs') -Destination $runtimePython -Recurse -Force
foreach ($name in 'examples','templates','test_files') { Copy-Item -LiteralPath (Join-Path $root ('bin\'+$name)) -Destination $stage -Recurse -Force }
Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $stage 'LICENSE-reZonator.txt') -Force
Copy-Item -LiteralPath (Join-Path $toolchain 'lua-5.4.8\doc\readme.html') -Destination (Join-Path $stage 'LICENSE-Lua.html') -Force
$originalZip = Join-Path $PSScriptRoot 'rezonator-2.3.0-win-x64.zip'
Get-PinnedFile 'https://github.com/orion-project/rezonator2/releases/download/v2.3.0/rezonator-2.3.0-win-x64.zip' $originalZip 'CE96DCC064B22F94537EA1447F4DB92B7DF239ED461A9F4F435168CD657AB8BE'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($originalZip)
try { foreach ($entry in $archive.Entries) { if ($entry.Name -in @('rezonator.qch','rezonator.qhc')) { [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,(Join-Path $stage $entry.Name),$true) } } } finally { $archive.Dispose() }
$verificationPath = $env:PATH
$verificationOverrides = @{}
foreach ($name in 'PYTHONHOME','PYTHONPATH','QT_PLUGIN_PATH','QT_QPA_PLATFORM_PLUGIN_PATH') {
  $verificationOverrides[$name] = [Environment]::GetEnvironmentVariable($name,'Process')
  [Environment]::SetEnvironmentVariable($name,$null,'Process')
}
try {
  $env:PATH = $env:SystemRoot+'\System32;'+$env:SystemRoot+';'+$stage
  & (Join-Path $PSScriptRoot 'smoke.ps1') -RuntimePath $stage -ExpectedTests 532
} finally {
  $env:PATH = $verificationPath
  foreach ($name in $verificationOverrides.Keys) { [Environment]::SetEnvironmentVariable($name,$verificationOverrides[$name],'Process') }
}
Write-Host ('Native patched runtime staged and tested: '+$stage)
