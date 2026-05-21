document.addEventListener('DOMContentLoaded', async () => {
  const listaContainer = document.getElementById('lista-videos');
  const videoTitulo = document.getElementById('video-titulo');
  const miniImg = document.getElementById('mini-img');
  const imgPlaceholder = document.getElementById('img-placeholder');

  // Verificar que tenemos una pestaña activa
  let tab;
  try {
    const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
    tab = tabs[0];
  } catch (e) {
    videoTitulo.innerText = 'Error al obtener la pestaña activa';
    return;
  }

  if (!tab || !tab.url) {
    videoTitulo.innerText = 'No se puede acceder a esta página';
    return;
  }

  // Verificar que no estamos en una página restringida
  if (tab.url.startsWith('chrome://') || tab.url.startsWith('chrome-extension://') || tab.url.startsWith('about:')) {
    videoTitulo.innerText = 'Navega a YouTube o Twitch para descargar';
    return;
  }

  const tituloOriginal = tab.title || 'Video sin título';
  videoTitulo.innerText = tituloOriginal;

  const nombreLimpio = tituloOriginal.replace(/[/\\?%*:|"<>\s]/g, '_').substring(0, 80) || 'video';

  // Mostrar miniatura de YouTube si aplica
  if (tab.url.includes("youtube.com/watch")) {
    try {
      const urlParams = new URLSearchParams(new URL(tab.url).search);
      const videoId = urlParams.get('v');
      if (videoId) {
        miniImg.src = `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`;
        miniImg.style.display = 'block';
        imgPlaceholder.style.display = 'none';
      }
    } catch (e) {
      // URL inválida, mantener placeholder
    }
  }

  // Obtener duración del video desde la pestaña
  let duracionTexto = '';
  try {
    const results = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: () => {
        const video = document.querySelector('video');
        if (video && video.duration && isFinite(video.duration)) {
          return video.duration;
        }
        const timeEl = document.querySelector('.ytp-time-duration');
        if (timeEl) return timeEl.textContent;
        return null;
      }
    });

    if (results && results[0] && results[0].result) {
      const duracion = results[0].result;
      if (typeof duracion === 'number') {
        duracionTexto = formatDuration(duracion);
      } else {
        duracionTexto = duracion;
      }
    }
  } catch (e) {
    // No se pudo inyectar script (página restringida o sin permiso)
  }

  // Mostrar duración en el preview
  if (duracionTexto) {
    document.getElementById('duracion-texto').innerText = duracionTexto;
    document.getElementById('video-duracion').style.display = 'inline-flex';
  }

  // Mostrar opciones de descarga si estamos en YouTube o Twitch
  if (tab.url.includes("youtube.com/watch") || tab.url.includes("twitch.tv")) {
    listaContainer.innerHTML = "";

    const duracionBadge = duracionTexto
      ? `<span class="format-duration"><i class="fas fa-clock"></i> ${duracionTexto}</span>`
      : '';

    const card = document.createElement('div');
    card.className = 'video-item';
    card.innerHTML = `
      <span class="tipo"><i class="fas fa-video"></i> ¡Video Detectado!</span>

      <div class="format-selector">
        <button class="format-btn active" data-format="mp4">
          <i class="fas fa-file-video"></i>
          <span class="format-label">MP4</span>
          <span class="format-desc">Video + Audio</span>
          ${duracionBadge}
        </button>
        <button class="format-btn" data-format="mp3">
          <i class="fas fa-music"></i>
          <span class="format-label">MP3</span>
          <span class="format-desc">Solo Audio</span>
          ${duracionBadge}
        </button>
      </div>

      <button id="btn-descargar" class="btn-descargar" style="width: 100%; padding: 10px;">
        <i class="fas fa-download"></i> Descargar MP4
      </button>
      <div id="status-msg"></div>
    `;

    listaContainer.appendChild(card);

    let formatoSeleccionado = 'mp4';

    // Manejar selección de formato
    const formatBtns = card.querySelectorAll('.format-btn');
    formatBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        formatBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        formatoSeleccionado = btn.dataset.format;

        const btnDescargar = document.getElementById('btn-descargar');
        if (formatoSeleccionado === 'mp4') {
          btnDescargar.innerHTML = '<i class="fas fa-download"></i> Descargar MP4';
        } else {
          btnDescargar.innerHTML = '<i class="fas fa-download"></i> Descargar MP3';
        }
      });
    });

    // Manejar descarga
    document.getElementById('btn-descargar').addEventListener('click', (e) => {
      const btn = e.currentTarget;
      btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Descargando...';
      btn.disabled = true;
      const statusEl = document.getElementById('status-msg');
      statusEl.style.color = '#9a9ab0';
      statusEl.innerText = formatoSeleccionado === 'mp4'
        ? "Procesando video+audio, puede tardar unos segundos..."
        : "Extrayendo audio, puede tardar unos segundos...";

      chrome.runtime.sendMessage({
        action: "descargarConYtdlp",
        url: tab.url,
        nombre: nombreLimpio,
        formato: formatoSeleccionado
      });
    });

    // Escuchar resultado de yt-dlp
    chrome.runtime.onMessage.addListener((msg) => {
      if (msg.action === 'ytdlpResult') {
        const btn = document.getElementById('btn-descargar');
        const status = document.getElementById('status-msg');
        if (!btn || !status) return;

        if (msg.result.status === 'ok') {
          btn.innerHTML = '<i class="fas fa-check-circle"></i> ¡Descargado!';
          status.style.color = '#5bc0be';
          status.innerText = msg.result.message;

          // Rehabilitar el botón después de 2 segundos para permitir descargar otro formato
          setTimeout(() => {
            btn.disabled = false;
            if (formatoSeleccionado === 'mp4') {
              btn.innerHTML = '<i class="fas fa-download"></i> Descargar MP4';
            } else {
              btn.innerHTML = '<i class="fas fa-download"></i> Descargar MP3';
            }
            status.innerText = 'Puedes descargar en otro formato si lo deseas.';
            status.style.color = '#9a9ab0';
          }, 2000);
        } else {
          btn.innerHTML = '<i class="fas fa-redo"></i> Reintentar';
          btn.disabled = false;
          status.style.color = '#ff6b6b';
          status.innerText = msg.result.message || 'Error desconocido';
        }
      }
    });
  }
});

function formatDuration(seconds) {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  if (h > 0) {
    return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }
  return `${m}:${s.toString().padStart(2, '0')}`;
}
