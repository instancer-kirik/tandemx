// Extension bridge using window.postMessage
const EXTENSION_ID = 'form-analyzer';
const APP_ORIGIN = 'http://localhost:8000';
let isConnected = false;
let isDebug = true;
let messageQueue = [];
let app = null;
let initializationTimer = null;
let maxInitAttempts = 50;  // 5 seconds total
let currentInitAttempt = 0;

// Form element types
const ElementTypes = {
  CLICKABLE: 'clickable',
  TYPEABLE: 'typeable',
  SELECTABLE: 'selectable',
  SUBMITTABLE: 'submittable'
};

// Form interaction types
const InteractionTypes = {
  CLICK: 'click',
  TYPE: 'type',
  SELECT: 'select',
  SUBMIT: 'submit'
};

function debug(...args) {
  if (isDebug) {
    console.log('[Form Analyzer Bridge]', ...args);
  }
}

function validateMessage(message) {
  if (!message) return false;
  if (!message.$constructor) return false;
  if (message.$constructor !== 'ExtensionMsg') return false;
  if (!message.$value || !message.$value.$constructor) return false;
  return true;
}

// Initialize the app reference
function initializeApp() {
  debug('Extension bridge initialized, waiting for Gleam app...');
  
  // Try to find the app container
  const appContainer = document.querySelector('[data-lustre-app="form-analyzer"]');
  if (!appContainer) {
    debug('App container not found');
    return false;
  }

  // Check container visibility
  const isVisible = appContainer.offsetParent !== null && 
                   window.getComputedStyle(appContainer).display !== 'none';
  debug('Container visibility:', isVisible);
  if (!isVisible) {
    debug('Container is not visible');
    return false;
  }
  
  // Check container status
  const status = appContainer.getAttribute('data-app-status');
  debug('Container found with status:', status);
  if (status !== 'initializing' && status !== 'mounted') {
    debug('Container not ready');
    return false;
  }
  
  // Check for Lustre app instance
  const lustreApp = appContainer._gleam_app || window.__gleam_app;
  if (lustreApp && typeof lustreApp.dispatch === 'function') {
    app = lustreApp;
    debug('Gleam app found and ready');
    debug('Message queue size:', messageQueue.length);
    processMessageQueue();
    return true;
  }
  
  debug('Lustre app not ready');
  return false;
}

// Start initialization after DOM is ready and route is active
function startInitialization() {
  // Clear any existing timer
  if (initializationTimer) {
    clearTimeout(initializationTimer);
    initializationTimer = null;
  }

  // Check if we've exceeded max attempts
  if (currentInitAttempt >= maxInitAttempts) {
    debug('Max initialization attempts reached, giving up');
    return;
  }

  currentInitAttempt++;
  debug(`Starting bridge initialization (attempt ${currentInitAttempt}/${maxInitAttempts})...`);
  
  // Check if we're on the correct route
  const currentRoute = document.body.getAttribute('data-current-route');
  const pathname = window.location.pathname.slice(1);
  const hash = window.location.hash;
  
  if (currentRoute !== 'form-analyzer' && pathname !== 'form-analyzer' && hash !== '#/form-analyzer') {
    debug('Not on form analyzer route:', { currentRoute, pathname, hash });
    initializationTimer = setTimeout(startInitialization, 200);
    return;
  }

  // Try to initialize
  if (!initializeApp()) {
    debug('Initialization failed, retrying in 200ms...');
    initializationTimer = setTimeout(startInitialization, 200);
    return;
  }

  debug('Bridge initialization complete');
  currentInitAttempt = 0; // Reset for next time
}

// Reset initialization state when route changes
function handleRouteChange() {
  currentInitAttempt = 0;
  if (initializationTimer) {
    clearTimeout(initializationTimer);
    initializationTimer = null;
  }
  startInitialization();
}

// Start initialization
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', startInitialization);
} else {
  startInitialization();
}

// Listen for route changes
window.addEventListener('hashchange', handleRouteChange);

// Process queued messages when app becomes available
function processMessageQueue() {
  debug('Processing message queue:', messageQueue.length);
  while (messageQueue.length > 0) {
    const message = messageQueue.shift();
    debug('Processing queued message:', message);
    try {
      app.dispatch(message);
      debug('Message dispatched successfully');
    } catch (error) {
      debug('Error dispatching message:', error);
      messageQueue.push(message); // Re-queue failed messages
      break;
    }
  }
}

// Send a message through the bridge
export function send_message(message) {
  debug('Sending message:', message);
  
  // Parse string messages as JSON
  if (typeof message === 'string') {
    try {
      message = JSON.parse(message);
    } catch (error) {
      debug('Failed to parse message as JSON:', error);
      return false;
    }
  }
  
  // Ensure message has proper structure
  if (!validateMessage(message)) {
    debug('Invalid message structure:', message);
    return false;
  }
  
  // Ensure message has proper source
  message = { ...message, source: EXTENSION_ID };
  
  if (app) {
    debug('Dispatching message to app:', message);
    try {
      app.dispatch(message);
      return true;
    } catch (error) {
      debug('Error dispatching message:', error);
      return false;
    }
  } else {
    debug('App not ready, queueing message:', message);
    messageQueue.push(message);
    return false;
  }
}

