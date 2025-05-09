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

# Initialize the database
echo -e "${GREEN}Initializing database...${NC}"
cd server && gleam build && gleam run -m db_init
cd ..

# Build the client application
echo -e "${GREEN}Building client application...${NC}"
cd client && gleam build

# Bundle the client JavaScript using esbuild
echo -e "${GREEN}Bundling client JavaScript with esbuild...${NC}"
# Adjust entry point and outfile as necessary.
# Entry point is relative to the 'client' directory after 'gleam build'.
# Output file is also relative to the 'client' directory.

# Ensure output directory exists
mkdir -p ./dist/js

echo -e "${YELLOW}Current directory before esbuild: $(pwd)${NC}"

# Use bunx to execute esbuild
bunx esbuild ./build/dev/javascript/tandemx_client/app.mjs --bundle --outfile=./dist/js/bundle.js --format=esm --platform=browser
ESBUILD_EXIT_CODE=$?

# Check if esbuild command was successful
if [ $ESBUILD_EXIT_CODE -ne 0 ]; then
  echo -e "${RED}esbuild failed with exit code $ESBUILD_EXIT_CODE. Aborting.${NC}"
  exit $ESBUILD_EXIT_CODE
fi

echo -e "${YELLOW}Checking if bundle exists...${NC}"
ls -l ./dist/js/bundle.js
if [ $? -ne 0 ]; then
  echo -e "${RED}Bundle file ./dist/js/bundle.js NOT found after esbuild step!${NC}"
  # Optionally list the contents of dist/js to see what *is* there
  ls -l ./dist/js
  exit 1
else
   echo -e "${GREEN}Bundle file found.${NC}"
fi

# Build the server application
echo -e "${GREEN}Building server application...${NC}"
cd ../server && gleam build

# Start the server
echo -e "${GREEN}Starting the server...${NC}"
cd server && gleam run &
SERVER_PID=$!

# Function to handle script termination
function cleanup {
  echo -e "${YELLOW}Shutting down services...${NC}"
  kill $SERVER_PID
  docker-compose down
  echo -e "${GREEN}All services stopped.${NC}"
}

# Register the cleanup function for script termination
trap cleanup EXIT

# Keep the script running and display information
echo -e "${GREEN}TandemX is running!${NC}"
echo -e "Server: http://localhost:8000"
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"

# Wait for user to press Ctrl+C
wait 