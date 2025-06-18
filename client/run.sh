#!/bin/bash

# Color for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting TandemX client setup...${NC}"

# Default settings
SKIP_DB=false
USE_TURSO=false
ELECTRIC_PORT=5133
POSTGRES_PORT=54321
TURSO_PORT=8080

# Check if Turso is enabled via environment variable
if [ "$TURSO_DB" = "true" ]; then
  USE_TURSO=true
  # Force database features to be enabled when using Turso
  SKIP_DB=false
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --skip-db) SKIP_DB=true; shift ;;
    --use-turso) USE_TURSO=true; shift ;;
    --electric-port) ELECTRIC_PORT="$2"; shift 2 ;;
    --postgres-port) POSTGRES_PORT="$2"; shift 2 ;;
    --turso-port) TURSO_PORT="$2"; shift 2 ;;
    --port) SERVER_PORT="$2"; shift 2 ;;
    *) shift ;;  # Skip unknown parameters silently
  esac
done

# Default port if not specified
SERVER_PORT=${SERVER_PORT:-8000}

if [ "$USE_TURSO" = true ]; then
  echo -e "${GREEN}Using Turso database...${NC}"
  
  # Load Turso credentials from .env file if it exists
  if [ -f "../.env" ]; then
    source "../.env"
    echo -e "${GREEN}Loaded environment variables from .env file${NC}"
  fi
  
  # Check if Turso CLI is installed
  if command -v turso &> /dev/null; then
    echo -e "${GREEN}Turso CLI detected.${NC}"
    
    # Check Turso auth status
    TURSO_STATUS=$(turso auth status 2>&1)
    if [[ $TURSO_STATUS == *"not logged in"* ]]; then
      echo -e "${YELLOW}Not logged in to Turso. Some features may require authentication.${NC}"
      echo -e "${YELLOW}Run 'turso auth login' to authenticate.${NC}"
    else
      echo -e "${GREEN}Logged in to Turso.${NC}"
    fi
    
    # Set Turso environment variables if not already set
    if [ -z "$TURSO_DATABASE_URL" ]; then
      echo -e "${YELLOW}TURSO_DATABASE_URL not set. Using local development database.${NC}"
      export TURSO_DATABASE_URL="file:tandemx.db"
    fi
  else
    echo -e "${YELLOW}Turso CLI not found. Using local SQLite database.${NC}"
    export TURSO_DATABASE_URL="file:tandemx.db"
  fi
  
  # Load Supabase credentials from .env file if it exists
  if [ -f "../.env" ]; then
    source "../.env"
    echo -e "${GREEN}Loaded Supabase credentials from .env file${NC}"
  fi
  
  # Explicitly unset ElectricSQL variables to prevent conflicts
  unset DATABASE_URL
  unset ELECTRIC_URL
  unset PG_PROXY_PASSWORD
  unset AUTH_MODE
  
  # Ensure database features are enabled
  SKIP_DB=false
elif [ "$SKIP_DB" = true ]; then
  echo -e "${YELLOW}Database sync is disabled. Running in standalone mode.${NC}"
else
  # Automatically switch to Turso since ElectricSQL has issues
  echo -e "${YELLOW}Switching to Turso database by default...${NC}"
  USE_TURSO=true
  
  # Set Turso environment variables
  export TURSO_DATABASE_URL="file:tandemx.db"
  echo -e "${YELLOW}Using local SQLite database.${NC}"
  
  # Explicitly unset ElectricSQL variables
  unset DATABASE_URL
  unset ELECTRIC_URL
  unset PG_PROXY_PASSWORD
  unset AUTH_MODE
  
  # Load .env file if it exists
  if [ -f "../.env" ]; then
    source "../.env"
    echo -e "${GREEN}Loaded environment variables from .env file${NC}"
  fi
  
  # Ensure database features are enabled
  SKIP_DB=false
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

# Create a simple file to disable database features or set Turso mode
if [ "$SKIP_DB" = true ]; then
  echo -e "${YELLOW}Creating file to disable database features...${NC}"
  echo "Database features disabled by run.sh script" > ../.disable_db
  # Remove Turso flag if it exists
  if [ -f "../.use_turso" ]; then
    rm ../.use_turso
  fi
elif [ "$USE_TURSO" = true ]; then
  echo -e "${YELLOW}Creating file to enable Turso database...${NC}"
  echo "Using Turso database by run.sh script" > ../.use_turso
  # Remove disable flag if it exists
  if [ -f "../.disable_db" ]; then
    rm ../.disable_db
  fi
else
  # Remove the flag files if they exist
  if [ -f "../.disable_db" ]; then
    rm ../.disable_db
  fi
  if [ -f "../.use_turso" ]; then
    rm ../.use_turso
  fi
fi

# Check if database initialization is needed
if [ "$SKIP_DB" = false ]; then
  cd ../server
  if [ "$USE_TURSO" = true ]; then
    echo -e "${YELLOW}Initializing Turso database...${NC}"
    cd ../server
    if grep -q "turso_db_setup" src/*.gleam 2>/dev/null; then
      gleam run -m turso_db_setup || echo -e "${YELLOW}Turso database initialization skipped or failed. Continuing...${NC}"
    fi
    cd - > /dev/null
  fi
  cd - > /dev/null
fi

# Start the server with appropriate port and flags
cd ../server
if [ "$USE_TURSO" = true ]; then
  echo -e "${YELLOW}Starting server with Turso on port ${SERVER_PORT}...${NC}"
  gleam run -m dev_server -- --port $SERVER_PORT --use-turso --setup-db &
else
  echo -e "${YELLOW}Starting server on port ${SERVER_PORT}...${NC}"
  gleam run -m dev_server -- --port $SERVER_PORT &
fi

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
elif [ "$USE_TURSO" = true ]; then
  echo -e "${YELLOW}Running with Turso database.${NC}"
  
  # Show database info
  if [[ "$TURSO_DATABASE_URL" == file:* ]]; then
    echo -e "${YELLOW}Using local SQLite database: ${TURSO_DATABASE_URL#file:}${NC}"
  else
    echo -e "${GREEN}Connected to remote Turso database${NC}"
  fi
  
  # Check if Supabase credentials are set
  if [ -n "$SUPABASE_URL" ]; then
    echo -e "${GREEN}Supabase is configured${NC}"
  else
    echo -e "${YELLOW}Supabase credentials not found (optional)${NC}"
  fi
else
  echo -e "${YELLOW}An unexpected error occurred with the database configuration.${NC}"
fi

echo -e "Press Ctrl+C to stop the server"

# Wait for user to press Ctrl+C
wait 