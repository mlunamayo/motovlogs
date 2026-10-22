param(
  [string]$Plan,
  [string]$Src = 'G:\Motovlog\2026-10-21',          # carpeta de la grabacion (rutas relativas del plan salen de aqui)
  [string]$Salida = 'TikTok_cine',                     # subcarpeta de salida dentro de $Src
  [string]$FF = 'C:\Users\tinlu\Documents\StreamDeck\tools\ffmpeg\bin\ffmpeg.exe'
)
# Motor de render: lee un plan JSON y genera videos verticales 1080x1920 para TikTok
$ErrorActionPreference = 'Continue'
$ff = $FF
$src = $Src
$p = Get-Content $Plan -Raw -Encoding UTF8 | ConvertFrom-Json
$outDir = Join-Path $src $Salida
$work = Join-Path $src ('_analisis\render_' + $Salida)
New-Item -ItemType Directory -Force -Path $outDir, $work | Out-Null
$planDir = Split-Path $Plan -Parent
$TM = 'zscale=tin=arib-std-b67:min=bt2020nc:pin=bt2020:rin=tv:t=linear:npl=203,format=gbrpf32le,zscale=p=bt709,tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p,eq=saturation=1.25:gamma=1.1:contrast=1.04'
$inv = [Globalization.CultureInfo]::InvariantCulture

