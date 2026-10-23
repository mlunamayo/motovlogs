param([ValidateSet('abrir','copiar','cancelar','analizar','estado')][string]$Accion = 'abrir',
      [string]$App = "$env:USERPROFILE\Documents\motovlogs\app")
# Botones del Stream Deck para la app Motovlogs. Hablan con la app local (127.0.0.1:8765).
$base = 'http://127.0.0.1:8765'
$sh = New-Object -ComObject WScript.Shell
function Aviso($t, $seg = 4) { $sh.Popup($t, $seg, 'Motovlogs', 64) | Out-Null }
function Vivo { try { Invoke-RestMethod "$base/api/jobs" -TimeoutSec 2 | Out-Null; $true } catch { $false } }
function Post($ruta, $cuerpo = @{}) { Invoke-RestMethod "$base$ruta" -Method Post -ContentType 'application/json' -Body ($cuerpo | ConvertTo-Json -Compress) -TimeoutSec 10 }
function Asegurar {
  if (Vivo) { return $true }
  Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$App\iniciar.ps1`"" -WindowStyle Hidden
  for ($i = 0; $i -lt 30; $i++) { Start-Sleep -Milliseconds 700; if (Vivo) { return $true } }
  Aviso 'No pude abrir Motovlogs. Ábrela desde el escritorio.' 6; return $false
}
if (-not (Asegurar)) { exit 1 }
try {
  switch ($Accion) {
    'abrir'    { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$App\iniciar.ps1`"" -WindowStyle Hidden }
    'copiar'   { Post '/api/copy' | Out-Null; Aviso 'Copiando lo nuevo de las cámaras. Mira el avance en Motovlogs o con el botón Estado.' }
    'cancelar' {
      $j = @(Invoke-RestMethod "$base/api/jobs") | Where-Object { $_.label -eq 'Copiar' -and $_.state -in 'cola','corriendo' }
      if ($j) { $j | ForEach-Object { Post "/api/cancel/$($_.id)" | Out-Null }; Aviso 'Copia cancelada. Las cámaras no se tocaron.' }
      else { Aviso 'No hay ninguna copia en marcha.' }
    }
    'analizar' {
      $r = @(Invoke-RestMethod "$base/api/recordings") | Sort-Object date | Select-Object -Last 1
      if (-not $r) { Aviso 'No hay grabaciones todavía.'; break }
      Post '/api/analyze' @{ src = $r.path } | Out-Null; Aviso "Analizando la grabación del $($r.date)."
    }
    'estado'   {
      $js = @(Invoke-RestMethod "$base/api/jobs")
      $act = $js | Where-Object { $_.state -in 'cola','corriendo' }
      if (-not $act) { $u = $js | Select-Object -Last 1; Aviso ($(if ($u) { "Nada en marcha. Último: $($u.label) ($($u.state))." } else { 'Nada en marcha.' })) }
      else { Aviso (($act | ForEach-Object { $p = $_.progress; "$($_.label): $($_.state)" + $(if ($p.percent) { " $($p.percent)% · $($p.file)" } elseif ($p.stage) { " · $($p.stage)" } else { '' }) }) -join "`n") 6 }
    }
  }
} catch { Aviso ('Motovlogs respondió con un error: ' + $_.Exception.Message) 6 }
