export function createWebSocket(url) {
  return new WebSocket(url);
}

export function setMessageHandler(ws, handler) {
  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      handler(data);
    } catch (e) {
      console.error('Failed to parse WebSocket message:', e);
    }
  };
}

export function setCloseHandler(ws, handler) {
  ws.onclose = () => handler();
}

export function sendMessage(ws, msg) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(msg);
  } else {
    console.warn('WebSocket is not open, message not sent');
  }
} 