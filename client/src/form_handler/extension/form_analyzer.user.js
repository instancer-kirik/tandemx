// ==UserScript==
// @name        Form Analyzer
// @namespace   TandemX
// @match       *://*/*
// @grant       GM_log
// @grant       window.close
// @grant       window.focus
// @run-at      document-end
// @version     1.0
// @author      TandemX
// @description Form analysis and interaction userscript
// ==/UserScript==

(function() {
  'use strict';
  
  const EXTENSION_ID = 'form-analyzer';
  const APP_ORIGIN = 'http://localhost:8000';
  let isDebug = true;
  let isConnected = false;
  let connectionAttempts = 0;
  const MAX_CONNECTION_ATTEMPTS = 30; // Increased to give more time
  const CONNECTION_RETRY_DELAY = 1000; // Decreased for faster retries
  let messageQueue = [];
  let pingInterval = null;
  
  function debug(...args) {
    if (isDebug) {
      console.log('[Form Analyzer]', ...args);
    }
  }

  // Basic form field analysis
  function analyzeField(field) {
    debug('Analyzing field:', field);
    const fieldInfo = {
      type: field.type || 'text',
      id: field.id,
      name: field.name,
      value: field.value,
      required: field.required,
      disabled: field.disabled,
      placeholder: field.placeholder,
      selector: generateSelector(field)
    };
    debug('Field info:', fieldInfo);
    return fieldInfo;
  }

  // Generate a unique selector for an element
  function generateSelector(element) {
    if (element.id) {
      return `#${element.id}`;
    }
    if (element.name) {
      return `[name="${element.name}"]`;
    }
    // Fallback to position-based selector
    const sameTagSiblings = Array.from(element.parentNode.children)
      .filter(el => el.tagName === element.tagName);
    const index = sameTagSiblings.indexOf(element);
    return `${element.tagName.toLowerCase()}:nth-of-type(${index + 1})`;
  }

  // Analyze all forms on the page
  function analyzeForms() {
    debug('Starting form analysis...');
    const forms = document.forms;
    debug(`Found ${forms.length} forms on the page`);
    
    const analyzedForms = Array.from(forms).map(form => {
      const fields = Array.from(form.elements)
        .filter(el => el.tagName === 'INPUT' || el.tagName === 'SELECT' || el.tagName === 'TEXTAREA')
        .map(analyzeField);
      
      debug(`Analyzed form with ${fields.length} fields`);
      
      return {
        selector: generateSelector(form),
        fields: fields,
        url: window.location.href
      };
    });
    
    debug('Form analysis complete:', analyzedForms);
    return analyzedForms;
  }

  // Update a field value
  function updateField(selector, value) {
    debug('Attempting to update field:', selector, value);
    const field = document.querySelector(selector);
    if (field) {
      field.value = value;
      // Trigger change event
      field.dispatchEvent(new Event('change', { bubbles: true }));
      field.dispatchEvent(new Event('input', { bubbles: true }));
      debug('Field updated successfully');
      return true;
    }
    debug('Field not found:', selector);
    return false;
  }

  // Submit a form
  function submitForm(selector) {
    debug('Attempting to submit form:', selector);
    const form = document.querySelector(selector);
    if (form) {
      form.dispatchEvent(new Event('submit', { bubbles: true }));
      debug('Form submitted successfully');
      return true;
    }
    debug('Form not found:', selector);
    return false;
  }

  // Message handling
  function handleMessage(event) {
    try {
      debug('Received message event:', event.origin);
      
      // Only accept messages from our app
      if (event.origin !== APP_ORIGIN) {
        debug('Ignoring message from non-app origin:', event.origin);
        return;
      }

      const message = event.data;
      if (!message) {
        debug('Ignoring empty message');
        return;
      }

      // Validate message source
      if (!message.source || message.source !== EXTENSION_ID) {
        debug('Ignoring message - invalid source');
        return;
      }

      // Handle Gleam messages
      if (message.$constructor === 'ExtensionMsg') {
        const value = message.$value;
        debug('Processing Gleam message:', value);

        if (value.$constructor === 'AppReady') {
          debug('Received AppReady, establishing connection');
          isConnected = true;
          clearInterval(pingInterval);
          
          // Send Connect message
          sendMessage({
            $constructor: 'ExtensionMsg',
            $value: {
              $constructor: 'Connect',
              $value: window.location.href
            }
          });
          
          processMessageQueue();
          return;
        }

        // Handle other message types...
        switch (value.$constructor) {
          case 'Pong':
            debug('Received pong from app');
            isConnected = true;
            clearInterval(pingInterval);
            processMessageQueue();
            break;

          case 'AnalyzeForms':
            const forms = analyzeForms();
            sendMessage({
              $constructor: 'ExtensionMsg',
              $value: {
                $constructor: 'FormsAnalyzed',
                $value: forms.map(form => ({
                  ...form,
                  url: window.location.href
                }))
              }
            });
            break;
            
          case 'UpdateField':
            const [selector, value] = value.$value;
            const updated = updateField(selector, value);
            sendMessage({
              $constructor: 'ExtensionMsg',
              $value: {
                $constructor: updated ? 'FieldUpdated' : 'Error',
                $value: updated ? [selector, value] : 'Field not found'
              }
            });
            break;
            
          case 'SubmitForm':
            const submitted = submitForm(value.$value);
            sendMessage({
              $constructor: 'ExtensionMsg',
              $value: {
                $constructor: submitted ? 'FormSubmitted' : 'Error',
                $value: submitted ? value.$value : 'Form not found'
              }
            });
            break;

          default:
            debug('Unknown message type:', value.$constructor);
        }
      } else {
        debug('Ignoring non-Gleam message');
      }
    } catch (error) {
      debug('Error handling message:', error);
    }
  }

  function processMessageQueue() {
    debug('Processing message queue:', messageQueue.length);
    while (messageQueue.length > 0) {
      const msg = messageQueue.shift();
      sendMessageImmediate(msg);
    }
  }

  function sendMessageImmediate(msg) {
    try {
      // Convert to Gleam message format
      let gleamMessage;
      switch (msg.type) {
        case 'CONNECTED':
          gleamMessage = {
            $constructor: 'ExtensionMsg',
            $value: {
              $constructor: 'Connect',
              $value: msg.url
            }
          };
          break;
          
        case 'FORMS_ANALYZED':
          gleamMessage = {
            $constructor: 'ExtensionMsg',
            $value: {
              $constructor: 'FormsAnalyzed',
              $value: msg.forms.map(form => ({
                ...form,
                url: msg.url || window.location.href
              }))
            }
          };
          break;
          
        case 'FIELD_UPDATED':
          gleamMessage = {
            $constructor: 'ExtensionMsg',
            $value: {
              $constructor: 'FieldUpdated',
              $value: [msg.selector, msg.value]
            }
          };
          break;
          
        case 'FORM_SUBMITTED':
          gleamMessage = {
            $constructor: 'ExtensionMsg',
            $value: {
              $constructor: 'FormSubmitted',
              $value: msg.selector
            }
          };
          break;
          
        case 'ERROR':
          gleamMessage = {
            $constructor: 'ExtensionMsg',
            $value: {
              $constructor: 'Error',
              $value: msg.error
            }
          };
          break;

        case 'PING':
          // Don't convert ping messages to Gleam format
          gleamMessage = msg;
          break;
          
        default:
          debug('Unknown message type:', msg.type);
          return;
      }
      
      // Always include source ID
      const message = {
        source: EXTENSION_ID,
        ...(msg.type === 'PING' ? msg : gleamMessage)
      };

      debug('Sending message:', message);
      window.postMessage(message, APP_ORIGIN);
    } catch (error) {
      debug('Error sending message:', error);
    }
  }

  function sendMessage(msg) {
    if (!isConnected) {
      debug('App not ready, queueing message:', msg);
      messageQueue.push(msg);
      return;
    }
    sendMessageImmediate(msg);
  }

  function attemptConnection() {
    debug('Attempting connection...');
    if (connectionAttempts >= MAX_CONNECTION_ATTEMPTS) {
      debug('Max connection attempts reached');
      clearInterval(pingInterval);
      return;
    }

    connectionAttempts++;
    
    try {
      // Send a simpler ping message first
      window.postMessage({
        source: EXTENSION_ID,
        type: 'PING'
      }, APP_ORIGIN);
      
      debug('Sent ping, attempt:', connectionAttempts);
    } catch (error) {
      debug('Error during connection attempt:', error);
    }
  }

  // Initialize
  function init() {
    try {
      debug('Initializing Form Analyzer userscript...');
      debug('Current URL:', window.location.href);
      debug('Current Origin:', window.location.origin);
      debug('Target App Origin:', APP_ORIGIN);
      debug('Is iframe:', window !== window.top);
      
      // Listen for messages from the app
      window.addEventListener('message', handleMessage);
      
      // Start periodic ping attempts
      pingInterval = setInterval(attemptConnection, CONNECTION_RETRY_DELAY);
      
      // Start first attempt immediately
      attemptConnection();
      
      debug('Form Analyzer userscript initialized');
    } catch (error) {
      debug('Error during initialization:', error);
    }
  }

  // Start the script with a small delay to ensure page is ready
  setTimeout(init, 1000);
})(); 