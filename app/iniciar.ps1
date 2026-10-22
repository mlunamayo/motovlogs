$ErrorActionPreference = 'Stop'
Start-Process -FilePath "$PSScriptRoot\.venv\Scripts\pythonw.exe" -ArgumentList ('"' + $PSScriptRoot + '\desktop.py"') -WorkingDirectory $PSScriptRoot -WindowStyle Hidden
