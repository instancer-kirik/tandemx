// Main application FFI functions
let initialized = false;
let navigationCallback = null;

// Store the callback in window to ensure it persists
if (typeof window !== 'undefined') {
  window.tandemxNavigationCallback = window.tandemxNavigationCallback || null;
}

// Initialize the application
export function init() {
  if (initialized) {
    console.log('App FFI already initialized, skipping');
    // Restore callback from window if available
    if (window.tandemxNavigationCallback && !navigationCallback) {
      navigationCallback = window.tandemxNavigationCallback;
      console.log('Restored navigation callback from window');
    }
    return true;
  }
  
  // Set up event listeners for navigation
  window.addEventListener('popstate', (event) => {
    console.log('Popstate event triggered, path:', window.location.pathname);
    // Call the navigation callback if it exists
    if (navigationCallback || window.tandemxNavigationCallback) {
      const callback = navigationCallback || window.tandemxNavigationCallback;
      console.log('Calling navigation callback with path:', window.location.pathname);
      callback(window.location.pathname);
    } else {
      console.warn('Navigation callback not set yet, cannot handle popstate');
      // Try to recover by dispatching a custom event
      const event = new CustomEvent('tandemx-navigate', { 
        detail: { path: window.location.pathname } 
      });
      window.dispatchEvent(event);
      console.log('Dispatched tandemx-navigate event as fallback for popstate');
    }
  });

  // Initialize toast notifications
  setupToastNotifications();
  
  // Set up navigation toggle
  setupNavToggle();
  
  // Mark as initialized
  initialized = true;
  console.log('App FFI initialized');
  
  // Return success
  return true;
}

// Set up a listener for navigation events
export function setupNavigationListener(callback) {
  console.log('Setting up navigation listener');
  navigationCallback = callback;
  // Store in window for persistence
  if (typeof window !== 'undefined') {
    window.tandemxNavigationCallback = callback;
  }
  console.log('Navigation listener set up successfully');
  
  // Immediately trigger a navigation event for the current path
  // This ensures the view is updated on initial load
  setTimeout(() => {
    console.log('Triggering initial navigation for current path:', window.location.pathname);
    callback(window.location.pathname);
  }, 0);
  
  return true;
}

// Set up a listener for the custom tandemx-navigate event
export function setupCustomEventListener(callback) {
  console.log('Setting up custom event listener for tandemx-navigate');
  window.addEventListener('tandemx-navigate', function(event) {
    console.log('Received tandemx-navigate event:', event.detail.path);
    callback(event.detail.path);
  });
  console.log('Custom event listener set up successfully');
  return true;
}

// Get the current window location path
export function getWindowLocation() {
  console.log('Getting window location:', window.location.pathname);
  return window.location.pathname;
}

// Set up toast notifications
function setupToastNotifications() {
  window.showToast = (message, type = 'success', duration = 3000) => {
    const toastContainer = document.getElementById('toast-container');
    
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    
    const messageSpan = document.createElement('span');
    messageSpan.textContent = message;
    
    const closeButton = document.createElement('button');
    closeButton.className = 'toast-close';
    closeButton.textContent = '×';
    closeButton.addEventListener('click', () => {
      toast.remove();
    });
    
    toast.appendChild(messageSpan);
    toast.appendChild(closeButton);
    toastContainer.appendChild(toast);
    
    setTimeout(() => {
      toast.classList.add('toast-hide');
      setTimeout(() => {
        toast.remove();
      }, 300);
    }, duration);
  };
}

// Set up navigation toggle
function setupNavToggle() {
  document.addEventListener('click', (event) => {
    if (event.target.closest('.nav-toggle')) {
      document.body.classList.toggle('nav-open');
      const navbar = document.querySelector('.navbar');
      if (navbar) {
        navbar.classList.toggle('open');
      }
    }
  });
  
  // Handle all internal navigation links
  document.addEventListener('click', (event) => {
    const link = event.target.closest('a[href]');
    if (link && link.getAttribute('href').startsWith('/')) {
      // Don't intercept external links or links with target="_blank"
      if (link.getAttribute('target') === '_blank' || link.getAttribute('href').startsWith('http')) {
        return;
      }
      
      event.preventDefault();
      const path = link.getAttribute('href');
      console.log('Link clicked, navigating to:', path);
      navigate(path);
      
      // Close the navigation on mobile after clicking a link
      if (window.innerWidth < 768) {
        document.body.classList.remove('nav-open');
        const navbar = document.querySelector('.navbar');
        if (navbar) {
          navbar.classList.remove('open');
        }
      }
    }
  });
}

// Handle navigation
export function navigate(path) {
  console.log('Navigate function called with path:', path);
  
  // Use traditional navigation - actually change the page
  window.location.href = path;
}

// Handle sharing content
export function shareContent(title, text, url) {
  if (navigator.share) {
    navigator.share({
      title: title,
      text: text,
      url: url,
    })
    .then(() => window.showToast('Shared successfully!'))
    .catch((error) => window.showToast('Error sharing: ' + error, 'error'));
  } else {
    // Fallback for browsers that don't support the Web Share API
    navigator.clipboard.writeText(url)
      .then(() => window.showToast('Link copied to clipboard!'))
      .catch(() => window.showToast('Failed to copy link', 'error'));
  }
}

// Initialize when the module is imported
document.addEventListener('DOMContentLoaded', () => {
  console.log('App FFI module loaded');
  init(); // Initialize the app when the DOM is loaded
}); 