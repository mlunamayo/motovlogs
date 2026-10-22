$ErrorActionPreference = 'Stop'
try {
    $response = Invoke-WebRequest 'http://127.0.0.1:8765/' -UseBasicParsing -TimeoutSec 2
    if ($response.StatusCode -eq 200 -and $response.Content -match '<title>Motovlogs</title>') {
        Start-Process 'http://127.0.0.1:8765'
        exit
    }
} catch { }
& "$PSScriptRoot\.venv\Scripts\python.exe" "$PSScriptRoot\server.py" --open