// Handle messages from the userscript
function handleMessage(event) {
  debug('Received raw message event:', event.origin);
  
  if (event.origin !== APP_ORIGIN && event.origin !== window.location.origin) {
    debug('Ignoring message - invalid origin');
    return;
  }
  
  const message = event.data;
  if (!message || !message.source || message.source !== EXTENSION_ID) {
    debug('Ignoring message - invalid source or data:', message);
    return;
  }

  // Handle PING message
  if (message.type === 'PING') {
    debug('Received PING, sending Connect message');
    const connectMsg = {
      $constructor: 'ExtensionMsg',
      $value: {
        $constructor: 'Connect',
        $value: window.location.href
      },
      source: EXTENSION_ID
    };
    
    if (app) {
      try {
        app.dispatch(connectMsg);
        debug('Connect message dispatched');
      } catch (error) {
        debug('Error dispatching connect message:', error);
        messageQueue.push(connectMsg);
      }
    } else {
      messageQueue.push(connectMsg);
      debug('Connect message queued');
    }
    isConnected = true;
    return;
  }

  // Handle other messages
  if (validateMessage(message)) {
    if (app) {
      try {
        app.dispatch(message);
        debug('Message dispatched successfully');
      } catch (error) {
        debug('Error dispatching message:', error);
        messageQueue.push(message);
      }
    } else {
      messageQueue.push(message);
      debug('Message queued');
    }
  } else {
    debug('Invalid message format:', message);
  }
}

// Initialize message listener
window.addEventListener('message', handleMessage);

// Form element report format
function createElementReport(element) {
  return {
    type: determineElementType(element),
    id: element.id || null,
    name: element.name || null,
    selector: generateSelector(element),
    value: element.value || null,
    isVisible: isElementVisible(element),
    attributes: getRelevantAttributes(element),
    label: findAssociatedLabel(element)
  };
}

// Form interaction report format
function createInteractionReport(element, interactionType, value = null) {
  return {
    $constructor: 'ExtensionMsg',
    $value: {
      $constructor: 'FormInteraction',
      $value: {
        element: createElementReport(element),
        interaction: {
          type: interactionType,
          value: value,
          timestamp: Date.now()
        }
      }
    }
  };
}

// Helper functions
function determineElementType(element) {
  if (element.tagName === 'BUTTON' || element.tagName === 'A' || 
      (element.tagName === 'INPUT' && element.type === 'button')) {
    return ElementTypes.CLICKABLE;
  }
  if (element.tagName === 'INPUT' && 
      ['text', 'password', 'email', 'number'].includes(element.type)) {
    return ElementTypes.TYPEABLE;
  }
  if (element.tagName === 'SELECT') {
    return ElementTypes.SELECTABLE;
  }
  if (element.tagName === 'INPUT' && element.type === 'submit' || 
      (element.tagName === 'BUTTON' && element.type === 'submit')) {
    return ElementTypes.SUBMITTABLE;
  }
  return null;
}

function generateSelector(element) {
  // Generate a unique CSS selector for the element
  // This is a simplified version - you might want more sophisticated logic
  if (element.id) {
    return `#${element.id}`;
  }
  if (element.name) {
    return `[name="${element.name}"]`;
  }
  // Add more sophisticated selector generation as needed
  return '';
}

function isElementVisible(element) {
  const style = window.getComputedStyle(element);
  return style.display !== 'none' && style.visibility !== 'hidden' && 
         style.opacity !== '0';
}

function getRelevantAttributes(element) {
  const relevantAttrs = ['type', 'placeholder', 'required', 'pattern', 
                        'minlength', 'maxlength', 'min', 'max'];
  const attrs = {};
  for (const attr of relevantAttrs) {
    if (element.hasAttribute(attr)) {
      attrs[attr] = element.getAttribute(attr);
    }
  }
  return attrs;
}

function findAssociatedLabel(element) {
  // Try to find a label that references this element
  if (element.id) {
    const label = document.querySelector(`label[for="${element.id}"]`);
    if (label) {
      return label.textContent.trim();
    }
  }
  // Check for wrapping label
  const parentLabel = element.closest('label');
  if (parentLabel) {
    return parentLabel.textContent.trim();
  }
  return null;
}

// Export functions for use in userscript
export function reportFormElement(element) {
  send_message({
    $constructor: 'ExtensionMsg',
    $value: {
      $constructor: 'FormElement',
      $value: createElementReport(element)
    }
  });
}

export function reportFormInteraction(element, interactionType, value = null) {
  send_message(createInteractionReport(element, interactionType, value));
} 