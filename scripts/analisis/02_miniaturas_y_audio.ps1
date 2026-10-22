$ff = 'C:\Users\tinlu\Documents\StreamDeck\tools\ffmpeg\bin\ffmpeg.exe'
& $ff -hide_banner -filters 2>$null | Select-String -Pattern 'whisper|zscale|tonemap|v360|libplacebo' | ForEach-Object { "FILTRO: $_" }
$src = 'G:\Motovlog\2026-10-21'
$an = Join-Path $src '_analisis'
$sh = Join-Path $an 'hojas'; $au = Join-Path $an 'audio'
New-Item -ItemType Directory -Force -Path $sh, $au | Out-Null
$lista = @()
$lista += Get-ChildItem "$src\DJI" -Filter 'DJI_202610*.MP4' | ForEach-Object { @{ f = $_; step = 10; w = 320 } }
$lista += Get-ChildItem "$src\Insta360" -Filter 'VID_20260304_*.mp4' | ForEach-Object { @{ f = $_; step = 10; w = 320 } }
$lista += Get-ChildItem "$src\Insta360" -Filter 'VID_20260205_*.insv' | ForEach-Object { @{ f = $_; step = 20; w = 480 } }
foreach ($x in $lista) {
  $v = $x.f
  Write-Host "Miniaturas $($v.Name)"
  & $ff -v error -y -skip_frame nokey -i $v.FullName -vf "fps=1/$($x.step),scale=$($x.w):-2,tile=6x5" -q:v 6 "$sh\$($v.BaseName)_%02d.jpg"
  Write-Host "Audio $($v.Name)"
  & $ff -v error -y -i $v.FullName -vn -ac 1 -ar 16000 -c:a libopus -b:a 20k "$au\$($v.BaseName).ogg"
}
Write-Host 'Listo paso 2'
