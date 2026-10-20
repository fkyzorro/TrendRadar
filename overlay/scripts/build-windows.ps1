[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($env:OS -ne 'Windows_NT') { throw 'Run this script on 64-bit Windows with Flutter and Visual Studio C++ installed.' }
if (-not [Environment]::Is64BitProcess) { throw 'Use 64-bit PowerShell.' }
if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw 'This build script requires an x64 Windows host.' }

$projectRoot = Split-Path $PSScriptRoot -Parent
$dist = Join-Path $projectRoot 'dist'
$logs = Join-Path $dist 'logs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$transcribing = $false
Push-Location $projectRoot
try {
    Start-Transcript -Path (Join-Path $logs 'build-transcript.txt') -Force | Out-Null
    $transcribing = $true
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -eq $flutter) { throw 'Flutter was not found on PATH. Install the Flutter Windows SDK and reopen PowerShell.' }
    $flutterPath = $flutter.Source
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) {
        throw 'Visual Studio Installer was not found. Install Visual Studio 2022 with Desktop development with C++, including MSVC, CMake, and Windows SDK.'
    }
    $vsInstall = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($vsInstall -join ''))) {
        throw 'Visual Studio C++ tools were not found. Add the Desktop development with C++ workload, including CMake and Windows SDK.'
    }
    $vsInstall = [string]($vsInstall | Select-Object -First 1)

    function Invoke-Flutter([string[]]$Arguments) {
        Write-Host ('flutter ' + ($Arguments -join ' '))
        & $flutterPath @Arguments
        if ($LASTEXITCODE -ne 0) { throw "Flutter failed (exit code $LASTEXITCODE): $($Arguments -join ' ')" }
    }

    Invoke-Flutter -Arguments @('--version')
    Invoke-Flutter -Arguments @('doctor', '-v')
    Invoke-Flutter -Arguments @('config', '--enable-windows-desktop')
    Invoke-Flutter -Arguments @('clean')
    Invoke-Flutter -Arguments @('pub', 'get')
    if (-not (Test-Path -LiteralPath 'pubspec.lock')) { throw 'Dependency resolution did not create pubspec.lock.' }
    Copy-Item -LiteralPath 'pubspec.lock' -Destination (Join-Path $logs 'pubspec.lock') -Force
    # Flutter 3.35 selects the Windows target architecture from the host.
    Invoke-Flutter -Arguments @('build', 'windows', '--release')

    $releaseDir = Join-Path $projectRoot 'build\windows\x64\runner\Release'
    if (-not (Test-Path -LiteralPath (Join-Path $releaseDir 'Celechron.exe'))) {
        throw "The Windows release executable was not produced at $releaseDir."
    }
    foreach ($required in @('flutter_windows.dll', 'data\icudtl.dat', 'data\app.so', 'data\flutter_assets')) {
        if (-not (Test-Path -LiteralPath (Join-Path $releaseDir $required))) { throw "Incomplete Flutter release: missing $required." }
    }
    $bundleName = 'Celechron-1.3.1-Windows-x64'
    $bundle = Join-Path $dist $bundleName
    if (Test-Path -LiteralPath $bundle) { Remove-Item -LiteralPath $bundle -Recurse -Force }
    New-Item -ItemType Directory -Path $bundle | Out-Null
    Copy-Item -Path (Join-Path $releaseDir '*') -Destination $bundle -Recurse -Force

    # Only use the installed Visual Studio redistribution directory, never System32.
    $redistRoot = Join-Path $vsInstall 'VC\Redist\MSVC'
    if (-not (Test-Path -LiteralPath $redistRoot)) { throw 'Visual C++ redistributable files were not found in the Visual Studio installation.' }
    $redistVersion = Get-ChildItem -LiteralPath $redistRoot -Directory |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+' } |
        Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
    if ($null -eq $redistVersion) { throw 'No versioned Visual C++ redistribution directory was found.' }
    $crt = Get-ChildItem -Path (Join-Path $redistVersion.FullName 'x64\Microsoft.VC*.CRT') -Directory |
        Select-Object -First 1
    if ($null -eq $crt) { throw 'The x64 Visual C++ CRT redistribution directory was not found.' }
    Copy-Item -Path (Join-Path $crt.FullName '*.dll') -Destination $bundle -Force
    foreach ($required in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
        if (-not (Test-Path -LiteralPath (Join-Path $bundle $required))) { throw "Missing Visual C++ runtime: $required." }
    }

    Copy-Item -LiteralPath 'LICENSE' -Destination (Join-Path $bundle 'LICENSE-Celechron.txt')
    Copy-Item -LiteralPath 'pubspec.lock' -Destination (Join-Path $bundle 'pubspec.lock')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'PORTABLE-README.txt') -Destination (Join-Path $bundle 'README.txt')
    $flutterVersion = (& $flutterPath --version --machine | Out-String)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot record the Flutter SDK version.' }
    $flutterVersion | Set-Content -LiteralPath (Join-Path $bundle 'flutter-version.json') -Encoding UTF8

    & (Join-Path $PSScriptRoot 'smoke-test-windows.ps1') -Executable (Join-Path $bundle 'Celechron.exe') -LogDirectory $logs
    Copy-Item -LiteralPath (Join-Path $logs 'smoke-test.txt') -Destination (Join-Path $bundle 'smoke-test.txt')

    $sourceName = 'Celechron-1.3.1-Windows-source.zip'
    $sourceStage = Join-Path $dist 'source-stage'
    if (Test-Path -LiteralPath $sourceStage) { Remove-Item -LiteralPath $sourceStage -Recurse -Force }
    New-Item -ItemType Directory -Path $sourceStage | Out-Null
    function Copy-SourceEntry([string]$Source, [string]$Destination) {
        $entry = Get-Item -LiteralPath $Source -Force
        # Exclude generated plugin symlinks BEFORE descent. Their targets are
        # external caches, not application source, and may contain long paths.
        if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { return }
        if ($entry.PSIsContainer) {
            if ($entry.Name -in @('ephemeral', '.plugin_symlinks', '.symlinks', 'Pods')) { return }
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
            foreach ($child in Get-ChildItem -LiteralPath $Source -Force) {
                Copy-SourceEntry -Source $child.FullName -Destination (Join-Path $Destination $child.Name)
            }
        }
        else {
            Copy-Item -LiteralPath $Source -Destination $Destination -Force
        }
    }
    # Explicit source inputs avoid leaking user files, credentials, caches, or prior outputs.
    foreach ($item in @('lib', 'assets', 'windows', 'android', 'ios', 'macos', 'linux', 'web', 'test', 'scripts', '.github', 'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'README.md', 'LICENSE', 'banner.png', '.metadata', 'WINDOWS-BUILD-README.txt')) {
        if (Test-Path -LiteralPath $item) { Copy-SourceEntry -Source $item -Destination (Join-Path $sourceStage $item) }
    }
    $sourceZip = Join-Path $dist $sourceName
    # ZipFile includes hidden source files; Compress-Archive silently skips them.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if (Test-Path -LiteralPath $sourceZip) { Remove-Item -LiteralPath $sourceZip -Force }
    [IO.Compression.ZipFile]::CreateFromDirectory($sourceStage, $sourceZip, [IO.Compression.CompressionLevel]::Optimal, $false)
    Remove-Item -LiteralPath $sourceStage -Recurse -Force
    $sourceHash = (Get-FileHash -LiteralPath $sourceZip -Algorithm SHA256).Hash.ToLowerInvariant()
    $provenance = [ordered]@{
        application = 'Celechron'; version = '1.3.1'; target = 'windows-x64'; mode = 'release'
        built_utc = [DateTime]::UtcNow.ToString('o')
        source_archive = $sourceName; source_sha256 = $sourceHash
        dependency_lock_sha256 = (Get-FileHash -LiteralPath 'pubspec.lock' -Algorithm SHA256).Hash.ToLowerInvariant()
        visual_cpp_redist_version = $redistVersion.Name
        github_commit = $env:GITHUB_SHA; github_run_id = $env:GITHUB_RUN_ID
        startup_test = 'passed'; functional_service_tests = 'not performed'
        modification = 'Unofficial Windows compatibility build from user-provided 1.3.1 source.'
    }
    $provenance | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $bundle 'build-info.json') -Encoding UTF8
    $zip = Join-Path $dist ($bundleName + '.zip')
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    [IO.Compression.ZipFile]::CreateFromDirectory($bundle, $zip, [IO.Compression.CompressionLevel]::Optimal, $true)
    @($zip, $sourceZip) | ForEach-Object {
        $hash = (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $(Split-Path $_ -Leaf)"
    } | Set-Content -LiteralPath (Join-Path $dist 'SHA256SUMS.txt') -Encoding ASCII
    Write-Host "BUILD SUCCEEDED: $zip"
    Write-Host "MATCHING SOURCE: $sourceZip"
}
finally {
    if ($transcribing) { Stop-Transcript | Out-Null }
    Pop-Location
}
