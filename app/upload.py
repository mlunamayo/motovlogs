"""Adaptador inbox de los scripts existentes. Solo se invoca tras confirmar en la UI.
No incluir respuestas de TikTok, URLs de subida ni credenciales en errores o logs.
"""
import json
import time
import urllib.request
import urllib.parse
from datetime import datetime, timedelta
from pathlib import Path

def send(video, directory):
    directory = Path(directory)
    cfgpath, tokpath = directory/'config.txt', directory/'token.json'
    if not cfgpath.exists() or not tokpath.exists():
        raise ValueError('Martin debe configurar client_key, client_secret y redirect_uri y conectar su cuenta con el script existente, fuera de esta app. No pegues las llaves aquí.')
    def post(url, body, token=None):
        encoded = json.dumps(body).encode() if token else urllib.parse.urlencode(body).encode()
        headers = {'Content-Type':'application/json' if token else 'application/x-www-form-urlencoded'}
        if token:
            headers['Authorization'] = 'Bearer '+token
        with urllib.request.urlopen(urllib.request.Request(url, data=encoded, headers=headers), timeout=120) as response:
            return json.load(response)
    try:
        cfg = dict(line.split('=',1) for line in cfgpath.read_text(encoding='utf-8-sig').splitlines() if '=' in line)
        tok = json.loads(tokpath.read_text(encoding='utf-8-sig'))
        expiry = datetime.fromisoformat(tok['expires'])
        now = datetime.now().astimezone() if expiry.tzinfo else datetime.now()
        if expiry < now:
            fresh = post('https://open.tiktokapis.com/v2/oauth/token/', dict(client_key=cfg['client_key'],client_secret=cfg['client_secret'],grant_type='refresh_token',refresh_token=tok['refresh_token']))
            tok = dict(access_token=fresh['access_token'],refresh_token=fresh['refresh_token'],expires=(datetime.now().astimezone()+timedelta(seconds=int(fresh['expires_in'])-120)).isoformat())
            tokpath.write_text(json.dumps(tok),encoding='utf-8')
        size = video.stat().st_size
        chunk = size if size <= 64000000 else 10000000
        count = max(1,size//chunk)
        init = post('https://open.tiktokapis.com/v2/post/publish/inbox/video/init/',dict(source_info=dict(source='FILE_UPLOAD',video_size=size,chunk_size=chunk,total_chunk_count=count)),tok['access_token'])
        if init['error']['code'] != 'ok':
            raise RuntimeError()
        with video.open('rb') as source:
            for i in range(count):
                start = i*chunk
                payload = source.read(size-start if i==count-1 else chunk)
                for retry in range(4):
                    try:
                        req = urllib.request.Request(init['data']['upload_url'], data=payload, method='PUT',headers={'Content-Type':'video/mp4','Content-Range':f'bytes {start}-{start+len(payload)-1}/{size}'})
                        with urllib.request.urlopen(req, timeout=1800):
                            pass
                        break
                    except Exception:
                        if retry == 3:
                            raise RuntimeError() from None
                        time.sleep(10)
        for _ in range(30):
            time.sleep(4)
            state = post('https://open.tiktokapis.com/v2/post/publish/status/fetch/',dict(publish_id=init['data']['publish_id']),tok['access_token'])['data']['status']
            if state in {'SEND_TO_USER_INBOX','PUBLISH_COMPLETE'}:
                return 'Enviado a las notificaciones de TikTok; Martin termina la publicación en el teléfono.'
            if state == 'FAILED':
                break
        raise RuntimeError()
    except Exception:
        raise ValueError('TikTok no confirmó el envío. Revisa la cuenta en el teléfono; no reintentes a ciegas. Puede haberse alcanzado el límite diario de unos 5 borradores.') from None