foreach ($o in $p.outputs) {
  if ($p.only -and ($p.only -notcontains $o.name)) { continue }
  Write-Host "=== $($o.name) ===" -ForegroundColor Cyan
  $partes = @()
  $i = 0
  foreach ($s in $o.segments) {
    $i++
    $part = Join-Path $work ('{0}_{1:D2}.mp4' -f $o.name, $i)
    $speed = if ($s.speed) { [double]$s.speed } else { 1.0 }
    $cx = if ($s.cx -ne $null) { [double]$s.cx } else { 0.5 }
    $vol = if ($s.vol -ne $null) { [double]$s.vol } else { 1.0 }
    $outDur = [double]$s.dur / $speed
    $pre = if ($s.hdr) { "$TM," } else { '' }
    if ($s.rot180) { $pre = $pre + 'hflip,vflip,' }
    $pts = if ($speed -ne 1.0) { 'setpts=PTS/' + $speed.ToString($inv) + ',' } else { '' }
    $cxs = $cx.ToString($inv)
    $post = ''
    if ($s.grade -eq 'cine') { $post = 'eq=contrast=1.08:saturation=0.8:gamma=0.96,colorbalance=rs=-0.06:gs=-0.01:bs=0.06:rh=0.06:gh=0.01:bh=-0.05,vignette=PI/5,' }
    if ($s.fadein) { $post = $post + 'fade=t=in:st=0:d=0.8,' }
    if ($s.fadeout) { $post = $post + 'fade=t=out:st=' + ([Math]::Max(0, $outDur - 1.8)).ToString($inv) + ':d=1.8,' }
    if ($s.layout -eq 'equi') {
      $yaw = if ($s.yaw -ne $null) { [double]$s.yaw } else { 0 }
      $pit = if ($s.pitch -ne $null) { [double]$s.pitch } else { -5 }
      $hf = if ($s.hfov) { [double]$s.hfov } else { 80 }
      $vfov = if ($s.vfov) { [double]$s.vfov } else { 112 }
      $vf = "[0:v]v360=input=equirect:output=flat:yaw=$($yaw.ToString($inv)):pitch=$($pit.ToString($inv)):h_fov=$($hf.ToString($inv)):v_fov=$($vfov.ToString($inv)):w=1080:h=1920:interp=lanczos,${pts}fps=30,${post}setsar=1,format=yuv420p[v]"
    } elseif ($s.layout -eq 'pano') {
      $yaw = if ($s.yaw -ne $null) { [double]$s.yaw } else { 0 }
      $pit = if ($s.pitch -ne $null) { [double]$s.pitch } else { 0 }
      $rol = if ($s.roll -ne $null) { [double]$s.roll } else { 90 }
      $hf = if ($s.hfov) { [double]$s.hfov } else { 100 }
      $vfov = if ($s.vfov) { [double]$s.vfov } else { 150 }
      $vf = "[0:v]v360=input=dfisheye:output=flat:ih_fov=195:iv_fov=195:yaw=$($yaw.ToString($inv)):pitch=$($pit.ToString($inv)):roll=$($rol.ToString($inv)):h_fov=$($hf.ToString($inv)):v_fov=$($vfov.ToString($inv)):w=1080:h=1920,fps=30,${pts}eq=saturation=1.1,${post}setsar=1,format=yuv420p[v]"
    } elseif ($s.layout -eq 'lens') {
      $half = if ($s.half) { [int]$s.half } else { 0 }
      $tr = if ($s.tr) { [int]$s.tr } else { 1 }
      $yaw = if ($s.yaw -ne $null) { [double]$s.yaw } else { 0 }
      $pit = if ($s.pitch -ne $null) { [double]$s.pitch } else { 0 }
      $rol = if ($s.roll -ne $null) { [double]$s.roll } else { 0 }
      $hf = if ($s.hfov) { [double]$s.hfov } else { 95 }
      $vfov = if ($s.vfov) { [double]$s.vfov } else { 140 }
      $vf = "[0:v]crop=iw/2:ih:(iw/2)*${half}:0,transpose=${tr},v360=input=fisheye:output=flat:ih_fov=195:iv_fov=195:yaw=$($yaw.ToString($inv)):pitch=$($pit.ToString($inv)):roll=$($rol.ToString($inv)):h_fov=$($hf.ToString($inv)):v_fov=$($vfov.ToString($inv)):w=1080:h=1920,fps=30,${pts}setsar=1,format=yuv420p[v]"
    } elseif ($s.layout -eq 'band') {
      $vf = "[0:v]${pre}${pts}fps=30,split[a][b];[a]scale=540:960:force_original_aspect_ratio=increase,crop=540:960,boxblur=20:2,scale=1080:1920,eq=brightness=-0.06[bg];[b]crop=ih*4/5:ih:(iw-ih*4/5)*${cxs}:0,scale=1080:1350:flags=lanczos[fg];[bg][fg]overlay=0:(H-h)/2,setsar=1,format=yuv420p[v]"
    } else {
      $vf = "[0:v]${pre}${pts}fps=30,crop=ih*9/16:ih:(iw-ih*9/16)*${cxs}:0,scale=1080:1920:flags=lanczos,unsharp=5:5:0.35:5:5:0,${post}setsar=1,format=yuv420p[v]"
    }
    $at = if ($speed -ne 1.0) { 'atempo=' + $speed.ToString($inv) + ',' } else { '' }
    $fo = [Math]::Max(0, $outDur - 0.2).ToString($inv)
    $af = "[0:a]aresample=48000,aformat=channel_layouts=stereo,${at}volume=$($vol.ToString($inv)),afade=t=in:d=0.15,afade=t=out:st=${fo}:d=0.2[a]"
    Write-Host ("  parte {0}: {1} desde {2}s, {3}s" -f $i, $s.file, $s.start, $s.dur)
    & $ff -v error -y -ss ([double]$s.start).ToString($inv) -t ([double]$s.dur).ToString($inv) -i $(if ($s.file -match '^[A-Za-z]:') { $s.file } else { Join-Path $src $s.file }) -filter_complex "$vf;$af" -map '[v]' -map '[a]' -c:v libx264 -preset medium -crf 11 -c:a aac -b:a 192k -ar 48000 $part
    $partes += $part
  }
  $lista = Join-Path $work "$($o.name)_lista.txt"
  ($partes | ForEach-Object { "file '" + ($_ -replace '\\', '/') + "'" }) | Out-File $lista -Encoding ascii
  $final = Join-Path $outDir "$($o.name).mp4"
  $vfFinal = 'null'
  if ($o.ass) {
    Copy-Item (Join-Path $planDir $o.ass) (Join-Path $work 'subs.ass') -Force
    $fd = Join-Path $work 'fonts'
    if (-not (Test-Path "$fd\segoeuil.ttf")) { New-Item -ItemType Directory -Force -Path $fd | Out-Null; Copy-Item 'C:\Windows\Fonts\ariblk.ttf', 'C:\Windows\Fonts\arialbd.ttf', 'C:\Windows\Fonts\segoeuil.ttf', 'C:\Windows\Fonts\segoeui.ttf' $fd -ErrorAction SilentlyContinue }
    $vfFinal = 'subtitles=subs.ass:fontsdir=fonts'
  }
  Push-Location $work
  & $ff -v error -y -f concat -safe 0 -i $lista -vf $vfFinal -c:v libx264 -preset slow -crf 15 -profile:v high -pix_fmt yuv420p -r 30 -c:a aac -b:a 192k -ar 48000 -movflags +faststart $final
  Pop-Location
  $f = Get-Item $final -ErrorAction SilentlyContinue
  if ($f) { Write-Host ("  LISTO: {0} ({1:N1} MB)" -f $f.Name, ($f.Length / 1MB)) -ForegroundColor Green }
  else { Write-Host '  ERROR: no se genero' -ForegroundColor Red }
  # fotogramas de control para revisar
  $chk = Join-Path $work "$($o.name)_check.jpg"
  & $ff -v error -y -i $final -vf 'fps=1/2,scale=216:384,tile=8x3' -frames:v 1 $chk
}
Write-Host 'Render terminado'
