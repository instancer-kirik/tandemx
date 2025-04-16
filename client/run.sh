#!/bin/bash

# Check if running in fish shell and adjusting commands accordingly
if [ -n "$FISH_VERSION" ]; then
  echo "Running in fish shell environment"
  SET_VAR="set -g"
  IS_FISH=true
else
  echo "Running in bash/standard shell environment"
  SET_VAR="export"
  IS_FISH=false
fi

# Create app_ffi.js if it doesn't exist
if [ ! -f "src/app_ffi.js" ]; then
  echo "Creating app_ffi.js..."
  cat > src/app_ffi.js << 'EOF'
// Navigation helper
export function navigate(path) {
  window.location.href = path;
}

// Cart integration
export function addToCart(productId) {
  // Dispatch a custom event for cart updates
  const event = new CustomEvent('addToCart', {
    detail: { productId }
  });
  window.dispatchEvent(event);
  console.log(`Added product ${productId} to cart`);
}
EOF
  echo "Created app_ffi.js"
fi

# Build the Gleam application
echo "Building TandemX application..."
gleam build

# Change to the server directory and build the server
echo "Building and starting the Gleam dev server..."
cd ../server
gleam build
gleam run -m dev_server -- --port 8000

# Print info message
echo "Open your browser at http://localhost:8000/" 