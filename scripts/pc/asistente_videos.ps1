$Host.UI.RawUI.WindowTitle = 'Asistente de videos (Claude) - cierra esta ventana para detenerlo'
$base = 'C:\Users\tinlu\Documents\StreamDeck\video'
$cola = Join-Path $base 'cola'; $hechos = Join-Path $base 'hechos'; $logs = Join-Path $base 'logs'
New-Item -ItemType Directory -Force -Path $cola, $hechos, $logs | Out-Null
Write-Host ''
Write-Host '  Asistente de videos activo.' -ForegroundColor Cyan
Write-Host '  Solo ejecuta los pasos que Claude deja en:' $cola
Write-Host '  Para detenerlo, cierra esta ventana.'
Write-Host ''
while ($true) {
  $s = Get-ChildItem $cola -Filter '*.ps1' -File -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1
  if (-not $s) { Start-Sleep -Seconds 3; continue }
  Start-Sleep -Seconds 1
  $dst = Join-Path $hechos $s.Name
  Move-Item $s.FullName $dst -Force
  $log = Join-Path $logs ($s.BaseName + '.log')
  Write-Host "  $(Get-Date -Format HH:mm:ss)  Ejecutando $($s.Name) ..." -ForegroundColor Yellow
  & powershell -NoProfile -ExecutionPolicy Bypass -File $dst *>&1 | Tee-Object -FilePath $log
  "##TERMINADO $(Get-Date -Format s)" | Out-File $log -Append -Encoding utf8
  Write-Host "  $(Get-Date -Format HH:mm:ss)  Terminado $($s.Name)" -ForegroundColor Green
  Write-Host ''
}
