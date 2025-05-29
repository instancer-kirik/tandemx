#!/bin/bash

# Color for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting TandemX platform setup...${NC}"

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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker and try again.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose and try again.${NC}"
    exit 1
fi

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
if ! kill -0 $SERVER_PID 2>/dev/null; then
  echo -e "${RED}Server failed to start. Check for errors above.${NC}"
  exit 1
fi

echo -e "${GREEN}Server started successfully on port ${SERVER_PORT}${NC}"

# Keep the script running until the server is stopped
wait $SERVER_PID 