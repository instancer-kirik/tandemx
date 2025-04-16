// Simple navigation function for the landing page
export function setWindowLocation(path) {
  // For in-app navigation, use the app's navigation event system
  if (path.startsWith('/')) {
    // Create and dispatch a custom event for navigation
    const event = new CustomEvent('app:navigate', {
      detail: { path }
    });
    document.dispatchEvent(event);
    return;
  }
  
  // For external links, use standard location change
  window.location.href = path;
}

// Initialize any landing page specific functionality
export function initLanding() {
  console.log("Landing page initialized");
  return true;
} 