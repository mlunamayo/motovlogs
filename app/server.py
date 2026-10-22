import csv
import importlib.util
import json
import os
import shutil
import subprocess
import time
import webbrowser
from datetime import date
from pathlib import Path
from flask import Flask, jsonify, request, render_template, send_file
from core import MEDIA, Jobs, classify, inside, media_path, safe_name, unique, validate_plan, hashtags, threshold

BASE = Path(__file__).resolve().parent
REPO = BASE.parent
STYLES = dict(gancho='cortos_gancho', cine='serie_cine', curvas='curvas_velocidad', rampa='rampa_velocidad', studio='equi_360_studio')

def create_app(config=None, data=None):
    app = Flask(__name__)
    cfg = config or json.loads((BASE / ('config.json' if (BASE / 'config.json').exists() else 'config.ejemplo.json')).read_text(encoding='utf-8-sig'))
    data = Path(data or BASE / 'datos')
    data.mkdir(parents=True, exist_ok=True)
    jobs = Jobs(data / 'logs')
    app.extensions['jobs'] = jobs
    roots = [Path(cfg['destino']), Path(cfg['red360'])]
    ff = cfg['ffmpeg']
    fp = str(Path(ff).with_name('ffprobe.exe' if os.name == 'nt' else 'ffprobe'))
    app.config['MAX_CONTENT_LENGTH'] = 2 * 1024 * 1024

    @app.before_request
    def local_only():
        if request.host.split(':')[0] not in {'127.0.0.1', 'localhost'}:
            return jsonify(error='Solo acceso local'), 403
        origin = request.headers.get('Origin')
        if origin and origin != request.host_url.rstrip('/'):
            return jsonify(error='Origen no permitido'), 403
        if request.method == 'POST' and not request.is_json:
            return jsonify(error='Se requiere JSON'), 415

    @app.errorhandler(ValueError)
    @app.errorhandler(KeyError)
    def invalid(exc):
        return jsonify(error=str(exc)), 400

    def srcpath(value):
        p = Path(value).resolve()
        root = Path(cfg['destino']).resolve()
        if p.parent != root or not p.is_dir() or not __import__('re').fullmatch(r'\d{4}-\d{2}-\d{2}', p.name):
            raise ValueError('Elige una carpeta de grabación por fecha')
        return p

    def run(job, args):
        with subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding='utf-8', errors='replace') as proc:
            for line in proc.stdout:
                jobs.log(job, line.rstrip())
                if 'parte ' in line or 'LISTO:' in line:
                    job['progress'] = dict(stage=line.strip())
            if proc.wait():
                raise ValueError('El proceso falló. Consulta el log')

    def probe(p):
        proc = subprocess.run([fp, '-v', 'error', '-show_format', '-show_streams', '-of', 'json', str(p)], capture_output=True, text=True, timeout=60)
        if proc.returncode:
            raise ValueError('ffprobe no pudo revisar el archivo')
        result = json.loads(proc.stdout)
        v = next((s for s in result['streams'] if s['codec_type'] == 'video'), {})
        rate = v.get('avg_frame_rate', '0/1').split('/')
        return dict(width=v.get('width'), height=v.get('height'), codec=v.get('codec_name'), pix_fmt=v.get('pix_fmt'), fps=float(rate[0])/max(float(rate[-1]), 1), hdr=v.get('color_transfer') in {'arib-std-b67', 'smpte2084'}, duration=float(result.get('format', {}).get('duration', 0)), mb=p.stat().st_size/1048576)

    def scan():
        if os.name != 'nt':
            return []
        import pythoncom
        import win32com.client
        pythoncom.CoInitialize()
        rows = []
        dest = Path(cfg['destino']) / date.today().isoformat()
        for disk in win32com.client.GetObject('winmgmts:').ExecQuery('SELECT DeviceID FROM Win32_LogicalDisk WHERE DriveType=2'):
            dcim = Path(disk.DeviceID + '\\') / 'DCIM'
            if not dcim.exists():
                continue
            for folder in dcim.iterdir():
                if not folder.is_dir():
                    continue
                files = [p for p in folder.rglob('*') if p.is_file() and p.suffix.lower() in MEDIA]
                cam = classify(folder.name, [p.name for p in files])
                if not cam:
                    continue
                for p in files:
                    target = dest / cam / p.relative_to(folder)
                    if not target.exists() or target.stat().st_size != p.stat().st_size:
                        rows.append(dict(cam=cam, source=str(p), target=str(target), size=p.stat().st_size))
        shell = win32com.client.Dispatch('Shell.Application')
        def walk(folder, prefix=()):
            for item in folder.Items():
                if item.Name.upper() == 'CANONMSC':
                    continue
                if item.IsFolder:
                    yield from walk(item.GetFolder, prefix + (item.Name,))
                elif Path(item.Name).suffix.lower() in MEDIA:
                    yield item, prefix
        for dev in shell.NameSpace(17).Items():
            if dev.IsFileSystem or classify(dev.Name) == 'Otros':
                continue
            cam = classify(dev.Name)
            for item, prefix in walk(dev.GetFolder):
                if not any(x.upper() == 'DCIM' for x in prefix):
                    continue
                target = dest / cam / item.Name
                if not target.exists():
                    rows.append(dict(cam=cam, mtp=item, target=str(target), size=int(item.Size)))
        return rows

    @app.get('/')
    def index():
        return render_template('index.html', user=cfg['usuario'])

    @app.get('/api/jobs')
    def joblist():
        return jsonify(list(jobs.items.values()))

    @app.post('/api/cancel/<jid>')
    def cancel(jid):
        job = jobs.items[jid]
        if job['label'] != 'Copiar':
            raise ValueError('Solo la copia se puede cancelar')
        job['cancel'] = True
        return jsonify(ok=True)

    @app.post('/api/cameras')
    def cameras():
        def action(job):
            rows = scan()
            groups = {}
            for row in rows:
                group = groups.setdefault(row['cam'], dict(camera=row['cam'], count=0, gb=0))
                group['count'] += 1
                group['gb'] += row['size']/1073741824
            return list(groups.values())
        return jsonify(jobs.add('Buscar cámaras', action))

    @app.post('/api/copy')
    def copy():
        def action(job):
            rows = scan()
            total = sum(r['size'] for r in rows)
            done, start = 0, time.monotonic()
            for row in rows:
                if job.get('cancel'):
                    break
                target = Path(row['target'])
                target.parent.mkdir(parents=True, exist_ok=True)
                # Nunca reemplazar una copia existente de distinto tamaño.
                target = unique(target)
                tmp = target.with_name(target.name + '.copiando')
                def progress(n):
                    speed = (done+n)/max(time.monotonic()-start, .01)
                    job['progress'] = dict(file=target.name, percent=round(100*(done+n)/max(total, 1)), mbs=round(speed/1048576, 2), remaining=round((total-done-n)/max(speed, 1)))
                try:
                    if 'mtp' in row:
                        import win32com.client
                        staging = data / 'mtp' / job['id'] / str(done)
                        staging.mkdir(parents=True, exist_ok=True)
                        win32com.client.Dispatch('Shell.Application').NameSpace(str(staging)).CopyHere(row['mtp'], 16+1024)
                        incoming = staging / row['mtp'].Name
                        deadline = time.monotonic()+3600
                        while not incoming.exists() or incoming.stat().st_size != row['size']:
                            if job.get('cancel') or time.monotonic() > deadline:
                                raise ValueError('Copia MTP interrumpida; el original permanece intacto')
                            progress(incoming.stat().st_size if incoming.exists() else 0)
                            time.sleep(.5)
                        shutil.copy2(incoming, tmp)
                    else:
                        with Path(row['source']).open('rb') as source, tmp.open('xb') as out:
                            n = 0
                            while chunk := source.read(8*1024*1024):
                                if job.get('cancel'):
                                    break
                                out.write(chunk)
                                n += len(chunk)
                                progress(n)
                        if job.get('cancel'):
                            break
                        shutil.copystat(row['source'], tmp)
                    tmp.rename(target)
                    done += row['size']
                    jobs.log(job, 'Copiado: ' + target.name)
                finally:
                    if tmp.exists():
                        tmp.unlink()
            return dict(bytes=done)
        return jsonify(jobs.add('Copiar', action))

    @app.get('/api/recordings')
    def recordings():
        root = Path(cfg['destino'])
        return jsonify([dict(path=str(p), date=p.name, counts={cam:sum(1 for f in (p/cam).rglob('*') if f.is_file() and f.suffix.lower() in MEDIA) for cam in ('DJI','Insta360','Canon')}) for p in sorted(root.glob('????-??-??')) if p.is_dir()])

    @app.post('/api/analyze')
    def analyze():
        src = srcpath(request.json['src'])
        def action(job):
            result = []
            for cam in ('DJI', 'Insta360', 'Canon'):
                for p in (src/cam).rglob('*'):
                    if p.suffix.lower() not in {'.mp4', '.mov', '.insv'}:
                        continue
                    p = media_path(p, roots)
                    out = src/'_analisis'/'app'/cam/p.stem
                    out.mkdir(parents=True, exist_ok=True)
                    ficha = out/'probe.json'
                    info = json.loads(ficha.read_text()) if ficha.exists() else probe(p)
                    ficha.write_text(json.dumps(info), encoding='utf-8')
                    sheets = []
                    for start in range(0, max(1, int(info['duration'])), 300):
                        sheet = out/f'hoja_{start}.jpg'
                        if not sheet.exists():
                            filters = ('zscale=t=linear:npl=203,format=gbrpf32le,tonemap=hable,zscale=t=bt709,format=yuv420p,' if info['hdr'] else '') + 'fps=1/10,scale=240:135:force_original_aspect_ratio=decrease,pad=240:135:(ow-iw)/2:(oh-ih)/2,tile=6x5'
                            run(job, [ff, '-v','error','-n','-ss',str(start),'-i',str(p),'-vf',filters,'-frames:v','1',str(sheet)])
                        sheets.append(dict(path=str(sheet), start=start))
                    audio = out/'audio.opus'
                    if not audio.exists():
                        run(job, [ff, '-v','error','-n','-i',str(p),'-map','0:a:0?','-vn','-ar','16000','-c:a','libopus','-b:a','24k',str(audio)])
                    result.append(dict(file=str(p), info=info, sheets=sheets))
            return result
        return jsonify(jobs.add('Analizar', action))

    @app.get('/api/style/<style>')
    def style(style):
        return jsonify(json.loads((REPO/'plantillas'/'planes'/(STYLES[style]+'.json')).read_text(encoding='utf-8-sig')))

    @app.post('/api/render')
    def render():
        body = request.json
        src = srcpath(body['src'])
        plan = validate_plan(body['plan'], src, roots)
        def action(job):
            folder = data/'planes'/job['id']
            folder.mkdir(parents=True)
            salida = 'TikTok_app_' + job['id'][:12]
            # Carpeta nueva por trabajo: el motor puede usar -y sin pisar renders previos.
            spec = importlib.util.spec_from_file_location('mkass', REPO/'scripts/render/mkass.py')
            ass = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(ass)
            outputs = []
            for output in plan['outputs']:
                if plan.get('only') and output['name'] not in plan['only']:
                    continue
                output = dict(output)
                duration = sum(float(s['dur'])/float(s.get('speed',1)) for s in output['segments'])
                if body.get('texts'):
                    texts = body['texts']
                    clean = lambda s: str(s).replace('{','').replace('}','').replace('\\','').replace('\n', ' ')
                    events = []
                    if texts.get('hook'):
                        events.append(ass.ev(0,min(2.8,duration),'Titulo',clean(texts['hook'])))
                    if texts.get('title'):
                        events.append(ass.titulo(.6,min(3.8,duration),clean(texts['title'])))
                    if texts.get('signature'):
                        events.append(ass.ev(max(0,duration-2.6),duration,'Sub',clean(texts['signature'])))
                    ass.write(folder/(output['name']+'.ass'), events)
                    output['ass'] = output['name']+'.ass'
                elif output.get('ass'):
                    original = REPO/'plantillas/planes'/Path(output['ass']).name
                    if original.suffix != '.ass' or not original.exists():
                        raise ValueError('Subtítulo de plantilla no encontrado')
                    shutil.copy2(original, folder/original.name)
                    output['ass'] = original.name
                outputs.append(output)
            if not outputs:
                raise ValueError('No hay salidas seleccionadas')
            path = folder/'plan.json'
            path.write_text(json.dumps(dict(outputs=outputs), ensure_ascii=False), encoding='utf-8-sig')
            run(job, ['powershell','-NoProfile','-ExecutionPolicy','Bypass','-File',str(REPO/'scripts/render/motor.ps1'),'-Plan',str(path),'-Src',str(src),'-Salida',salida,'-FF',ff])
            results = []
            for output in outputs:
                video = src/salida/(output['name']+'.mp4')
                check = src/'_analisis'/('render_'+salida)/(output['name']+'_check.jpg')
                info = probe(video)
                if not check.exists() or ('LISTO: '+output['name']+'.mp4') not in job['log'] or 'ERROR' in job['log']:
                    raise ValueError('El render no superó la revisión del log y la hoja')
                results.append(dict(video=str(video), check=str(check), info=info, listo=True))
            (data / ('render_' + job['id'] + '.json')).write_text(json.dumps(results), encoding='utf-8')
            return results
        return jsonify(jobs.add('Renderizar', action))

    @app.get('/api/renders')
    def renders():
        return jsonify([row for p in data.glob('render_*.json') for row in json.loads(p.read_text(encoding='utf-8'))])

    @app.get('/media')
    def media():
        return send_file(media_path(request.args['path'], roots), conditional=True)

    @app.route('/api/analytics', methods=['GET','POST'])
    def analytics():
        path = data/'analiticas.csv'
        fields = ['video','hours','views','average','complete']
        if request.method == 'POST':
            body = request.json
            row = {k:body[k] for k in fields}
            for k in fields[1:]:
                row[k] = float(row[k])
                if not __import__('math').isfinite(row[k]) or row[k]<0:
                    raise ValueError('Las métricas deben ser números positivos')
            if row['complete'] > 100:
                raise ValueError('Porcentaje máximo 100')
            if str(row['video']).startswith(('=', '+', '-', '@')):
                row['video'] = "'"+str(row['video'])
            exists = path.exists()
            with path.open('a',newline='',encoding='utf-8') as f:
                writer = csv.DictWriter(f,fieldnames=fields)
                if not exists:
                    writer.writeheader()
                writer.writerow(row)
        with path.open(encoding='utf-8') if path.exists() else __import__('io').StringIO('') as f:
            rows = list(csv.DictReader(f))
        for row in rows:
            row['status'] = threshold(*(float(row[k]) for k in fields[1:]))
        return jsonify(rows)

    @app.post('/api/caption')
    def caption():
        hashtags(request.json['text'])
        return jsonify(ok=True)

    @app.post('/api/upload')
    def upload():
        body = request.json
        hashtags(body.get('text',''))
        if body.get('confirm') is not True:
            raise ValueError('Confirma el envío de este video en el diálogo')
        video = media_path(body['video'], roots)
        if video.suffix.lower() != '.mp4' or not any(part.startswith('TikTok') for part in video.parts):
            raise ValueError('Selecciona un video terminado')
        def action(job):
            from upload import send
            return send(video, Path(cfg['cola']).parent/'tiktok')
        return jsonify(jobs.add('Enviar a borradores', action))

    return app

if __name__ == '__main__':
    import sys
    if '--open' in sys.argv:
        import threading
        threading.Timer(1.5, lambda: webbrowser.open('http://127.0.0.1:8765')).start()
    create_app().run(host='127.0.0.1', port=8765, debug=False)
