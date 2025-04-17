#!/bin/bash

# Color for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting TandemX client setup...${NC}"

# Default settings
SKIP_DB=false
ELECTRIC_PORT=5133
POSTGRES_PORT=54321

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --skip-db) SKIP_DB=true; shift ;;
    --electric-port) ELECTRIC_PORT="$2"; shift 2 ;;
    --postgres-port) POSTGRES_PORT="$2"; shift 2 ;;
    *) 
      # Handle port argument from the server directly
      if [[ "$1" == "--port" && "$#" -gt 1 ]]; then
        SERVER_PORT="$2"
        shift 2
      else
        echo "Unknown parameter: $1"; exit 1
      fi
    ;;
  esac
done

# Default port if not specified
SERVER_PORT=${SERVER_PORT:-8000}

if [ "$SKIP_DB" = true ]; then
  echo -e "${YELLOW}Database sync is disabled. Running in standalone mode.${NC}"
else
  # Check if Docker is running
  if command -v docker &> /dev/null; then
    if ! docker info &> /dev/null; then
      echo -e "${RED}Docker is not running. Please start Docker first.${NC}"
      echo -e "${YELLOW}Note: The ElectricSQL database requires Docker to be running.${NC}"
      echo -e "${YELLOW}You can continue with --skip-db flag to run without database.${NC}"
      echo -e "${YELLOW}Proceed anyway? This will disable database features. (y/n)${NC}"
      read -r proceed
      if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Setup aborted.${NC}"
        exit 1
      fi
      SKIP_DB=true
    else
      # Check if ElectricSQL container is running
      if ! docker ps | grep -q electric; then
        echo -e "${YELLOW}ElectricSQL container not detected.${NC}"
        echo -e "${YELLOW}Do you want to start the database services? (y/n)${NC}"
        read -r start_db
        if [[ "$start_db" =~ ^[Yy]$ ]]; then
          echo -e "${GREEN}Starting ElectricSQL services...${NC}"
          cd .. && docker-compose up -d
          echo -e "${YELLOW}Waiting for services to start...${NC}"
          sleep 8  # Increased wait time for services to fully initialize
          cd - > /dev/null
          
          # Verify Electric service is running and responding
          echo -e "${YELLOW}Verifying ElectricSQL service...${NC}"
          if ! curl -s http://localhost:$ELECTRIC_PORT/api/status > /dev/null 2>&1; then
            echo -e "${YELLOW}ElectricSQL service not responding. Will run with database features disabled.${NC}"
            SKIP_DB=true
          else
            echo -e "${GREEN}ElectricSQL services verified and running.${NC}"
            
            # Set environment variables for auth
            export PG_PROXY_PASSWORD=proxy_password
            export DATABASE_URL="postgresql://postgres:password@localhost:$POSTGRES_PORT/tandemx"
            export ELECTRIC_URL="http://localhost:$ELECTRIC_PORT"
            export AUTH_MODE=insecure
          fi
        else
          echo -e "${YELLOW}Continuing without database services. Some features may not work.${NC}"
          SKIP_DB=true
        fi
      else
        echo -e "${GREEN}ElectricSQL services detected and running.${NC}"
        
        # Set environment variables for auth
        export PG_PROXY_PASSWORD=proxy_password
        export DATABASE_URL="postgresql://postgres:password@localhost:$POSTGRES_PORT/tandemx"
        export ELECTRIC_URL="http://localhost:$ELECTRIC_PORT"
        export AUTH_MODE=insecure
      fi
    fi
  else
    echo -e "${YELLOW}Docker not found. The database services will not be available.${NC}"
    echo -e "${YELLOW}Running with database features disabled.${NC}"
    SKIP_DB=true
  fi
fi

# Check if running in fish shell and adjusting commands accordingly
if [ -n "$FISH_VERSION" ]; then
  echo -e "${YELLOW}Running in fish shell environment${NC}"
  SET_VAR="set -g"
  IS_FISH=true
