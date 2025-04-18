// landing_ffi.js - FFI functions for the landing page

// Function to handle navigation
export function navigate(path) {
  window.location.href = path;
  return null; // Return null for Gleam compatibility
}

// Initialize any landing page specific functionality
export function initLanding() {
  console.log("Landing page initialized");
  return true;
} 