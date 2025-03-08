import { initBackground } from './bizpay_background.js';

export function setWindowLocation(path) {
  window.location.href = path;
}

// Initialize the background when the page loads
window.addEventListener('load', () => {
  initBackground();
}); 