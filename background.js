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
      chrome.action.setBadgeBackgroundColor({ tabId: tabId, color: "#00adb5" });
    }
  },
  { urls: ["<all_urls>"] }
);

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === "getFlujos") {
    sendResponse({ flujos: flujosDetectados[message.tabId] || { videoUrls: [], audioUrls: [] } });
  }
  if (message.action === "descargarConYtdlp") {
    const port = chrome.runtime.connectNative('com.descargador.ytdlp');
    port.postMessage({
      action: 'download',
      url: message.url,
      nombre: message.nombre
    });
    port.onMessage.addListener((response) => {
      chrome.runtime.sendMessage({ action: 'ytdlpResult', result: response });
      port.disconnect();
    });
    port.onDisconnect.addListener(() => {
      if (chrome.runtime.lastError) {
        chrome.runtime.sendMessage({
          action: 'ytdlpResult',
          result: { status: 'error', message: chrome.runtime.lastError.message }
        });
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
