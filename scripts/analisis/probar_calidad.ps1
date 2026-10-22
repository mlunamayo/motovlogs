$fp = 'C:\Users\tinlu\Documents\StreamDeck\tools\ffmpeg\bin\ffprobe.exe'
foreach ($f in 'G:\Motovlog\2026-10-21\DJI\DJI_20261018102253_0002_D.MP4','G:\Motovlog\2026-10-21\st_002_s1397.mp4','G:\Motovlog\2026-10-21\TikTok_cine\cine_06_rumbo_v2.mp4') {
  "== $f"
  & $fp -v error -select_streams v:0 -show_entries stream=codec_name,width,height,r_frame_rate,bit_rate,pix_fmt,color_transfer -of compact $f
}