else
  echo -e "${YELLOW}Running in bash/standard shell environment${NC}"
  SET_VAR="export"
  IS_FISH=false
fi

# Create app_ffi.js if it doesn't exist
if [ ! -f "src/app_ffi.js" ]; then
  echo -e "${YELLOW}Creating app_ffi.js...${NC}"
  cat > src/app_ffi.js << 'EOF'
// Navigation helper
export function navigate(path) {
  window.location.href = path;
}

// Initialize application
export function init() {
  console.log("Initializing app...");
  return true;
}

// Get window location
export function getWindowLocation() {
  return window.location.pathname;
}

// Setup navigation listener
export function setupNavigationListener(callback) {
  window.addEventListener('popstate', () => {
    callback(window.location.pathname);
  });
  return true;
}

// Setup custom event listener
export function setupCustomEventListener(callback) {
  window.addEventListener('customnavigate', (event) => {
    callback(event.detail.path);
  });
  return true;
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

// Navigate to Vendure store
export function navigateToVendure(path) {
  console.log(`Navigating to Vendure: ${path}`);
  window.location.href = `/store${path}`;
}
EOF
  echo -e "${GREEN}Created app_ffi.js${NC}"
fi

# Build the Gleam application
echo -e "${GREEN}Building TandemX application...${NC}"
gleam build

# Change to the server directory and build the server
echo -e "${GREEN}Building server...${NC}"
cd ../server
gleam build

# Create a simple file to disable database features
if [ "$SKIP_DB" = true ]; then
  echo -e "${YELLOW}Creating file to disable database features...${NC}"
  echo "Database features disabled by run.sh script" > .disable_db
else
  # Remove the flag file if it exists
  if [ -f ".disable_db" ]; then
    rm .disable_db
  fi
fi

# Check if db_init module exists, and run it if database is enabled
if [ "$SKIP_DB" = false ] && grep -q "db_init" src/*.gleam 2>/dev/null; then
  echo -e "${YELLOW}Initializing database...${NC}"
  gleam run -m db_init || echo -e "${YELLOW}Database initialization skipped or failed. Continuing...${NC}"
fi

# Start the server with appropriate port
echo -e "${YELLOW}Starting server on port ${SERVER_PORT}...${NC}"
gleam run -m dev_server -- --port $SERVER_PORT &

# Store the PID of the server process
SERVER_PID=$!

# Wait a moment to check if the server started successfully
sleep 2
if ! ps -p $SERVER_PID > /dev/null; then
  echo -e "${RED}Server failed to start. Check for errors above.${NC}"
  exit 1
fi

# Function to handle script termination
function cleanup {
  echo -e "${YELLOW}Shutting down services...${NC}"
  if ps -p $SERVER_PID > /dev/null; then
    kill $SERVER_PID
    echo -e "${GREEN}Server stopped.${NC}"
  else
    echo -e "${YELLOW}Server already stopped.${NC}"
  fi
}

# Register the cleanup function for script termination
trap cleanup EXIT

# Print info message
echo -e "${GREEN}TandemX is running!${NC}"
echo -e "Open your browser at ${YELLOW}http://localhost:$SERVER_PORT/${NC}"

if [ "$SKIP_DB" = true ]; then
  echo -e "${YELLOW}Running in standalone mode without database connectivity.${NC}"
  echo -e "${YELLOW}To enable database features, restart without the --skip-db flag${NC}"
  echo -e "${YELLOW}and ensure Docker with ElectricSQL is running.${NC}"
else
  echo -e "${YELLOW}Database features are enabled. If you see subscription errors,${NC}"
  echo -e "${YELLOW}they may be safely ignored for non-database functionality.${NC}"
  echo -e "${YELLOW}To disable database features, restart with the --skip-db flag.${NC}"
fi

echo -e "Press Ctrl+C to stop the server"

# Wait for user to press Ctrl+C
wait 