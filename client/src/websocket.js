// Websocket connection for server communication
let socket = null;

// Initialize WebSocket connection
function initializeWebSocket() {
  // Use REST API instead of WebSocket if not available in environment
  if (!window.WebSocket) {
    console.warn("WebSockets not available in this browser. Using REST API fallback.");
    return;
  }
  
  // Create WebSocket connection
  const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const wsUrl = `${wsProtocol}//${window.location.host}/ws/cart`;
  
  socket = new WebSocket(wsUrl);
  
  // Connection opened
  socket.addEventListener('open', (event) => {
    console.log('WebSocket connection established');
    // Send sync message to get latest cart state
    send("sync:");
  });
  
  // Listen for messages
  socket.addEventListener('message', (event) => {
    console.log('Message from server:', event.data);
    // Process the cart state message - will be handled by Gleam
  });
  
  // Connection closed
  socket.addEventListener('close', (event) => {
    console.log('WebSocket connection closed');
    socket = null;
    // Try to reconnect after a delay
    setTimeout(initializeWebSocket, 3000);
  });
  
  // Connection error
  socket.addEventListener('error', (event) => {
    console.error('WebSocket error:', event);
    socket = null;
  });
}

// Send message to server via WebSocket or fall back to REST API
export function send(msg) {
  // If WebSocket is connected, use it
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(msg);
    return true;
  }
  
  // Otherwise use REST API fallback
  console.log('Using REST API fallback for:', msg);
  
  // Parse the message
  const parts = msg.split(':');
  const action = parts[0];
  const data = parts.slice(1).join(':');
  
  // Send as REST API call
  fetch(`/api/cart/${action}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ data }),
  })
  .then(response => response.json())
  .then(data => {
    console.log('REST API response:', data);
    // Simulate a WebSocket message from server
    const event = new CustomEvent('message', { 
      detail: {
        data: `state|${JSON.stringify(data.cart.items)}` 
      }
    });
    window.dispatchEvent(event);
  })
  .catch(error => {
    console.error('Error with REST API:', error);
  });
  
  return true;
}

// Initialize WebSocket when page loads
if (typeof window !== 'undefined') {
  window.addEventListener('DOMContentLoaded', initializeWebSocket);
  
  // Retry connection when window comes back online
  window.addEventListener('online', () => {
    if (!socket) {
      initializeWebSocket();
    }
  });
} 