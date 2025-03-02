let currentApp = null;
let cleanupTimer = null;

export function make_app_global(app) {
  // Store the current app instance
  currentApp = app;
  
  // Make the app instance available globally
  window.__gleam_app = app;
  
  // Also store it on the container element
  const container = document.querySelector('[data-lustre-app="form-analyzer"]');
  if (container) {
    container._gleam_app = app;
    container.setAttribute('data-app-status', 'mounted');
  }
  
  return null;
}

export function cleanup_app() {
  // Clear any pending cleanup
  if (cleanupTimer) {
    clearTimeout(cleanupTimer);
    cleanupTimer = null;
  }

  // Clean up the app instance
  const container = document.querySelector('[data-lustre-app="form-analyzer"]');
  if (container) {
    container._gleam_app = null;
    container.setAttribute('data-app-status', 'unmounted');
  }
  
  // Clear global references
  if (window.__gleam_app === currentApp) {
    window.__gleam_app = null;
  }
  currentApp = null;
  
  // Force a cleanup after a short delay to ensure all references are cleared
  cleanupTimer = setTimeout(() => {
    const container = document.querySelector('[data-lustre-app="form-analyzer"]');
    if (container) {
      container.innerHTML = '';
    }
  }, 100);
  
  return null;
} 