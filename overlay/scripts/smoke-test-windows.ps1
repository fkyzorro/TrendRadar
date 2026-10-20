[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Executable,
    [Parameter(Mandatory = $true)][string]$LogDirectory,
    [ValidateRange(10, 120)][int]$ObserveSeconds = 20
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This smoke test requires Windows.' }
$exe = (Resolve-Path -LiteralPath $Executable).Path
New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
$logDir = (Resolve-Path -LiteralPath $LogDirectory).Path
$process = $null
try {
    $process = Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) -PassThru `
        -RedirectStandardOutput (Join-Path $logDir 'app-stdout.txt') `
        -RedirectStandardError (Join-Path $logDir 'app-stderr.txt')
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $sawWindow = $false
    while ($clock.Elapsed.TotalSeconds -lt $ObserveSeconds) {
        Start-Sleep -Milliseconds 250
        $process.Refresh()
        if ($process.HasExited) {
            throw "The packaged application exited during startup (exit code $($process.ExitCode)). See app-stderr.txt."
        }
        if ($process.MainWindowHandle -ne [IntPtr]::Zero) { $sawWindow = $true }
    }
    if (-not $sawWindow) {
        throw 'The application process survived, but no visible application window appeared. Startup smoke test failed.'
    }
    @(
        'PASS: packaged executable remained running and created a main window.',
        "Observation: $ObserveSeconds seconds.",
        'Scope: startup only. Login, university services, notifications, and data synchronization are not tested.'
    ) | Set-Content -LiteralPath (Join-Path $logDir 'smoke-test.txt') -Encoding UTF8
    Write-Host 'Windows startup smoke test passed.'
}
finally {
    if ($null -ne $process) {
        $process.Refresh()
        if (-not $process.HasExited) {
            $process.CloseMainWindow() | Out-Null
            if (-not $process.WaitForExit(5000)) { Stop-Process -Id $process.Id -Force }
        }
        $process.Dispose()
    }
}
