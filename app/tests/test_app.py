import json
import sys
import threading
import urllib.request
from pathlib import Path
import pytest
from werkzeug.serving import make_server

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from core import classify, validate_plan, hashtags, unique, threshold, Jobs
from server import create_app

@pytest.fixture
def context(tmp_path):
    root = tmp_path/'material'
    src = root/'2026-10-21'
    (src/'DJI').mkdir(parents=True)
    clip = src/'DJI'/'DJI_test.MP4'
    clip.write_bytes(b'fixture')
    cfg = dict(destino=str(root), red360=str(tmp_path/'red'),ffmpeg='ffmpeg',usuario='martin',cola=str(tmp_path/'cola'))
    app = create_app(cfg, tmp_path/'datos')
    return app, src, clip

@pytest.mark.parametrize('folder,files,expected', [('100CANON',[], 'Canon'),('EOS',[], 'Canon'),('CANONMSC',[],None),('100MEDIA',['DJI_001.MP4'],'DJI'),('Osmo',[],'DJI'),('Camera01',[],'Insta360'),('MEDIA',['VID_001.insv'],'Insta360'),('MEDIA',['a.insp'],'Insta360'),('OTHER',[],'Otros')])
def test_classify(folder,files,expected):
    assert classify(folder,files)==expected

def test_valid_plan(context):
    _,src,clip=context
    assert validate_plan({'outputs':[{'name':'test','segments':[dict(file=str(clip),start=0,dur=3)]}]},src,[src])

@pytest.mark.parametrize('change',[{'dur':0},{'dur':-1},{'speed':0},{'speed':float('nan')},{'start':-1},{'file':'missing.mp4'},{'file':'token.json'}])
def test_bad_plan(context,change):
    _,src,clip=context
    segment=dict(file=str(clip),start=0,dur=3)
    segment.update(change)
    with pytest.raises(ValueError):
        validate_plan({'outputs':[{'name':'test','segments':[segment]}]},src,[src])

def test_required(context):
    _,src,_=context
    with pytest.raises(ValueError):
        validate_plan({},src,[src])
    with pytest.raises(ValueError):
        validate_plan({'outputs':[{'name':'test','segments':[{'file':'x'}]}]},src,[src])

def test_tags():
    assert len(hashtags('#a #b #c #d #e'))==5
    with pytest.raises(ValueError):
        hashtags('#a #b #c #d #e #f')

def test_version(tmp_path):
    p=tmp_path/'video.mp4'
    p.touch()
    assert unique(p).name=='video_v2.mp4'
    unique(p).touch()
    assert unique(p).name=='video_v3.mp4'

@pytest.mark.parametrize('values,result',[((24,100,8,5),'verde'),((24,100,7.9,5),'rojo'),((24,100,8,4.9),'rojo'),((23,1000,10,20),'pendiente'),((24,99,10,20),'pendiente')])
def test_threshold(values,result):
    assert threshold(*values)==result

def test_real_server(context):
    app,_,_=context
    server=make_server('127.0.0.1',0,app)
    thread=threading.Thread(target=server.serve_forever)
    thread.start()
    try:
        with urllib.request.urlopen(f'http://127.0.0.1:{server.server_port}/') as response:
            assert response.status==200
            assert b'Motovlogs' in response.read()
    finally:
        server.shutdown()
        thread.join()

def test_security(context):
    app,_,_=context
    client=app.test_client()
    assert client.get('/media?path=token.json',base_url='http://localhost').status_code==400
    assert client.post('/api/copy',json={},headers={'Origin':'https://evil.test'}).status_code==403
    assert client.get('/',base_url='http://evil.test').status_code==403
    assert client.post('/api/upload',json={'confirm':False}).status_code==400
    assert client.post('/api/caption',json={'text':'#a #b #c #d #e #f'}).status_code==400

def test_analytics_persistence(context):
    app,_,_=context
    c=app.test_client()
    row=dict(video='test',hours=24,views=100,average=8,complete=5)
    assert c.post('/api/analytics',json=row).json[0]['status']=='verde'
    assert len(c.get('/api/analytics').json)==1

def test_queue_serial_and_recovery(tmp_path):
    jobs=Jobs(tmp_path)
    order=[]
    event=threading.Event()
    def first(job):
        event.wait(2)
        order.append(1)
        raise ValueError('Fallo de prueba')
    a=jobs.add('primero',first)
    b=jobs.add('segundo',lambda job:order.append(2))
    event.set()
    jobs.pending.join()
    assert order==[1,2] and a['state']=='error' and b['state']=='terminado'

def test_templates(context):
    app,_,_=context
    for style in ('gancho','cine','curvas','rampa','studio'):
        assert app.test_client().get('/api/style/'+style).json['outputs']
