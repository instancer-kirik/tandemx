// debug-helper.js - Debugging helper script for TandemX
(function() {
  const DEBUG = true; // Set to false to disable all debugging
  const DEBUG_LEVEL = 2; // 0=errors only, 1=warnings, 2=info, 3=verbose
  
  // Styles for console output
  const styles = {
    error: 'color: #ff5555; font-weight: bold;',
    warn: 'color: #ffaa00; font-weight: bold;',
    info: 'color: #55aaff;',
    success: 'color: #55ff55;',
    verbose: 'color: #aaaaaa;',
    api: 'color: #aa55ff;',
    db: 'color: #55ffaa;',
    ui: 'color: #ffaa55;',
  };

  // Create namespaced loggers
  function createLogger(namespace) {
    return {
      error: (...args) => DEBUG && _log('error', namespace, ...args),
      warn: (...args) => DEBUG && DEBUG_LEVEL >= 1 && _log('warn', namespace, ...args),
      info: (...args) => DEBUG && DEBUG_LEVEL >= 2 && _log('info', namespace, ...args),
      success: (...args) => DEBUG && DEBUG_LEVEL >= 2 && _log('success', namespace, ...args),
      verbose: (...args) => DEBUG && DEBUG_LEVEL >= 3 && _log('verbose', namespace, ...args),
      trace: (...args) => DEBUG && DEBUG_LEVEL >= 3 && console.trace(`[${namespace}]`, ...args)
    };
  }

  // Internal log function
  function _log(level, namespace, ...args) {
    const timestamp = new Date().toISOString().slice(11, 19);
    const prefix = `%c[${timestamp}] [${namespace}]`;
    
    switch (level) {
      case 'error':
        console.error(prefix, styles[level], ...args);
        break;
      case 'warn':
        console.warn(prefix, styles[level], ...args);
        break;
      default:
        console.log(prefix, styles[level], ...args);
    }
  }

  // Network request monitoring
  function monitorNetworkRequests() {
    const networkLogger = createLogger('network');
    const originalFetch = window.fetch;
    
    window.fetch = async function(resource, init) {
      const url = typeof resource === 'string' ? resource : resource.url;
      const method = init?.method || 'GET';
      
      networkLogger.info(`${method} ${url}`);
      
      try {
        const response = await originalFetch(resource, init);
        
        // Clone the response to avoid consuming it
        const clonedResponse = response.clone();
        
        // Log response status
        if (response.ok) {
          networkLogger.success(`${response.status} ${method} ${url}`);
        } else {
          networkLogger.error(`${response.status} ${method} ${url}`);
          
          // Try to log response body for error responses
          try {
            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
              const errorBody = await clonedResponse.json();
              networkLogger.error('Response:', errorBody);
            }
          } catch (e) {
            // Ignore errors parsing response
          }
        }
        
        return response;
      } catch (error) {
        networkLogger.error(`Failed ${method} ${url}`, error);
        throw error;
      }
    };
    
    // Also monitor XMLHttpRequest
    const originalXhrOpen = XMLHttpRequest.prototype.open;
    const originalXhrSend = XMLHttpRequest.prototype.send;
    
    XMLHttpRequest.prototype.open = function(method, url) {
      this._debugMethod = method;
      this._debugUrl = url;
      return originalXhrOpen.apply(this, arguments);
    };
    
    XMLHttpRequest.prototype.send = function() {
      const xhr = this;
      networkLogger.info(`XHR ${xhr._debugMethod} ${xhr._debugUrl}`);
      
      xhr.addEventListener('load', function() {
        if (xhr.status >= 200 && xhr.status < 300) {
          networkLogger.success(`XHR ${xhr.status} ${xhr._debugMethod} ${xhr._debugUrl}`);
        } else {
          networkLogger.error(`XHR ${xhr.status} ${xhr._debugMethod} ${xhr._debugUrl}`);
        }
      });
      
      xhr.addEventListener('error', function() {
        networkLogger.error(`XHR failed ${xhr._debugMethod} ${xhr._debugUrl}`);
      });
      
      return originalXhrSend.apply(this, arguments);
    };
  }

  // Expose global debugging helpers
  window.Debug = {
    createLogger,
    loggers: {
      api: createLogger('api'),
      ui: createLogger('ui'),
      db: createLogger('db'),
      auth: createLogger('auth'),
      app: createLogger('app')
    },
    monitorNetworkRequests
  };

  // Add error tracking
  window.addEventListener('error', function(event) {
    createLogger('global').error('Uncaught error:', event.error || event.message);
  });
  
  window.addEventListener('unhandledrejection', function(event) {
    createLogger('global').error('Unhandled promise rejection:', event.reason);
  });

  // Enable network monitoring by default
  if (DEBUG) {
    monitorNetworkRequests();
    console.log('%c[Debug] Debugging enabled at level ' + DEBUG_LEVEL, 'color: #55ff55; font-weight: bold;');
  }
})();