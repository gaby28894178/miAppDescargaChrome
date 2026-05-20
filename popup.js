document.addEventListener('DOMContentLoaded', async () => {
  const listaContainer = document.getElementById('lista-videos');
  const videoTitulo = document.getElementById('video-titulo');
  const miniImg = document.getElementById('mini-img');

  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab) return;

  const tituloOriginal = tab.title;
  videoTitulo.innerText = tituloOriginal;

  const nombreLimpio = tituloOriginal.replace(/[/\\?%*:|"<>\s]/g, '_').substring(0, 50);

  if (tab.url.includes("youtube.com/watch")) {
    const urlParams = new URLSearchParams(new URL(tab.url).search);
    const videoId = urlParams.get('v');
    if (videoId) miniImg.src = `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`;
  }

  // Mostrar botón de descarga si estamos en YouTube
  if (tab.url.includes("youtube.com/watch") || tab.url.includes("twitch.tv")) {
    listaContainer.innerHTML = "";

    const card = document.createElement('div');
    card.className = 'video-item';
    card.innerHTML = `
      <span class="tipo" style="color: #00adb5;">¡Video Detectado!</span>
      <div style="font-size: 11px; margin-bottom: 8px; color: #ccc;">
        Se descargará como MP4 completo con audio usando yt-dlp portable.
      </div>
      <button id="btn-descargar" style="background: #00adb5; color: white; width: 100%; padding: 10px; border: none; border-radius: 4px; font-weight: bold; cursor: pointer; margin-bottom: 6px;">
        📥 Descargar MP4 Completo (con audio)
      </button>
      <div id="status-msg" style="font-size: 11px; color: #888; margin-top: 4px;"></div>
    `;

    listaContainer.appendChild(card);

    document.getElementById('btn-descargar').addEventListener('click', (e) => {
      e.target.innerText = "⏳ Descargando con yt-dlp...";
      e.target.disabled = true;
      document.getElementById('status-msg').innerText = "Procesando video+audio, puede tardar unos segundos...";

      chrome.runtime.sendMessage({
        action: "descargarConYtdlp",
        url: tab.url,
        nombre: nombreLimpio
      });
    });

    // Escuchar resultado de yt-dlp
    chrome.runtime.onMessage.addListener((msg) => {
      if (msg.action === 'ytdlpResult') {
        const btn = document.getElementById('btn-descargar');
        const status = document.getElementById('status-msg');
        if (msg.result.status === 'ok') {
          btn.innerText = "✅ ¡Descargado!";
          status.style.color = '#00adb5';
          status.innerText = msg.result.message;
        } else {
          btn.innerText = "📥 Reintentar";
          btn.disabled = false;
          status.style.color = '#ff6b6b';
          status.innerText = "Error: " + msg.result.message;
        }
      }
    });
  }
});
