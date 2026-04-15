$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Project = $Root
$AppName = "reaction-box-psychopy-win"

# 1) Use existing project venv (.venv)
$VenvPath = Join-Path $Root ".venv"
if (-not (Test-Path $VenvPath)) {
    Write-Host "[!] 未找到 $VenvPath" -ForegroundColor Yellow
    Write-Host "    请先创建: python -m venv .venv; .\\.venv\\Scripts\\Activate.ps1; pip install -r packaging_requirements.txt"
    exit 1
}
& "$VenvPath/Scripts/Activate.ps1"
# ensure venv tools precede system tools
$env:PATH = "$VenvPath/Scripts;$env:PATH"
# Prefer official PyPI to avoid mirror SSL issues; allow override via env
if (-not $env:PIP_INDEX_URL) { $env:PIP_INDEX_URL = "https://pypi.org/simple" }

& "$VenvPath/Scripts/python.exe" -m pip install --upgrade pip
& "$VenvPath/Scripts/python.exe" -m pip install -r (Join-Path $Root "packaging_requirements.txt")

# 2) Clean previous build
Remove-Item -Recurse -Force (Join-Path $Root "build") -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force (Join-Path $Root "dist") -ErrorAction SilentlyContinue

# 3) Build (ONEDIR for better dependency loading with PsychoPy)
pyinstaller `
  --clean --noconfirm `
  --onedir --windowed `
  --name "$AppName" `
  --paths $Project `
  --collect-all psychopy `
  --collect-all pyglet `
  --collect-all pandas `
  --collect-all numpy `
  (Join-Path $Project "experiment_psychopy.py")

$DistPath = Join-Path $Root 'dist'
$ExePath = Join-Path $DistPath "$AppName\$AppName.exe"
Write-Host "Windows build finished: $ExePath"
