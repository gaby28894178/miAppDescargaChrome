import sys
import json
import struct
import subprocess
import os

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

def main():
    msg = get_message()
    
    if msg.get('action') == 'download':
        url = msg.get('url', '')
        nombre = msg.get('nombre', 'video')
        carpeta = os.path.join(os.path.expanduser('~'), 'Downloads')
        
        script_dir = os.path.dirname(os.path.abspath(__file__))
        ytdlp_path = os.path.join(script_dir, 'yt-dlp.exe')
        ffmpeg_path = os.path.join(script_dir, 'ffmpeg.exe')
        
        output_template = os.path.join(carpeta, f'{nombre}.mp4')
        
        # Forzar PATH con Node.js
        env = os.environ.copy()
        env['PATH'] = r'C:\Program Files\nodejs;' + env.get('PATH', '')
        
        try:
            result = subprocess.run(
                [ytdlp_path,
                 '--ffmpeg-location', ffmpeg_path,
                 '--js-runtimes', 'nodejs',
                 '-f', 'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b',
                 '--merge-output-format', 'mp4',
                 '--no-playlist',
                 '--no-part',
                 '-o', output_template,
                 url],
                capture_output=True, text=True, timeout=600,
                env=env
            )
            
            if result.returncode == 0:
                send_message({'status': 'ok', 'message': f'Descargado: {nombre}.mp4 en Descargas'})
            else:
                send_message({'status': 'error', 'message': result.stderr[:300]})
        except subprocess.TimeoutExpired:
            send_message({'status': 'error', 'message': 'Timeout: video muy largo (>10 min)'})
        except Exception as e:
            send_message({'status': 'error', 'message': str(e)})
    else:
        send_message({'status': 'error', 'message': 'Acción no reconocida'})

if __name__ == '__main__':
    main()
