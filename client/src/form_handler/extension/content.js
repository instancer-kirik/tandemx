// Content script for form analysis
let port = null;

// Basic form field analysis
function analyzeField(field) {
  return {
    type: field.type || 'text',
    id: field.id,
    name: field.name,
    value: field.value,
    required: field.required,
    disabled: field.disabled,
    placeholder: field.placeholder,
    selector: generateSelector(field)
  };
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
  const forms = document.forms;
  return Array.from(forms).map(form => {
    const fields = Array.from(form.elements)
      .filter(el => el.tagName === 'INPUT' || el.tagName === 'SELECT' || el.tagName === 'TEXTAREA')
      .map(analyzeField);
    
    return {
      selector: generateSelector(form),
      fields: fields
    };
  });
}

// Update a field value
function updateField(selector, value) {
  const field = document.querySelector(selector);
  if (field) {
    field.value = value;
    // Trigger change event
    field.dispatchEvent(new Event('change', { bubbles: true }));
    return true;
  }
  return false;
}

// Submit a form
function submitForm(selector) {
  const form = document.querySelector(selector);
  if (form) {
    form.dispatchEvent(new Event('submit', { bubbles: true }));
    return true;
  }
  return false;
}

// Connect to the extension bridge
function connect() {
  port = chrome.runtime.connect({ name: 'form-analyzer' });
  
  port.onMessage.addListener((msg) => {
    switch (msg.type) {
      case 'ANALYZE_FORMS':
        const forms = analyzeForms();
        port.postMessage({ type: 'FORMS_ANALYZED', forms });
        break;
        
      case 'UPDATE_FIELD':
        const updated = updateField(msg.selector, msg.value);
        port.postMessage({ 
          type: updated ? 'FIELD_UPDATED' : 'ERROR',
          selector: msg.selector,
          value: msg.value,
          error: updated ? null : 'Field not found'
        });
        break;
        
      case 'SUBMIT_FORM':
        const submitted = submitForm(msg.selector);
        port.postMessage({ 
          type: submitted ? 'FORM_SUBMITTED' : 'ERROR',
          selector: msg.selector,
          error: submitted ? null : 'Form not found'
        });
        break;
    }
  });
}

// Start connection
connect(); 