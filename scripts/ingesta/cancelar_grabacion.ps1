$n = 0
Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -like '*nueva_grabacion*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue; $n++ }
Get-Process robocopy -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue; $n++ }
Start-Sleep -Milliseconds 800
foreach ($r in 'G:\Motovlog','E:\Motovlog') {
  if (Test-Path $r) { Get-ChildItem $r -Recurse -File -Filter '*.copiando' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }
}
$msg = if ($n) { 'Transferencia cancelada. Las camaras no se tocaron; presiona Grabar para continuar despues.' } else { 'No habia ninguna transferencia corriendo.' }
(New-Object -ComObject WScript.Shell).Popup($msg, 4, 'Grabar', 64) | Out-Null
