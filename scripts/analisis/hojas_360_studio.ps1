$d0 = 'G:\Motovlog\2026-10-21'
for ($i = 0; $i -lt 240; $i++) {
  $f = @(Get-ChildItem $d0 -Filter 'st_*.mp4')
  $sz = ($f | Measure-Object Length -Sum).Sum
  if ($f.Count -ge 7 -and $sz -eq $prev) { break }
  $prev = $sz; Start-Sleep -Seconds 15
}
Start-Sleep -Seconds 20
$ff = 'C:\Users\tinlu\Documents\StreamDeck\tools\ffmpeg\bin\ffmpeg.exe'
$d = 'G:\Motovlog\2026-10-21'
$out = Join-Path $d '_analisis\studio'
New-Item -ItemType Directory -Force -Path $out | Out-Null
Get-ChildItem $d -Filter 'st_*.mp4' | ForEach-Object {
  $n = $_.BaseName
  foreach ($y in 0, 180) {
    & $ff -v error -y -i $_.FullName -vf "fps=1/3,v360=input=equirect:output=flat:yaw=${y}:pitch=-5:h_fov=80:v_fov=112:w=180:h=320,tile=10x3" -frames:v 1 (Join-Path $out "${n}_y${y}.jpg")
  }
  "$n listo"
}
