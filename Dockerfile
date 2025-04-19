# Use official Gleam image
FROM ghcr.io/gleam-lang/gleam:v1.9.1-erlang

# Set working directory
WORKDIR /app

# Install Node.js and npm
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . .

# Clean any existing build artifacts
RUN rm -rf client/build/ server/build/ \
    client/_build/ server/_build/

# Build client
WORKDIR /app/client
RUN gleam clean && \
    gleam update && \
    gleam build && \
    npm install

# Build server
WORKDIR /app/server
RUN gleam clean && \
    gleam update && \
    gleam build

# Set working directory to server for running
WORKDIR /app/server

# Expose ports
EXPOSE 8000

# Start the server
CMD ["gleam", "run", "-m", "dev_server"]