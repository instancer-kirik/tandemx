// Initialize the Vendure store when the DOM is fully loaded
if (typeof document !== 'undefined') {
  document.addEventListener('DOMContentLoaded', function() {
    console.log('Vendure Store DOM content loaded');
    
    // Check if we're on the store route
    const currentPath = window.location.pathname;
    if (currentPath.includes('/store')) {
      console.log('Initializing Vendure store');
      
      // Create the store container if it doesn't exist
      let storeRoot = document.getElementById('vendure-store-root');
      if (!storeRoot) {
        storeRoot = document.createElement('div');
        storeRoot.id = 'vendure-store-root';
        storeRoot.className = 'vendure-store-container';
        document.body.appendChild(storeRoot);
      }
      
      // Load the Vendure store
      import('/build/dev/javascript/tandemx_client/vendure_store.mjs')
        .then(() => {
          console.log('Vendure store loaded');
          // Initialize the store
          window.vendureStore.init(storeRoot);
        })
        .catch(err => {
          console.error('Error loading Vendure store:', err);
        });
    }
  });
}

// Export the main function for Gleam
export function main() {
  console.log('Initializing Vendure store module');
  
  if (typeof document === 'undefined') {
    console.log('Document not available. Skipping Vendure store initialization.');
    return;
  }
  
  // Check if we're on the store route
  const currentPath = window.location.pathname;
  if (!currentPath.includes('/store')) {
    console.log('Not on store route, skipping initialization');
    return;
  }
  
  // Create or get the store container
  let storeRoot = document.getElementById('vendure-store-root');
  if (!storeRoot) {
    storeRoot = document.createElement('div');
    storeRoot.id = 'vendure-store-root';
    storeRoot.className = 'vendure-store-container';
    document.body.appendChild(storeRoot);
  }
  
  // Load and initialize the Vendure store
  import('/build/dev/javascript/tandemx_client/vendure_store.mjs')
    .then(() => {
      console.log('Vendure store loaded');
      window.vendureStore.init(storeRoot);
    })
    .catch(err => {
      console.error('Error loading Vendure store:', err);
    });
  
  return { type: 'none' };
} 