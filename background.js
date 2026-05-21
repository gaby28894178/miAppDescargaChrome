let flujosDetectados = {};

chrome.webRequest.onBeforeRequest.addListener(
  (details) => {
    const url = details.url;
    const tabId = details.tabId;
    if (tabId === -1) return;

    if (
      url.includes("videoplayback") ||
      url.includes(".googlevideo.com/initplayback") ||
      url.includes(".m3u8") ||
      url.includes(".mp4")
    ) {
      if (!flujosDetectados[tabId]) {
        flujosDetectados[tabId] = { videoUrls: [], audioUrls: [] };
      }

      if (url.includes("mime=audio")) {
        if (!flujosDetectados[tabId].audioUrls.includes(url)) flujosDetectados[tabId].audioUrls.push(url);
      } else {
        if (!flujosDetectados[tabId].videoUrls.includes(url)) flujosDetectados[tabId].videoUrls.push(url);
      }

      const total = flujosDetectados[tabId].videoUrls.length;
      chrome.action.setBadgeText({ tabId: tabId, text: total.toString() });
      chrome.action.setBadgeBackgroundColor({ tabId: tabId, color: "#5bc0be" });
    }
  },
  { urls: ["<all_urls>"] }
);

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === "getFlujos") {
    sendResponse({ flujos: flujosDetectados[message.tabId] || { videoUrls: [], audioUrls: [] } });
  }

  if (message.action === "descargarConYtdlp") {
    let port;
    try {
      port = chrome.runtime.connectNative('com.descargador.ytdlp');
    } catch (e) {
      chrome.runtime.sendMessage({
        action: 'ytdlpResult',
        result: { status: 'error', message: 'No se pudo conectar con el native host. Ejecuta instalar_host.bat' }
      }).catch(() => {});
      sendResponse({ status: 'error' });
      return true;
    }

    let responded = false;

    port.postMessage({
      action: 'download',
      url: message.url,
      nombre: message.nombre,
      formato: message.formato || 'mp4'
    });

    port.onMessage.addListener((response) => {
      if (!responded) {
        responded = true;
        chrome.runtime.sendMessage({ action: 'ytdlpResult', result: response }).catch(() => {});
        port.disconnect();
      }
    });

    port.onDisconnect.addListener(() => {
      if (!responded) {
        responded = true;
        let errorMsg = 'Conexión con native host perdida';
        if (chrome.runtime.lastError) {
          const msg = chrome.runtime.lastError.message || '';
          if (msg.includes('not found') || msg.includes('No such native')) {
            errorMsg = 'Native host no encontrado. Ejecuta instalar_host.bat y reinicia Chrome.';
          } else if (msg.includes('host has exited')) {
            errorMsg = 'El proceso terminó inesperadamente. Verifica que Python esté instalado.';
          } else {
            errorMsg = msg;
          }
        }
        chrome.runtime.sendMessage({
          action: 'ytdlpResult',
          result: { status: 'error', message: errorMsg }
        }).catch(() => {});
      }
    });

    sendResponse({ status: 'enviado' });
  }

  return true;
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (changeInfo.status === 'loading') {
    flujosDetectados[tabId] = { videoUrls: [], audioUrls: [] };
    chrome.action.setBadgeText({ tabId: tabId, text: "" });
  }
});

// Limpiar flujos cuando se cierra una pestaña
chrome.tabs.onRemoved.addListener((tabId) => {
  delete flujosDetectados[tabId];
});
