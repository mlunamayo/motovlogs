"""Ventana de escritorio de Motovlogs; el servidor vive y termina con ella."""
import ctypes
import json
import os
import sys
import threading
from pathlib import Path

from werkzeug.serving import make_server
from server import create_app


def main(smoke=False):
    mutex = None
    if os.name == 'nt':
        kernel = ctypes.WinDLL('kernel32', use_last_error=True)
        kernel.CreateMutexW.restype = ctypes.c_void_p
        mutex = kernel.CreateMutexW(None, False, 'Local\\MotovlogsDesktop')
        if ctypes.get_last_error() == 183:
            user = ctypes.windll.user32
            hwnd = user.FindWindowW(None, 'Motovlogs')
            if hwnd:
                user.ShowWindow(hwnd, 9)
                user.SetForegroundWindow(hwnd)
            return
    server = None
    try:
        import webview
        webview.settings['ALLOW_DOWNLOADS'] = True
        app = create_app()
        server = make_server('127.0.0.1', 8765, app, threaded=True)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        window = webview.create_window('Motovlogs', 'http://127.0.0.1:8765', width=1280, height=900, min_size=(900, 650), background_color='#111720')

        def closing():
            busy = any(j['state'] in {'cola', 'corriendo'} for j in app.extensions['jobs'].items.values())
            if busy:
                if os.name == 'nt':
                    ctypes.windll.user32.MessageBoxW(None, 'Hay trabajos pendientes. Espera a que terminen o cancela la copia antes de cerrar.', 'Motovlogs', 0x40)
                return False

        window.events.closing += closing
        if smoke:
            def loaded():
                import urllib.request
                report = dict(title=window.evaluate_js('document.title'), tabs=window.evaluate_js('document.querySelectorAll("nav button").length'))
                with urllib.request.urlopen('http://127.0.0.1:8765/', timeout=5) as response:
                    report['http'] = response.status
                (Path(__file__).parent/'datos'/'desktop_smoke.json').write_text(json.dumps(report), encoding='utf-8')
                window.destroy()
            window.events.loaded += loaded
        webview.start(gui='edgechromium' if os.name == 'nt' else None, debug=False)
    except Exception:
        if os.name == 'nt':
            ctypes.windll.user32.MessageBoxW(None, 'No se pudo abrir Motovlogs. Cierra una instancia antigua del servidor y repite instalar.ps1. Comprueba que Microsoft Edge WebView2 Runtime esté instalado.', 'Motovlogs', 0x10)
        raise
    finally:
        if server:
            server.shutdown()
            server.server_close()
        if mutex:
            kernel.CloseHandle.argtypes = [ctypes.c_void_p]
            kernel.CloseHandle(mutex)


if __name__ == '__main__':
    main(smoke='--smoke' in sys.argv)
