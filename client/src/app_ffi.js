// Simple app FFI for core functionality
let initialized = false;

// Initialize the application
export function init() {
  if (initialized) return true;
  
  console.log('App FFI initialized');
  
  // Only run browser-specific code if document exists
  if (typeof document !== 'undefined') {
    // Setup the core functionality
    setupToastNotifications();
    setupNavToggle();
    setupCalendarObserver();
  }
  
  initialized = true;
  return true;
}

// Get current window location path
export function getWindowLocation() {
  if (typeof window === 'undefined') {
    return '/';
  }
  return window.location.pathname;
}

// Set up navigation listener
export function setupNavigationListener(callback) {
  if (typeof document === 'undefined' || typeof window === 'undefined') {
    console.log('Document or window not available, skipping navigation listener setup');
    return false;
  }

  // Handle link clicks
  document.addEventListener('click', e => {
    const link = e.target.closest('a');
    if (link) {
      const href = link.getAttribute('href');
      if (href && href.startsWith('/') && !href.includes('://')) {
        e.preventDefault();
        console.log('Navigation intercepted for:', href);
        window.history.pushState({}, '', href);
        callback(href);
      }
    }
  });
  
  // Handle back/forward
  window.addEventListener('popstate', () => {
    const path = window.location.pathname;
    console.log('Popstate event, navigating to:', path);
    callback(path);
  });
  
  return true;
}

// Setup custom event listener
export function setupCustomEventListener(callback) {
  if (typeof window === 'undefined') {
    console.log('Window not available, skipping custom event listener setup');
    return false;
  }

  window.addEventListener('navigate', event => {
    if (event.detail && event.detail.path) {
      callback(event.detail.path);
    }
  });
  
  return true;
}

// Navigate to a path
export function navigate(path) {
  if (typeof window === 'undefined') {
    console.log('Window not available, skipping navigation to:', path);
    return false;
  }
  console.log('Navigating to:', path);
  window.history.pushState({}, '', path);
  // Dispatch a custom navigation event
  const event = new CustomEvent('navigate', { detail: { path } });
  window.dispatchEvent(event);
  return true;
}

// Navigate to Vendure storefront
export function navigateToVendure(path) {
  if (typeof window === 'undefined') {
    console.log('Window not available, skipping Vendure navigation to:', path);
    return false;
  }

  // Redirect to Vendure store
  if (window.location.hostname === "localhost") {
    window.location.href = `http://localhost:5173${path}`;
  } else {
    // Production URL - update this with your actual domain
    window.location.href = `https://store.yourdomain.com${path}`;
  }
  return true;
}

// Toggle the navigation menu
export function toggleNav() {
  if (typeof document === 'undefined') {
    console.log('Document not available, skipping nav toggle');
    return false;
  }

  const appContainer = document.querySelector('.app-container');
  if (appContainer) {
    appContainer.classList.toggle('nav-open');
  }
  return true;
}

// Set up toast notifications
function setupToastNotifications() {
  if (typeof window === 'undefined' || typeof document === 'undefined') {
    return;
  }

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
  if (typeof document === 'undefined') {
    return;
  }

  document.addEventListener('click', (event) => {
    if (event.target.closest('.nav-toggle')) {
      // Toggle the nav-open class on the app-container element
      const appContainer = document.querySelector('.app-container');
      if (appContainer) {
        appContainer.classList.toggle('nav-open');
        console.log('Toggled nav-open class on app-container');
      }
      
      // Also toggle the open class on the navbar for compatibility
      const navbar = document.querySelector('.navbar');
      if (navbar) {
        navbar.classList.toggle('open');
        console.log('Toggled open class on navbar');
      }
    }
  });
}

// Initialize calendar when the container is present
function initCalendar() {
  if (typeof document === 'undefined') {
    return;
  }

  const calendarContainer = document.querySelector('[data-init-calendar="true"]');
  if (calendarContainer) {
    console.log('Initializing calendar');
    // Import and initialize the calendar module
    import('/src/calendar_ffi.js').then(module => {
      if (module.initCalendarWithAppEntrypoint) {
        module.initCalendarWithAppEntrypoint();
      }
    }).catch(err => {
      console.error('Failed to load calendar module:', err);
    });
  }
}

