$ErrorActionPreference = 'Stop'
$runtimeDirectory = Join-Path $PSScriptRoot '.venv'
python -m venv $runtimeDirectory
if ($LASTEXITCODE -ne 0) { throw 'Python runtime creation failed' }
$runtimePython = Join-Path $runtimeDirectory 'Scripts/python.exe'
& $runtimePython -m pip install torch==2.14.0 torchvision==0.29.0 --index-url https://download.pytorch.org/whl/cpu
if ($LASTEXITCODE -ne 0) { throw 'CPU inference dependencies failed' }
& $runtimePython -m pip install -r (Join-Path $PSScriptRoot 'requirements.txt')
if ($LASTEXITCODE -ne 0) { throw 'Detector dependencies failed' }
$modelDirectory = Join-Path $PSScriptRoot 'models'
New-Item -ItemType Directory -Force -Path $modelDirectory | Out-Null
$modelPath = Join-Path $modelDirectory 'yolo11n.pt'
if (-not (Test-Path -LiteralPath $modelPath)) {
    Invoke-WebRequest -Uri 'https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo11n.pt' -OutFile $modelPath
}
& $runtimePython (Join-Path $PSScriptRoot 'worker.py') --model $modelPath --check
if ($LASTEXITCODE -ne 0) { throw 'Model verification failed' }
Write-Output "Object detection is ready. Python runtime: $runtimePython"
