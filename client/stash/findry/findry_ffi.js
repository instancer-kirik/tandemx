// Get the WebSocket URL for real-time updates
export function getWebSocketUrl() {
  if (typeof window === 'undefined') {
    console.log('Window not available, returning default WebSocket URL');
    return 'ws://localhost:3000/ws/findry';
  }
  
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const host = window.location.hostname === '0.0.0.0' ? 'localhost' : window.location.hostname;
  return `${protocol}//${host}:${window.location.port}/ws/findry`;
}

// Initialize the Findry module
export function init() {
  console.log('Findry FFI module loaded');
  // Additional initialization code can be added here
  return true;
}

// Dispatch events to the Findry system
export function dispatch(event) {
  console.log('Dispatching event to Findry:', event);
  // Implement actual event dispatch logic here
  return true;
}

// Handle changes from the Findry system
export function onChange(callback) {
  console.log('Setting up change listener for Findry');
  // In a real implementation, this would set up event listeners
  // and call the callback when changes occur
  return true;
}

// Handle input events in the Findry system
export function onInput(callback) {
  console.log('Setting up input listener for Findry');
  // In a real implementation, this would set up input event listeners
  // and call the callback when input events occur
  return true;
}

// Get the current window width
export function getWindowWidth() {
  if (typeof window === 'undefined') {
    console.log('Window not available, returning default width');
    return 1024; // Return a default width
  }
  return window.innerWidth;
} 