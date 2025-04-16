// Cart FFI - Interface between the Gleam cart module and JavaScript
import * as $cart from './cart.mjs';

// Initialize the cart application
export function initializeApp() {
  // Get or create the cart root element
  const cartRoot = getCartRoot();
  
  // Clear any existing content
  cartRoot.innerHTML = '';
  
  // Import and set up the cart module
  setupModule();
}

// Get the cart root element
function getCartRoot() {
  let cartRoot = document.getElementById('cart-root');
  if (!cartRoot) {
    cartRoot = createCartRoot();
  }
  return cartRoot;
}

// Create the cart root element if it doesn't exist
function createCartRoot() {
  const cartRoot = document.createElement('div');
  cartRoot.id = 'cart-root';
  
  // Try to find the cart container in the page
  const cartContainer = document.querySelector('.cart-page');
  if (cartContainer) {
    // Insert at the beginning of the cart page
    if (cartContainer.firstChild) {
      cartContainer.insertBefore(cartRoot, cartContainer.firstChild);
    } else {
      cartContainer.appendChild(cartRoot);
    }
  } else {
    // Fallback to body if .cart-page isn't found
    document.body.appendChild(cartRoot);
  }
  
  return cartRoot;
}

// Setup the cart module
export function setupModule() {
  // Initialize the Lustre application with the cart module
  const app = $cart.main();
  
  // Start the application in the cart-root element
  app.start(document.getElementById('cart-root'));
  
  // Return the app instance for potential further manipulation
  return app;
}

// WebSocket connection for cart synchronization
let socket = null;

// Initialize WebSocket connection
export function initializeWebSocket() {
  // Create WebSocket connection
  socket = new WebSocket(`ws://${window.location.host}/ws/cart`);
  
  // Connection opened
  socket.addEventListener('open', (event) => {
    console.log('WebSocket connection established');
  });
  
  // Listen for messages
  socket.addEventListener('message', (event) => {
    // Process the cart state from the server
    const cartStateMsg = event.data;
    
    // Update the cart state in the Gleam module
    if (cartStateMsg.startsWith('state|')) {
      $cart.receiveServerMsg(cartStateMsg);
    }
  });
  
  // Connection closed
  socket.addEventListener('close', (event) => {
    console.log('WebSocket connection closed');
    // Try to reconnect after a delay
    setTimeout(initializeWebSocket, 3000);
  });
  
  // Connection error
  socket.addEventListener('error', (event) => {
    console.error('WebSocket error:', event);
  });
}

// Send message to server via WebSocket
export function send(msg) {
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(msg);
    return true;
  } else {
    console.error('WebSocket is not connected');
    // Initialize WebSocket if not already done
    if (!socket) {
      initializeWebSocket();
    }
    return false;
  }
}

// Function to add an item to cart programmatically
export function addToCart(id, title, price) {
  // Directly call the Gleam function to add an item
  $cart.addToCart(id, title, price);
}

// Initialize WebSocket when the page loads
if (typeof window !== 'undefined') {
  window.addEventListener('DOMContentLoaded', initializeWebSocket);
} 