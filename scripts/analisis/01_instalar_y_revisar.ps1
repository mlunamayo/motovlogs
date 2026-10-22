$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$tools = 'C:\Users\tinlu\Documents\StreamDeck\tools'
$ffdir = Join-Path $tools 'ffmpeg'
if (-not (Test-Path "$ffdir\bin\ffmpeg.exe")) {
  Write-Host 'Descargando ffmpeg...'
  $zip = Join-Path $env:TEMP 'ffmpeg.zip'
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile $zip -UseBasicParsing
  $tmp = Join-Path $env:TEMP 'ffmpeg_x'; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Archive $zip -DestinationPath $tmp -Force
  $inner = Get-ChildItem $tmp -Directory | Select-Object -First 1
  New-Item -ItemType Directory -Force -Path $ffdir | Out-Null
  Copy-Item "$($inner.FullName)\*" $ffdir -Recurse -Force
}
$ff = "$ffdir\bin\ffmpeg.exe"; $fp = "$ffdir\bin\ffprobe.exe"
& $ff -hide_banner -version | Select-Object -First 1
$src = 'G:\Motovlog\2026-10-21'
$out = Join-Path $src '_analisis\probe'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$vids = @(Get-ChildItem "$src\DJI" -Filter '*.MP4') + @(Get-ChildItem "$src\Insta360" -File | Where-Object { $_.Name -like 'VID_*' })
foreach ($v in $vids) {
  Write-Host "Revisando $($v.Name)"
  & $fp -v error -show_format -show_streams -of json $v.FullName | Out-File "$out\$($v.BaseName).json" -Encoding utf8
  & $ff -v error -y -ss 20 -i $v.FullName -frames:v 1 -vf "scale=640:-2" "$out\$($v.BaseName).jpg"
}
Write-Host 'Listo paso 1'
