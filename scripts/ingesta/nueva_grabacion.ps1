$Host.UI.RawUI.WindowTitle = 'Grabar - copiando videos'
$root = 'G:\Motovlog'
New-Item -ItemType Directory -Force -Path $root | Out-Null
$dest = Join-Path $root (Get-Date -Format 'yyyy-MM-dd')
foreach ($s in 'Canon','Insta360','DJI') { New-Item -ItemType Directory -Force -Path (Join-Path $dest $s) | Out-Null }
Write-Host ''
Write-Host "  Destino: $dest" -ForegroundColor Cyan
Write-Host '  Buscando camaras...'
Write-Host ''

function GB($b) { '{0:N2} GB' -f ($b / 1GB) }

# ---------- 1) Buscar lo que hay que copiar ----------
$cola = New-Object System.Collections.ArrayList
$tarjetas = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
foreach ($d in $tarjetas) {
  $dcim = Join-Path ($d.DeviceID + '\') 'DCIM'
  if (-not (Test-Path $dcim)) { continue }
  foreach ($f in Get-ChildItem $dcim -Directory) {
    if ($f.Name -eq 'CANONMSC') { continue }
    $arch = @(Get-ChildItem $f.FullName -File -Recurse -ErrorAction SilentlyContinue)
    if ($f.Name -match 'CANON') { $cam = 'Canon' }
    elseif ($f.Name -match 'DJI' -or ($arch | Where-Object { $_.Name -like 'DJI_*' })) { $cam = 'DJI' }
    elseif ($f.Name -match '^Camera\d+' -or ($arch | Where-Object { $_.Extension -in '.insv','.insp' })) { $cam = 'Insta360' }
    else { $cam = 'Otros' }
    $carpeta = Join-Path $dest $cam
    foreach ($a in $arch) {
      $rel = $a.FullName.Substring($f.FullName.Length).TrimStart('\')
      $target = Join-Path $carpeta $rel
      if ((Test-Path $target) -and (Get-Item $target).Length -eq $a.Length) { continue }
      [void]$cola.Add([pscustomobject]@{ Cam = $cam; Src = $a.FullName; Dir = (Split-Path $target -Parent); Name = $a.Name; Size = $a.Length })
    }
  }
}

# Camaras por USB sin letra (MTP), por ejemplo la Canon
$shell = New-Object -ComObject Shell.Application
$mtp = New-Object System.Collections.ArrayList
foreach ($dev in $shell.NameSpace(17).Items()) {
  if ($dev.IsFileSystem) { continue }
  if ($dev.Name -match 'Canon|EOS') { $cam = 'Canon' }
  elseif ($dev.Name -match 'DJI|Osmo') { $cam = 'DJI' }
  elseif ($dev.Name -match 'Insta') { $cam = 'Insta360' }
  else { continue }
  foreach ($storage in $dev.GetFolder.Items()) {
    $dcim = $storage.GetFolder.Items() | Where-Object { $_.Name -eq 'DCIM' } | Select-Object -First 1
    if (-not $dcim) { continue }
    foreach ($sub in $dcim.GetFolder.Items()) {
      if (-not $sub.IsFolder -or $sub.Name -eq 'CANONMSC') { continue }
      foreach ($x in $sub.GetFolder.Items()) {
        if ($x.IsFolder) { continue }
        $target = Join-Path (Join-Path $dest $cam) $x.Name
        if (Test-Path $target) { continue }
        [void]$mtp.Add([pscustomobject]@{ Cam = $cam; Item = $x; Dir = (Join-Path $dest $cam); Name = $x.Name; Size = [int64]$x.Size })
      }
    }
  }
}

$todo = @($cola) + @($mtp)
if ($todo.Count -eq 0) {
  Write-Host '  No hay nada nuevo para copiar (o no hay camaras conectadas).' -ForegroundColor Yellow
  Write-Host ''
  Read-Host '  Presiona Enter para cerrar'
  exit
}
$totalBytes = ($todo | Measure-Object Size -Sum).Sum
Write-Host "  Archivos por copiar: $($todo.Count)   Total: $(GB $totalBytes)" -ForegroundColor Cyan
foreach ($g in $todo | Group-Object Cam) {
  Write-Host ("    {0,-9} {1,3} archivos  {2}" -f $g.Name, $g.Count, (GB (($g.Group | Measure-Object Size -Sum).Sum)))
}
Write-Host ''

# ---------- 2) Copiar mostrando el progreso ----------
$script:hecho = 0; $script:n = 0; $inicio = Get-Date; $errores = 0
function Avance($nombre, $extra) {
  $va = $script:hecho + $extra
  $pct = [int]($va * 100 / $totalBytes)
  $seg = ((Get-Date) - $inicio).TotalSeconds
  $vel = if ($seg -gt 2) { $va / $seg } else { 0 }
  $resta = if ($vel -gt 0) { [TimeSpan]::FromSeconds([Math]::Max(0, ($totalBytes - $va) / $vel)).ToString('hh\:mm\:ss') } else { '...' }
  Write-Progress -Activity "Copiando $($script:n) de $($todo.Count)  -  $(GB $va) de $(GB $totalBytes)" `
    -Status ("{0}%   {1:N0} MB/s   falta aprox. {2}" -f $pct, ($vel / 1MB), $resta) -CurrentOperation $nombre -PercentComplete ([Math]::Min($pct, 100))
}

foreach ($t in $cola) {
  $script:n++
  Write-Host ("  [{0}/{1}] {2,-9} {3}  ({4})" -f $script:n, $todo.Count, $t.Cam, $t.Name, (GB $t.Size))
  New-Item -ItemType Directory -Force -Path $t.Dir | Out-Null
  $destFile = Join-Path $t.Dir $t.Name
  $tmp = "$destFile.copiando"
  try {
    $in = [IO.File]::OpenRead($t.Src)
    $out = [IO.File]::Create($tmp)
    $buf = New-Object byte[] (8MB)
    $copiado = 0; $ultimo = Get-Date
    while (($r = $in.Read($buf, 0, $buf.Length)) -gt 0) {
      $out.Write($buf, 0, $r); $copiado += $r
      if (((Get-Date) - $ultimo).TotalMilliseconds -gt 500) { Avance $t.Name $copiado; $ultimo = Get-Date }
    }
    $out.Close(); $in.Close()
    if (Test-Path $destFile) { Remove-Item $destFile -Force }
    Move-Item $tmp $destFile
    $src = Get-Item $t.Src
    $nuevo = Get-Item $destFile
    $nuevo.CreationTime = $src.CreationTime
    $nuevo.LastWriteTime = $src.LastWriteTime
  } catch {
    if ($out) { $out.Close() }; if ($in) { $in.Close() }
    if (Test-Path $tmp) { Remove-Item $tmp -Force }
    $errores++; Write-Host "        ERROR: $($_.Exception.Message)" -ForegroundColor Red
  }
  $out = $null; $in = $null
  $script:hecho += $t.Size
  Avance $t.Name 0
}

foreach ($t in $mtp) {
  $script:n++
  Write-Host ("  [{0}/{1}] {2,-9} {3}  ({4})" -f $script:n, $todo.Count, $t.Cam, $t.Name, (GB $t.Size))
  $target = Join-Path $t.Dir $t.Name
  $shell.NameSpace($t.Dir).CopyHere($t.Item, 16 + 1024)
  $last = -1; $stable = 0; $w = 0
  while ($w -lt 7200) {
    Start-Sleep -Milliseconds 700; $w++
    if (Test-Path $target) {
      $size = (Get-Item $target).Length
      Avance $t.Name $size
      if ($size -gt 0 -and $size -eq $last) { $stable++ } else { $stable = 0 }
      $last = $size
      if ($stable -ge 4) { break }
    }
  }
  $script:hecho += $t.Size
}

Write-Progress -Activity 'Copiando' -Completed
$min = [int]((Get-Date) - $inicio).TotalMinutes
Write-Host ''
if ($errores) { Write-Host "  Terminado con $errores errores. Vuelve a presionar Grabar para reintentar." -ForegroundColor Red }
else { Write-Host "  LISTO: $($todo.Count) archivos, $(GB $totalBytes) en $min min. Ya puedes desconectar las camaras." -ForegroundColor Green }
Start-Process explorer.exe $dest
Write-Host ''
Read-Host '  Presiona Enter para cerrar'
