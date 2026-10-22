$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Net.Http
$Host.UI.RawUI.WindowTitle = 'Subir borradores a TikTok'
$dir = 'C:\Users\tinlu\Documents\StreamDeck\video\tiktok'
$videos = 'G:\Motovlog\2026-10-21\TikTok'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

function Fin($msg) { Write-Host ''; if ($msg) { Write-Host "  $msg" -ForegroundColor Yellow }; Read-Host '  Presiona Enter para cerrar'; exit }

# ---------- Configuracion (la llenas tu, Claude no la ve) ----------
$cfgPath = Join-Path $dir 'config.txt'
if (-not (Test-Path $cfgPath)) {
  "client_key=`r`nclient_secret=`r`nredirect_uri=" | Out-File $cfgPath -Encoding ascii
}
$cfg = @{}
Get-Content $cfgPath | ForEach-Object { if ($_ -match '^\s*([a-z_]+)\s*=\s*(.*?)\s*$') { $cfg[$matches[1]] = $matches[2] } }
if (-not $cfg['client_key'] -or -not $cfg['client_secret'] -or -not $cfg['redirect_uri']) {
  Write-Host ''
  Write-Host '  Falta llenar config.txt (se abre en el Bloc de notas):' -ForegroundColor Cyan
  Write-Host '   client_key=    el Client Key del Sandbox (TikTok Developers)'
  Write-Host '   client_secret= el Client Secret NUEVO'
  Write-Host '   redirect_uri=  la Redirect URI que copiaste de Composio (la misma que pusiste en Login Kit)'
  Start-Process notepad.exe $cfgPath
  Fin 'Llena los 3 datos, guarda el archivo y vuelve a abrir Subir_TikTok.'
}

$http = [System.Net.Http.HttpClient]::new()
$http.Timeout = [TimeSpan]::FromMinutes(30)

function PostForm($url, $data) {
  $pairs = New-Object 'System.Collections.Generic.List[System.Collections.Generic.KeyValuePair[string,string]]'
  foreach ($k in $data.Keys) { $pairs.Add([System.Collections.Generic.KeyValuePair[string,string]]::new($k, [string]$data[$k])) }
  $content = [System.Net.Http.FormUrlEncodedContent]::new($pairs)
  $r = $http.PostAsync($url, $content).Result
  return ($r.Content.ReadAsStringAsync().Result | ConvertFrom-Json)
}
function PostJson($url, $token, $obj) {
  $req = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post, $url)
  $req.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $token)
  $req.Content = [System.Net.Http.StringContent]::new(($obj | ConvertTo-Json -Depth 5 -Compress), [Text.Encoding]::UTF8, 'application/json')
  $r = $http.SendAsync($req).Result
  return ($r.Content.ReadAsStringAsync().Result | ConvertFrom-Json)
}

# ---------- Token ----------
$tokPath = Join-Path $dir 'token.json'
function SaveTok($t) {
  @{ access_token = $t.access_token; refresh_token = $t.refresh_token; expires = (Get-Date).AddSeconds([int]$t.expires_in - 120).ToString('o') } |
    ConvertTo-Json | Out-File $tokPath -Encoding utf8
  return (Get-Content $tokPath -Raw | ConvertFrom-Json)
}
$tok = $null
if (Test-Path $tokPath) { $tok = Get-Content $tokPath -Raw | ConvertFrom-Json }
if ($tok -and [datetime]::Parse($tok.expires, $null, 'RoundtripKind') -lt (Get-Date)) {
  $t = PostForm 'https://open.tiktokapis.com/v2/oauth/token/' @{ client_key = $cfg['client_key']; client_secret = $cfg['client_secret']; grant_type = 'refresh_token'; refresh_token = $tok.refresh_token }
  if ($t.access_token) { $tok = SaveTok $t } else { $tok = $null }
}
if (-not $tok) {
  $state = [guid]::NewGuid().ToString('N')
  $auth = 'https://www.tiktok.com/v2/auth/authorize/?client_key=' + [uri]::EscapeDataString($cfg['client_key']) +
          '&scope=user.info.basic,video.upload&response_type=code&redirect_uri=' + [uri]::EscapeDataString($cfg['redirect_uri']) + '&state=' + $state
  Write-Host ''
  Write-Host '  1) Se abre TikTok en el navegador: inicia sesion con mluna_1709 y acepta.' -ForegroundColor Cyan
  Write-Host '  2) Te va a llevar a una pagina de Composio (puede mostrar un error, no importa).'
  Write-Host '  3) Copia la direccion COMPLETA de la barra del navegador y pegala aqui.'
  Start-Process $auth
  $back = Read-Host '  Direccion'
  if ($back -notmatch '[?&]code=([^&]+)') { Fin 'No encontre el codigo en esa direccion. Vuelve a intentarlo.' }
  $code = [uri]::UnescapeDataString($matches[1])
  $t = PostForm 'https://open.tiktokapis.com/v2/oauth/token/' @{ client_key = $cfg['client_key']; client_secret = $cfg['client_secret']; code = $code; grant_type = 'authorization_code'; redirect_uri = $cfg['redirect_uri'] }
  if (-not $t.access_token) { Write-Host ($t | ConvertTo-Json -Compress); Fin 'TikTok no entrego el acceso. Manda una foto de este mensaje a Claude.' }
  $tok = SaveTok $t
  Write-Host '  Cuenta conectada.' -ForegroundColor Green
}

