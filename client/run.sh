#!/bin/bash

# Build the application
echo "Building TandemX application..."
gleam build

# Change to the server directory and build the server
echo "Building and starting the dev server..."
cd ../server
gleam build
gleam run -m dev_server -- --port 8000

# Note: The server will run on port 8000 by default
echo "Open your browser at http://localhost:8000/" 