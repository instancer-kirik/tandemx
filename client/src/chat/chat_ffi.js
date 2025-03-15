export function generateId() {
  return Math.random().toString(36).substring(2) + Date.now().toString(36);
}

export function getCurrentTimestamp() {
  return new Date().toISOString();
}

export function initWebSocket(url) {
  const ws = new WebSocket(url);
  return {
    id: generateId(),
    ws
  };
}

export function sendWebSocketMessage(wsId, message) {
  // In a real implementation, you would maintain a map of WebSocket instances
  // and look up the correct one using wsId
  // For now, this is just a placeholder
  console.log('Would send message to WebSocket', wsId, message);
} 