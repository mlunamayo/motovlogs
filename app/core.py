"""Operaciones locales: nunca abrir archivos de credenciales ni escribir originales."""
import json
import math
import re
import threading
import queue
import uuid
from pathlib import Path

MEDIA = {'.mp4', '.mov', '.insv', '.insp', '.jpg', '.jpeg', '.cr3', '.wav'}
SECRET = {'config.txt', 'token.json'}

def classify(folder, files=()):
    name = str(folder).upper()
    if 'CANONMSC' in name:
        return None
    if 'CANON' in name or 'EOS' in name:
        return 'Canon'
    if 'DJI' in name or 'OSMO' in name or any(Path(f).name.upper().startswith('DJI_') for f in files):
        return 'DJI'
    if re.search(r'CAMERA\d+|INSTA', name) or any(Path(f).suffix.lower() in {'.insv', '.insp'} for f in files):
        return 'Insta360'
    return 'Otros'

def inside(path, root):
    return Path(path).resolve().is_relative_to(Path(root).resolve())

def media_path(value, roots):
    p = Path(value).resolve()
    if p.suffix.lower() not in MEDIA or p.name.lower() in SECRET or not any(inside(p, r) for r in roots):
        raise ValueError('Archivo fuera de las carpetas de material permitidas')
    if not p.is_file():
        raise ValueError('El archivo no existe')
    return p

def safe_name(name):
    if not re.fullmatch(r'[a-zA-Z0-9_-]{1,80}', name):
        raise ValueError('Usa letras, números, guiones o guion bajo para el nombre')
    return name

def unique(path):
    path = Path(path)
    candidate, n = path, 2
    while candidate.exists():
        candidate = path.with_name(f'{path.stem}_v{n}{path.suffix}')
        n += 1
    return candidate

def validate_plan(plan, src, roots):
    if not isinstance(plan, dict) or not plan.get('outputs'):
        raise ValueError('Faltan las salidas del plan')
    names = set()
    for output in plan['outputs']:
        safe_name(output['name'])
        if output['name'] in names:
            raise ValueError('Nombre de salida repetido')
        names.add(output['name'])
        if not output.get('segments'):
            raise ValueError('Añade al menos una toma')
        for seg in output['segments']:
            for key in ('file', 'start', 'dur'):
                if key not in seg:
                    raise ValueError(f'Falta {key}')
            media_path(Path(src) / seg['file'], roots)
            for key, default in [('start', 0), ('dur', 0), ('speed', 1)]:
                value = float(seg.get(key, default))
                if not math.isfinite(value) or value < 0 or (key != 'start' and value == 0):
                    raise ValueError(f'{key} no válido')
            if seg.get('layout', 'full') not in {'full', 'band', 'pano', 'equi', 'lens'}:
                raise ValueError('Encuadre no válido')
    return plan

def hashtags(text):
    tags = re.findall(r'#[^\s#]+', text)
    if len(tags) > 5:
        raise ValueError('Máximo 5 hashtags')
    return tags

def threshold(hours, views, average, complete):
    if hours < 24 or views < 100:
        return 'pendiente'
    return 'verde' if average >= 8 and complete >= 5 else 'rojo'

class Jobs:
    def __init__(self, directory):
        self.directory = Path(directory)
        self.directory.mkdir(parents=True, exist_ok=True)
        self.items = {}
        self.pending = queue.Queue()
        threading.Thread(target=self.worker, daemon=True).start()

    def add(self, label, action):
        job = dict(id=uuid.uuid4().hex, label=label, state='cola', progress={}, result=None, log='')
        self.items[job['id']] = job
        self.pending.put((job, action))
        return job

    def log(self, job, line):
        job['log'] = (job['log'] + str(line) + '\n')[-50000:]
        with (self.directory / (job['id'] + '.log')).open('a', encoding='utf-8') as f:
            f.write(str(line) + '\n')

    def worker(self):
        while True:
            job, action = self.pending.get()
            try:
                if job.get('cancel'):
                    job['state'] = 'cancelado'
                    continue
                job['state'] = 'corriendo'
                job['result'] = action(job)
                job['state'] = 'cancelado' if job.get('cancel') else 'terminado'
            except Exception as exc:
                job['state'] = 'error'
                self.log(job, str(exc))
            finally:
                self.pending.task_done()
