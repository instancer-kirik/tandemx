#!/bin/bash

# Script to run the development server with SendGrid email functionality
# Usage: ./run_with_email.sh [port]

# Set default port
PORT=${1:-8000}

# Check if SENDGRID_API_KEY is set in the environment
if [ -z "$SENDGRID_API_KEY" ]; then
  echo "WARNING: SENDGRID_API_KEY is not set in the environment."
  echo "Email functionality will be limited."
fi

echo "===================================================================="
echo "IMPORTANT: This script currently runs with the Erlang mock email service."
echo "To use the actual SendGrid service, you would need to:"
echo "1. Change the target in gleam.toml to 'javascript'"
echo "2. Rename email_service_js.gleam to replace email_service.gleam"
echo "3. Run this script"
echo "===================================================================="

# Get the script's directory
SCRIPT_DIR=$(dirname "$0")

# Change to the server directory
cd "$SCRIPT_DIR"

# Build the server
echo "Building server..."
gleam build

# Run the server
echo "Starting server on port $PORT with email functionality..."
gleam run -m dev_server -- --port $PORT 