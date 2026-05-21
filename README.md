# 🎥 Descargador Universal Automático - Extensión Chrome

Extensión de Google Chrome que permite descargar videos de **YouTube** y **Twitch** como archivos **MP4** (video + audio) o **MP3** (solo audio) usando **yt-dlp** de forma portable, sin necesidad de instalar programas adicionales en el sistema.

![Chrome Extension](https://img.shields.io/badge/Chrome-Extension-green?logo=googlechrome&logoColor=white)
![Manifest V3](https://img.shields.io/badge/Manifest-V3-blue)
![yt--dlp](https://img.shields.io/badge/yt--dlp-portable-red)

---

## ✨ Características

- 🎬 **Descarga MP4** — Video completo con audio en máxima calidad
- 🎵 **Descarga MP3** — Extrae solo el audio en calidad máxima
- ⏱️ **Duración visible** — Muestra el tiempo del video en los botones de formato
- 🖼️ **Miniatura automática** — Preview del video de YouTube directamente en el popup
- 🔒 **ID fijo** — La extensión mantiene su ID sin importar dónde esté la carpeta
- 🚀 **Instalación automática** — El instalador detecta la ruta y configura todo sin intervención
- 🎨 **Interfaz moderna** — Diseño glassmorphism con gradientes y animaciones

---

## 📸 Vista Previa

```
┌─────────────────────────────────────────┐
│  📡 Radar de Video Pro                  │
│  ┌──────┐                               │
│  │ 🖼️  │  Título del video...          │
│  └──────┘                               │
│                                          │
│  ¡Video Detectado!                       │
│                                          │
│  ┌───────────────┐ ┌───────────────┐    │
│  │   🎬 MP4     │ │   🎵 MP3     │    │
│  │ Video + Audio │ │  Solo Audio   │    │
│  │   🕐 4:32    │ │   🕐 4:32    │    │
│  └───────────────┘ └───────────────┘    │
│                                          │
│  ┌─────────────────────────────────┐    │
│  │   ⬇️  Descargar MP4            │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

---

## 📁 Estructura del Proyecto

```
extencion chrome mia/
├── manifest.json              # Configuración de la extensión (Manifest V3 + key fija)
├── popup.html                 # Interfaz visual del popup (diseño glassmorphism)
├── popup.js                   # Lógica del popup (selector formato, duración, descarga)
├── background.js              # Service Worker (intercepta flujos, Native Messaging)
├── native_host.py             # Script Python que ejecuta yt-dlp (MP4 y MP3)
├── native_host.bat            # Lanzador del script Python
├── com.descargador.ytdlp.json # Manifiesto del Native Messaging Host (auto-generado)
├── instalar_host.bat          # Instalador automático (detecta ruta, registra host)
├── yt-dlp.exe                 # Descargador de video portable
├── ffmpeg.exe                 # Codificador de video/audio portable
├── icono.png                  # Ícono de la extensión
└── icono.svg                  # Ícono vectorial
```

---

## ⚙️ Requisitos Previos

| Requisito | Descripción |
|-----------|-------------|
| **Google Chrome** | Navegador (versión 88+ para Manifest V3) |
| **Python 3.x** | Necesario para ejecutar `native_host.py` |
| **Node.js** | Requerido por yt-dlp para descifrar videos protegidos |
| **Windows** | El proyecto está configurado para Windows |

> ⚠️ **Python** y **Node.js** deben estar instalados y accesibles desde el PATH del sistema.

---

## 🚀 Instalación Paso a Paso

### Paso 1: Descargar/Clonar el Proyecto

```bash
git clone https://github.com/TU_USUARIO/miAppDescargaChrome.git
```

O descarga el ZIP y extráelo en cualquier carpeta.

> ✅ **Puedes mover la carpeta libremente.** Solo vuelve a ejecutar `instalar_host.bat` después de moverla.

---

### Paso 2: Cargar la Extensión en Chrome

1. Abre Chrome y ve a `chrome://extensions/`
2. Activa el **Modo desarrollador** (esquina superior derecha)
3. Haz clic en **"Cargar descomprimida"**
4. Selecciona la carpeta del proyecto

```
chrome://extensions/ → Modo desarrollador → Cargar descomprimida
```

> ℹ️ El ID de la extensión es fijo (`bmenjglifbckojodomkkbaoknjhejdbd`) gracias a la `key` en el manifest. No necesitas configurar nada manualmente.

---

### Paso 3: Ejecutar el Instalador

Haz doble clic (o clic derecho → Ejecutar como administrador) en:

```
instalar_host.bat
```

El instalador hace todo automáticamente:
- Detecta la ruta actual de la carpeta
- Genera el archivo `com.descargador.ytdlp.json` con las rutas correctas
- Registra el Native Messaging Host en Windows

**No requiere intervención del usuario.**

---

### Paso 4: Verificar Python y Node.js

Abre una terminal y verifica:

```bash
python --version
# Debe mostrar Python 3.x

node --version
# Debe mostrar v18+ o superior
```

Si no están instalados:
- **Python:** https://www.python.org/downloads/
- **Node.js:** https://nodejs.org/

---

## 🎮 Uso

1. Navega a un video de **YouTube** o **Twitch**
2. Haz clic en el ícono de la extensión (📡)
3. Se mostrará la miniatura, título y **duración** del video
4. Selecciona el formato:
   - **MP4** — Video completo con audio
   - **MP3** — Solo audio en máxima calidad
5. Presiona **"Descargar"**
6. Espera a que yt-dlp procese el archivo
7. El archivo se guardará en tu carpeta **Descargas** (`~/Downloads`)

---

## 🔧 Cómo Funciona (Arquitectura)

```
┌──────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   popup.js   │────▶│  background.js   │────▶│ native_host.py  │
│  (Interfaz)  │     │ (Service Worker) │     │   (Python)      │
└──────────────┘     └──────────────────┘     └────────┬────────┘
                        Native Messaging                │
                                                        ▼
                                               ┌────────────────┐
                                               │   yt-dlp.exe   │
                                               │  + ffmpeg.exe  │
                                               └────────────────┘
                                                        │
                                                        ▼
                                            📁 ~/Downloads/video.mp4
                                            📁 ~/Downloads/video.mp3
```

1. **popup.js** detecta si estás en YouTube/Twitch, obtiene la duración del video y muestra el selector de formato
2. Al hacer clic en descargar, envía el formato elegido (mp4/mp3) al **background.js**
3. **background.js** se comunica con **native_host.py** vía Native Messaging
4. **native_host.py** ejecuta **yt-dlp.exe** con los argumentos según el formato:
   - MP4: `-f bv*[ext=mp4]+ba[ext=m4a] --merge-output-format mp4`
   - MP3: `-x --audio-format mp3 --audio-quality 0`
5. El resultado se guarda en la carpeta Descargas

---

## 🐛 Solución de Problemas

| Problema | Solución |
|----------|----------|
| "Specified native messaging host not found" | Ejecuta `instalar_host.bat` de nuevo |
| "Timeout: video muy largo" | Videos de más de 10 min pueden tardar, el timeout es de 600s |
| yt-dlp no descarga | Verifica que Node.js esté instalado (`node --version`) |
| No aparece el botón | Asegúrate de estar en `youtube.com/watch` o `twitch.tv` |
| Error de permisos | Ejecuta `instalar_host.bat` como administrador |
| Moviste la carpeta | Solo ejecuta `instalar_host.bat` de nuevo, detecta la ruta automáticamente |
| ID de extensión cambió | No debería pasar. La key fija en manifest.json garantiza el mismo ID siempre |

---

## 📋 Notas Técnicas

- **Manifest V3** con Service Worker (no background page)
- **Key fija** en manifest.json para ID de extensión permanente
- **Native Messaging** para comunicación Chrome ↔ Python
- **Selector de formato** MP4/MP3 con duración visible
- **Duración del video** obtenida via `chrome.scripting` desde el elemento `<video>` de la página
- **yt-dlp** formato MP4: `bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]` (mejor video + mejor audio)
- **yt-dlp** formato MP3: `-x --audio-format mp3 --audio-quality 0` (máxima calidad audio)
- **ffmpeg** incluido de forma portable para merge/conversión de streams
- **Instalador automático** que detecta la ruta con `%~dp0` y genera el JSON dinámicamente
- Los archivos se descargan sin partes temporales (`--no-part`)
- No descarga playlists (`--no-playlist`)
- **Font Awesome 6.4** para iconografía moderna
- **Diseño glassmorphism** con backdrop-filter y gradientes

---

## 📄 Licencia

Uso personal/educativo. Los binarios `yt-dlp.exe` y `ffmpeg.exe` tienen sus propias licencias:
- [yt-dlp (Unlicense)](https://github.com/yt-dlp/yt-dlp/blob/master/LICENSE)
- [ffmpeg (LGPL/GPL)](https://ffmpeg.org/legal.html)
