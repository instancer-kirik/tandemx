#!/bin/bash

# Color for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting TandemX platform setup...${NC}"

# Default settings
SKIP_DB=false
USE_TURSO=false

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
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
done

# Check for shell type
if [ -n "$FISH_VERSION" ]; then
  echo -e "${YELLOW}Running in fish shell environment${NC}"
  SET_VAR="set -g"
  IS_FISH=true
else
  echo -e "${YELLOW}Running in bash/standard shell environment${NC}"
  SET_VAR="export"
  IS_FISH=false
fi

# Check requirements based on database mode
if [ "$SKIP_DB" = true ]; then
    echo -e "${YELLOW}Running in standalone mode without database.${NC}"
elif [ "$USE_TURSO" = true ]; then
    echo -e "${GREEN}Using Turso database...${NC}"
    
    # Check if Turso CLI is installed (optional)
    if command -v turso &> /dev/null; then
        echo -e "${GREEN}Turso CLI detected.${NC}"
    else
        echo -e "${YELLOW}Turso CLI not found. Using local SQLite database.${NC}"
    fi
else
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed. Please install Docker or use --use-turso or --skip-db flags.${NC}"
        exit 1
    fi

    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Docker Compose is not installed. Please install Docker Compose or use --use-turso or --skip-db flags.${NC}"
        exit 1
    fi
fi

# Setup database services based on mode
if [ "$SKIP_DB" = true ]; then
    echo -e "${YELLOW}Skipping database setup as requested.${NC}"
elif [ "$USE_TURSO" = true ]; then
    # Load Turso credentials from .env file if it exists
    if [ -f ".env" ]; then
        if [ "$IS_FISH" = true ]; then
            source .env | while read -l line; eval $SET_VAR $line; end
        else
            source .env
        fi
        echo -e "${GREEN}Loaded environment variables from .env file${NC}"
    fi
    
    # Set Turso environment variables if not already set
    if [ -z "$TURSO_DATABASE_URL" ]; then
        echo -e "${YELLOW}TURSO_DATABASE_URL not set. Using local development database.${NC}"
        $SET_VAR TURSO_DATABASE_URL="file:tandemx.db"
    fi
    
    # Explicitly unset ElectricSQL variables to prevent conflicts
    unset DATABASE_URL
    unset ELECTRIC_URL
    unset PG_PROXY_PASSWORD
    unset AUTH_MODE
    
    echo -e "${GREEN}Turso database configuration ready.${NC}"
else
    # Create a docker-compose.yml file for ElectricSQL if it doesn't exist
    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${YELLOW}Creating docker-compose.yml for ElectricSQL...${NC}"
        cat > docker-compose.yml << 'EOL'
version: '3.8'
services:
  postgres:
    image: postgres:14
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: electric
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  electric:
    image: electricsql/electric:latest
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/electric
      PG_PROXY_PASSWORD: proxy_password
      AUTH_MODE: insecure
    ports:
      - "5133:5133"
      - "5433:5433"
    depends_on:
      - postgres

volumes:
  postgres_data:
EOL
        echo -e "${GREEN}docker-compose.yml created.${NC}"
    fi

    # Start the ElectricSQL stack in the background
    echo -e "${YELLOW}Starting ElectricSQL services with Docker Compose...${NC}"
    docker-compose up -d

    # Wait for ElectricSQL to start
    echo -e "${YELLOW}Waiting for ElectricSQL to start...${NC}"
    sleep 5
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
  echo "Database features disabled by run.sh script" > .disable_db
  # Remove Turso flag if it exists
  if [ -f ".use_turso" ]; then
    rm .use_turso
  fi
  if [ -f ".disable_electric" ]; then
    rm .disable_electric
  fi
elif [ "$USE_TURSO" = true ]; then
  echo -e "${YELLOW}Creating file to enable Turso database...${NC}"
  echo "Using Turso database by run.sh script" > .use_turso
  # Remove disable flag if it exists
  if [ -f ".disable_db" ]; then
    rm .disable_db
  fi
  # Also create an electric disable flag to completely bypass ElectricSQL
  echo "ElectricSQL disabled when using Turso" > .disable_electric
else
  # Remove the flag files if they exist
  if [ -f ".disable_db" ]; then
    rm .disable_db
  fi
  if [ -f ".use_turso" ]; then
    rm .use_turso
  fi
fi

# Check if database initialization modules exist, and run the appropriate one
if [ "$SKIP_DB" = false ]; then
  if [ "$USE_TURSO" = true ] && grep -q "turso_db_setup" src/*.gleam 2>/dev/null; then
    echo -e "${YELLOW}Initializing Turso database...${NC}"
    gleam run -m turso_db_setup || echo -e "${YELLOW}Turso database initialization skipped or failed. Continuing...${NC}"
  elif grep -q "db_init" src/*.gleam 2>/dev/null; then
    echo -e "${YELLOW}Initializing database...${NC}"
    gleam run -m db_init || echo -e "${YELLOW}Database initialization skipped or failed. Continuing...${NC}"
  fi
fi

# Load Supabase credentials from .env file if it exists
if [ -f ".env" ]; then
  if [ "$IS_FISH" = true ]; then
    source .env | while read -l line; eval $SET_VAR $line; end
  else
    source .env
  fi
  echo -e "${GREEN}Loaded Supabase credentials from .env file${NC}"
else
  echo -e "${YELLOW}No .env file found. Supabase credentials will not be available.${NC}"
fi

# Start the server with appropriate port and flags
if [ "$USE_TURSO" = true ]; then
  echo -e "${YELLOW}Starting server with Turso on port ${SERVER_PORT}...${NC}"
  gleam run -m dev_server -- --port $SERVER_PORT --use-turso --skip-electric &
else
  echo -e "${YELLOW}Starting server on port ${SERVER_PORT}...${NC}"
  gleam run -m dev_server -- --port $SERVER_PORT &
fi

# Store the PID of the server process
SERVER_PID=$!

# Wait a moment to check if the server started successfully
sleep 2
if ! kill -0 $SERVER_PID 2>/dev/null; then
  echo -e "${RED}Server failed to start. Check for errors above.${NC}"
  exit 1
fi

echo -e "${GREEN}Server started successfully on port ${SERVER_PORT}${NC}"

# Keep the script running until the server is stopped
wait $SERVER_PID 