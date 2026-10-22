$ErrorActionPreference = 'Stop'
$appDir = $PSScriptRoot
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) { throw 'Instala Python 3.11 o superior desde https://www.python.org/downloads/windows/ y activa Add Python to PATH. Después repite este comando.' }
& $pythonCmd.Source -c "import sys; assert sys.version_info >= (3,11), 'Se necesita Python 3.11+'"
if ($LASTEXITCODE -ne 0) { throw 'Se necesita Python 3.11 o superior.' }
if (-not (Test-Path "$appDir\.venv\Scripts\python.exe")) { & $pythonCmd.Source -m venv "$appDir\.venv" }
$py = "$appDir\.venv\Scripts\python.exe"
& $py -m pip install -r "$appDir\requirements.txt"
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron instalar las dependencias.' }
if (-not (Test-Path "$appDir\config.json")) {
    $cfg = Get-Content "$appDir\config.ejemplo.json" -Raw | ConvertFrom-Json
    $cfg.ffmpeg = Join-Path $env:USERPROFILE 'Documents\StreamDeck\tools\ffmpeg\bin\ffmpeg.exe'
    $cfg.cola = Join-Path $env:USERPROFILE 'Documents\StreamDeck\video\cola'
    $cfg | ConvertTo-Json | Set-Content "$appDir\config.json" -Encoding UTF8
}
$cfg = Get-Content "$appDir\config.json" -Raw | ConvertFrom-Json
if (-not (Test-Path -LiteralPath $cfg.ffmpeg) -or -not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $cfg.ffmpeg) 'ffprobe.exe'))) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $stage = Join-Path $env:TEMP ('motovlogs-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage | Out-Null
    Invoke-WebRequest 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile "$stage\ffmpeg.zip" -UseBasicParsing
    Expand-Archive "$stage\ffmpeg.zip" -DestinationPath "$stage\extraido"
    $inner = Get-ChildItem "$stage\extraido" -Directory | Select-Object -First 1
    $bin = Split-Path -Parent $cfg.ffmpeg
    New-Item -ItemType Directory -Force -Path $bin | Out-Null
    Copy-Item "$($inner.FullName)\bin\ffmpeg.exe" -Destination $cfg.ffmpeg -Force
    Copy-Item "$($inner.FullName)\bin\ffprobe.exe" -Destination (Join-Path $bin 'ffprobe.exe') -Force
}
New-Item -ItemType Directory -Force -Path "$appDir\datos", $cfg.cola | Out-Null
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Motovlogs.lnk'))
$shortcut.TargetPath = (Get-Command powershell.exe).Source
$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $appDir + '\iniciar.ps1"'
$shortcut.WorkingDirectory = $appDir
$shortcut.Description = 'Motovlogs: cámaras, edición y revisión local'
$shortcut.Save()
Write-Host 'Instalación terminada. Abre Motovlogs desde el escritorio.'
