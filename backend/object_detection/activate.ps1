param(
    [string]$AppDirectory = (Join-Path $PSScriptRoot '../../build/windows/x64/runner/Debug')
)
$ErrorActionPreference = 'Stop'
$detectorDirectory = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$appPath = (Resolve-Path -LiteralPath $AppDirectory).Path
$pythonPath = Join-Path $detectorDirectory '.venv/Scripts/python.exe'
if (-not (Test-Path -LiteralPath $pythonPath)) { throw 'Run setup.ps1 first.' }
if (-not (Test-Path -LiteralPath (Join-Path $detectorDirectory 'models/yolo11n.pt'))) {
    throw 'Local model missing. Run setup.ps1 first.'
}
$configDirectory = Join-Path $appPath 'data/object_detection'
if (-not (Test-Path -LiteralPath (Join-Path $configDirectory 'worker.py'))) {
    throw 'Build the Windows app first, or pass its directory with -AppDirectory.'
}
$config = @{ detectorDirectory = $detectorDirectory; pythonExecutable = $pythonPath } | ConvertTo-Json
[System.IO.File]::WriteAllText((Join-Path $configDirectory 'runtime.json'), $config, [System.Text.UTF8Encoding]::new($false))
Write-Output "Detector activated for $appPath. Restart the app to use it."