# ---------- Videos pendientes (orden pensado para retencion) ----------
$orden = '25','14','02','23','31','33','05','01','03','10','13','35','20','06','29','30','32','36','37','38','28','27','34','08','09','11','12','15','16','17','18','19','21','22','24','07','04','26','39'
$hechosPath = Join-Path $dir 'subidos.txt'
$hechos = @(); if (Test-Path $hechosPath) { $hechos = @(Get-Content $hechosPath) }
$pend = @(foreach ($n in $orden) {
  $f = Get-ChildItem $videos -Filter "${n}_*.mp4" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($f -and ($hechos -notcontains $f.Name)) { $f }
})
Write-Host ''
Write-Host "  Subidos: $($hechos.Count)   Pendientes: $($pend.Count)" -ForegroundColor Cyan
if ($pend.Count -eq 0) { Fin 'No queda nada por subir.' }
$r = Read-Host '  Cuantos subir ahora? (Enter = 1, TikTok permite unos 5 por dia)'
$cant = 1; if ($r -match '^\d+$') { $cant = [int]$r }

foreach ($f in ($pend | Select-Object -First $cant)) {
  $size = [int64]$f.Length
  if ($size -le 64000000) { $chunk = $size; $count = 1 } else { $chunk = [int64]10000000; $count = [int][math]::Floor($size / $chunk) }
  Write-Host ''
  Write-Host ("  {0}  ({1:N1} MB)" -f $f.Name, ($size / 1MB))
  $init = PostJson 'https://open.tiktokapis.com/v2/post/publish/inbox/video/init/' $tok.access_token @{ source_info = @{ source = 'FILE_UPLOAD'; video_size = $size; chunk_size = $chunk; total_chunk_count = $count } }
  if ($init.error.code -ne 'ok') {
    Write-Host ("  ERROR TikTok: {0} - {1}" -f $init.error.code, $init.error.message) -ForegroundColor Red
    if ($init.error.code -match 'too_many|spam|rate') { Write-Host '  Llegaste al limite del dia. Vuelve a abrir esto manana.' -ForegroundColor Yellow }
    break
  }
  $url = $init.data.upload_url
  $fs = [IO.File]::OpenRead($f.FullName)
  $ok = $true
  for ($i = 0; $i -lt $count; $i++) {
    $start = [int64]$i * $chunk
    $len = if ($i -eq $count - 1) { $size - $start } else { $chunk }
    $buf = New-Object byte[] ([int]$len)
    $read = 0; while ($read -lt $len) { $read += $fs.Read($buf, $read, [int]$len - $read) }
    $c = [System.Net.Http.ByteArrayContent]::new($buf)
    $c.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::new('video/mp4')
    $c.Headers.ContentRange = [System.Net.Http.Headers.ContentRangeHeaderValue]::new($start, $start + $len - 1, $size)
    $resp = $null
    for ($try = 1; $try -le 4; $try++) {
      $c = [System.Net.Http.ByteArrayContent]::new($buf)
      $c.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::new('video/mp4')
      $c.Headers.ContentRange = [System.Net.Http.Headers.ContentRangeHeaderValue]::new($start, $start + $len - 1, $size)
      $resp = $http.PutAsync($url, $c).Result
      if ($resp.IsSuccessStatusCode) { break }
      Write-Host "    TikTok respondio $([int]$resp.StatusCode), reintento $try de 3 en 10 s..." -ForegroundColor Yellow
      Start-Sleep -Seconds 10
    }
    if (-not $resp.IsSuccessStatusCode) { Write-Host "  ERROR subiendo parte $($i+1): $([int]$resp.StatusCode)" -ForegroundColor Red; $ok = $false; break }
    Write-Host ("    parte {0}/{1} enviada" -f ($i + 1), $count)
  }
  $fs.Close()
  if (-not $ok) { break }
  $estado = ''
  for ($k = 0; $k -lt 30; $k++) {
    Start-Sleep -Seconds 4
    $s = PostJson 'https://open.tiktokapis.com/v2/post/publish/status/fetch/' $tok.access_token @{ publish_id = $init.data.publish_id }
    $estado = $s.data.status
    if ($estado -in 'SEND_TO_USER_INBOX', 'PUBLISH_COMPLETE', 'FAILED') { break }
  }
  if ($estado -eq 'FAILED') { Write-Host "  TikTok rechazo el video: $($s.data.fail_reason)" -ForegroundColor Red; break }
  Add-Content $hechosPath $f.Name
  Write-Host "  LISTO: enviado a tus borradores/notificaciones de TikTok ($estado)" -ForegroundColor Green
}
Fin 'En la app de TikTok revisa la notificacion de "borrador listo", pega la descripcion y publica.'