// Set up mutation observer to watch for calendar container
function setupCalendarObserver() {
  if (typeof document === 'undefined') {
    return;
  }

  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.addedNodes.length) {
        const calendarContainer = document.querySelector('[data-init-calendar="true"]');
        if (calendarContainer) {
          initCalendar();
          observer.disconnect();
        }
      }
    });
  });

  observer.observe(document.body, { childList: true, subtree: true });
}

// Handle sharing content
export function shareContent(title, text, url) {
  if (typeof window === 'undefined' || typeof navigator === 'undefined') {
    console.log('Window or navigator not available, skipping share');
    return false;
  }

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
  return true;
}

// Helper to determine if a URL is an external resource
function isExternalResource(url) {
  // Check file extensions that should be loaded as resources
  const resourceExtensions = ['.css', '.js', '.jpg', '.jpeg', '.png', '.gif', '.svg', '.pdf'];
  return resourceExtensions.some(ext => url.endsWith(ext));
}

// Setup lazy loading for additional modules
function setupLazyLoading() {
  if (typeof document === 'undefined') {
    return;
  }

  // The modules will be loaded when they are needed
  const modulesToLoad = {
    '/events': () => import('/events/events_ffi.js'),
    '/calendar': () => import('/src/calendar_ffi.js'),
    '/findry': () => import('/findry/findry_ffi.js')
  };
  
  // Listen for route changes to load modules
  document.addEventListener('app:navigate', (event) => {
    if (event.detail && event.detail.path) {
      const path = event.detail.path;
      
      // Check if we need to load a module for this path
      Object.keys(modulesToLoad).forEach(route => {
        if (path.startsWith(route)) {
          // Load the module
          modulesToLoad[route]().catch(err => {
            console.warn(`Failed to load module for ${route}:`, err);
          });
        }
      });
    }
  });
}

// Get the WebSocket URL for real-time updates
export function getWebSocketUrl() {
  if (typeof window === 'undefined') {
    console.log('Window not available, returning default WebSocket URL');
    return 'ws://localhost:8000/ws/cart';
  }
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const host = window.location.hostname === '0.0.0.0' ? 'localhost' : window.location.hostname;
  return `${protocol}//${host}:${window.location.port}/ws/cart`;
}

// Initialize the cart module
export function initCart() {
  console.log('Cart FFI module loaded');
  initializeWebSocket();
  return true;
}

// WebSocket connection for cart synchronization
let socket = null;

// Initialize WebSocket connection
function initializeWebSocket() {
  if (!window.WebSocket) {
    console.warn("WebSockets not available in this browser");
    return;
  }

  const wsUrl = getWebSocketUrl();
  socket = new WebSocket(wsUrl);

  socket.addEventListener('open', (event) => {
    console.log('Cart WebSocket connection established');
    // Request initial cart state
    send("sync:");
  });

  socket.addEventListener('message', (event) => {
    console.log('Cart update received:', event.data);
    // Dispatch event for cart updates
    const cartEvent = new CustomEvent('cartUpdate', {
      detail: { data: event.data }
    });
    window.dispatchEvent(cartEvent);
  });

  socket.addEventListener('close', (event) => {
    console.log('Cart WebSocket connection closed');
    // Try to reconnect after a delay
    setTimeout(initializeWebSocket, 3000);
  });

  socket.addEventListener('error', (event) => {
    console.error('Cart WebSocket error:', event);
  });
}

// Send message to server via WebSocket
export function send(msg) {
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(msg);
    return true;
  } else {
    console.error('Cart WebSocket is not connected');
    if (!socket) {
      initializeWebSocket();
    }
    return false;
  }
}

// Add item to cart
export function addToCart(productId, title, price) {
  console.log('Adding to cart:', { productId, title, price });
  const msg = `add:${productId}:${title}:${price}`;
  return send(msg);
}

// Remove item from cart
export function removeFromCart(productId) {
  console.log('Removing from cart:', productId);
  const msg = `remove:${productId}`;
  return send(msg);
}

// Update item quantity
export function updateQuantity(productId, quantity) {
  console.log('Updating quantity:', { productId, quantity });
  const msg = `update:${productId}:${quantity}`;
  return send(msg);
} 