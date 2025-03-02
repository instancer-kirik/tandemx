let ws = null;

function connect() {
  ws = new WebSocket('ws://localhost:8000/ws/cart');
  
  ws.onopen = () => {
    console.log('Connected to cart WebSocket');
  };
  
  ws.onmessage = (event) => {
    console.log('Received cart update:', event.data);
  };
  
  ws.onclose = () => {
    console.log('Disconnected from cart WebSocket');
    // Try to reconnect in 1 second
    setTimeout(connect, 1000);
  };
  
  ws.onerror = (error) => {
    console.error('WebSocket error:', error);
  };
}

// Connect when the script loads
connect();

// Export function to send messages
export function send(msg) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(msg);
  } else {
    console.warn('WebSocket not ready, message not sent:', msg);
  }
} 