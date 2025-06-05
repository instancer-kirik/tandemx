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

// FFI implementations for app.gleam

export function getCurrentUser() {
  // In a real app, you'd interact with Supabase Auth here
  // For now, simulate no user or a specific user
  console.log("FFI: getCurrentUser called (simulating)");
  
  // Create a proper Result object with the format Gleam expects
  const adminUser = {
    id: 'admin-user-777',
    email: 'admin@example.com'
  };
  
  // Create an Option type with isSome/isNone functions
  const someUser = {
    isSome: function() { return true; },
    isNone: function() { return false; },
    value: adminUser
  };
  
  // Return a proper Result object with isOk/isError functions
  // that Gleam can use with pattern matching
  return {
    isOk: function() { return true; },
    isError: function() { return false; },
    value: someUser,
    error: null
  };
}

export function signInWithGitHub() {
  console.log("FFI: signInWithGitHub called (simulating)");
  // In a real app, call Supabase signInWithOAuth({ provider: 'github' })
  // This would redirect. For simulation, we just return Ok.
  
  // Return a proper Result object with isOk/isError functions
  return {
    isOk: function() { return true; },
    isError: function() { return false; },
    value: null,
    error: null
  };
}

export function signOutUser() {
  console.log("FFI: signOutUser called (simulating)");
  // In a real app, call Supabase auth.signOut()
  
  // Return a proper Result object with isOk/isError functions
  return {
    isOk: function() { return true; },
    isError: function() { return false; },
    value: null,
    error: null
  };
}

// FFI function to get the current browser path
export function getCurrentPath() {
  console.log(`FFI: getCurrentPath called, path is: ${window.location.pathname}`);
  return window.location.pathname;
} 