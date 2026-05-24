import sys
import json
import struct
import subprocess
import os
import shutil

def get_message():
    raw_length = sys.stdin.buffer.read(4)
    if not raw_length:
        sys.exit(0)
    message_length = struct.unpack('I', raw_length)[0]
    message = sys.stdin.buffer.read(message_length).decode('utf-8')
    return json.loads(message)

def send_message(message):
    encoded = json.dumps(message).encode('utf-8')
    sys.stdout.buffer.write(struct.pack('I', len(encoded)))
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()

def find_node():
    """Busca Node.js en varias ubicaciones comunes"""
    # Primero intentar con el PATH del sistema
    node_path = shutil.which('node')
    if node_path:
        return os.path.dirname(node_path)
    
    # Rutas comunes de Node.js en Windows
    posibles = [
        r'C:\Program Files\nodejs',
        r'C:\Program Files (x86)\nodejs',
        os.path.join(os.environ.get('APPDATA', ''), 'nvm', 'current'),
        os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Programs', 'nodejs'),
        os.path.join(os.environ.get('ProgramFiles', ''), 'nodejs'),
    ]
    
    for ruta in posibles:
        if ruta and os.path.isfile(os.path.join(ruta, 'node.exe')):
            return ruta
    
    return None

def get_downloads_folder():
    """Obtiene la carpeta de descargas del usuario (funciona en cualquier idioma de Windows)"""
    # Intentar con la API de Windows via registro
    try:
        import winreg
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
        )
        downloads_path = winreg.QueryValueEx(key, '{374DE290-123F-4565-9164-39C4925E467B}')[0]
        winreg.CloseKey(key)
        # Expandir variables de entorno como %USERPROFILE%
        downloads_path = os.path.expandvars(downloads_path)
        if os.path.isdir(downloads_path):
            return downloads_path
    except Exception:
        pass
    
    # Fallback: ~/Downloads o ~/Descargas
    home = os.path.expanduser('~')
    for nombre in ['Downloads', 'Descargas', 'Téléchargements']:
        carpeta = os.path.join(home, nombre)
        if os.path.isdir(carpeta):
            return carpeta
    
    # Ultimo fallback: crear Downloads
    carpeta = os.path.join(home, 'Downloads')
    os.makedirs(carpeta, exist_ok=True)
    return carpeta

def get_unique_filename(carpeta, nombre, ext):
    """Genera un nombre de archivo único si ya existe"""
    base_path = os.path.join(carpeta, f'{nombre}.{ext}')
    if not os.path.exists(base_path):
        return base_path
    
    counter = 1
    while True:
        new_path = os.path.join(carpeta, f'{nombre} ({counter}).{ext}')
        if not os.path.exists(new_path):
            return new_path
        counter += 1

def main():
    try:
        msg = get_message()
    except Exception as e:
        send_message({'status': 'error', 'message': f'Error leyendo mensaje: {str(e)}'})
        return
    
    if msg.get('action') == 'download':
        url = msg.get('url', '')
        nombre = msg.get('nombre', 'video')
        formato = msg.get('formato', 'mp4')
        
        # Validar URL
        if not url or not url.startswith('http'):
            send_message({'status': 'error', 'message': 'URL inválida o vacía'})
            return
        
        # Obtener carpeta de descargas
        carpeta = get_downloads_folder()
        
        # Verificar que yt-dlp y ffmpeg existen
        script_dir = os.path.dirname(os.path.abspath(__file__))
        ytdlp_path = os.path.join(script_dir, 'yt-dlp.exe')
        ffmpeg_path = os.path.join(script_dir, 'ffmpeg.exe')
        
        if not os.path.isfile(ytdlp_path):
            send_message({'status': 'error', 'message': f'No se encontró yt-dlp.exe en: {script_dir}'})
            return
        
        if not os.path.isfile(ffmpeg_path):
            send_message({'status': 'error', 'message': f'No se encontró ffmpeg.exe en: {script_dir}'})
            return
        
        # Buscar Node.js
        node_dir = find_node()
        
        # Configurar entorno con Node.js siempre disponible
        env = os.environ.copy()
        # Agregar rutas comunes de Node.js al PATH por si el proceso no las hereda
        extra_paths = []
        if node_dir:
            extra_paths.append(node_dir)
        extra_paths.extend([
            r'C:\Program Files\nodejs',
            os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Programs', 'nodejs'),
        ])
        env['PATH'] = ';'.join(extra_paths) + ';' + env.get('PATH', '')
        
        # Generar nombre de archivo único
        ext = 'mp3' if formato == 'mp3' else 'mp4'
        output_path = get_unique_filename(carpeta, nombre, ext)
        
        try:
            if formato == 'mp3':
                cmd = [
                    ytdlp_path,
                    '--ffmpeg-location', ffmpeg_path,
                    '-x',
                    '--audio-format', 'mp3',
                    '--audio-quality', '0',
                    '--no-playlist',
                    '--no-part',
                    '-o', output_path,
                    url
                ]
            else:
                cmd = [
                    ytdlp_path,
                    '--ffmpeg-location', ffmpeg_path,
                    '-f', 'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b',
                    '--merge-output-format', 'mp4',
                    '--no-playlist',
                    '--no-part',
                    '-o', output_path,
                    url
                ]
            
            # Agregar Node.js como runtime disponible
            cmd.insert(3, '--js-runtimes')
            cmd.insert(4, 'nodejs')
            
            result = subprocess.run(
                cmd,
                capture_output=True, text=True, timeout=600,
                env=env,
                creationflags=subprocess.CREATE_NO_WINDOW if hasattr(subprocess, 'CREATE_NO_WINDOW') else 0
            )
            
            if result.returncode == 0:
                archivo_final = os.path.basename(output_path)
                send_message({'status': 'ok', 'message': f'Descargado: {archivo_final} en Descargas'})
            else:
                error_msg = result.stderr[:300] if result.stderr else 'Error desconocido de yt-dlp'
                # Dar pistas útiles sobre errores comunes
                if 'unable to extract' in error_msg.lower() or 'nsig' in error_msg.lower():
                    error_msg += ' | Posible solución: actualiza yt-dlp.exe'
                send_message({'status': 'error', 'message': error_msg})
                
        except subprocess.TimeoutExpired:
            send_message({'status': 'error', 'message': 'Timeout: la descarga tardó más de 10 minutos'})
        except FileNotFoundError as e:
            send_message({'status': 'error', 'message': f'Ejecutable no encontrado: {str(e)}'})
        except PermissionError:
            send_message({'status': 'error', 'message': 'Sin permisos para escribir en la carpeta Descargas'})
        except Exception as e:
            send_message({'status': 'error', 'message': f'Error inesperado: {str(e)}'})
    else:
        send_message({'status': 'error', 'message': 'Acción no reconocida'})

if __name__ == '__main__':
    main()
