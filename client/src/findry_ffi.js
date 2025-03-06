export function getWebSocketUrl() {
  return `ws://${window.location.host}/ws/findry`;
}

export function dispatch(msg) {
  // This will be replaced by Lustre's runtime
  console.log('Message dispatched:', msg);
} 