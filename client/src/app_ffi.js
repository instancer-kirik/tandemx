// app_ffi.js - FFI functions for the main app

// Initialize the application
function init() {
  console.log('Initializing TandemX application from app_ffi.js');
  return null;
}

// Make init function globally available
window.app_ffi = {
  init: init,
  navigate: navigate,
  showToast: showToast
};

// Navigate to a new route
function navigate(path) {
  console.log(`Navigating to: ${path}`);
  
  // Use history API for internal navigation
  if (!path.startsWith('http')) {
    window.history.pushState({}, '', path);
    // Additional routing logic would go here in a real app
    return null;
  }
  
  // Open external links in a new tab
  window.open(path, '_blank');
  return null;
}

// Show a toast notification
function showToast(message, type = 'info') {
  console.log(`Toast (${type}): ${message}`);
  
  // In a real app, this would display a visible toast notification
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  
  const container = document.getElementById('toast-container') || document.body;
  container.appendChild(toast);
  
  // Remove after 3 seconds
  setTimeout(() => {
    toast.classList.add('toast-hiding');
    setTimeout(() => {
      toast.remove();
    }, 300);
  }, 3000);
  
  return null;
} 