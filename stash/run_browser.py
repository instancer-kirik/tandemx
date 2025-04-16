import os
import sys
import subprocess
import time
import webbrowser

def find_available_port(start_port=8000):
    """Find first available port starting from start_port"""
    port = start_port
    while port < start_port + 100:  # Try up to 100 ports
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.bind(('localhost', port))
            sock.close()
            return port
        except OSError:
            port += 1
    raise RuntimeError("Could not find an available port")

def main():
    # Get current directory
    current_dir = os.getcwd()
    client_dir = os.path.join(current_dir, 'client')
    server_dir = os.path.join(current_dir, 'server')

    print("\nWorking directories:")
    print(f"Current dir: {current_dir}")
    print(f"Client dir: {client_dir}")
    print(f"Server dir: {server_dir}")

    # Build client
    print("\nBuilding client (JavaScript)...")
    subprocess.run(['gleam', 'build'], cwd=client_dir, check=True)

    # Build server
    print("\nBuilding server (Erlang)...")
    subprocess.run(['gleam', 'build'], cwd=server_dir, check=True)

    # Find available port
    port = find_available_port()
    print(f"\nUsing port {port}")

    # Start server
    print("\nStarting server...")
    server_proc = subprocess.Popen(
        ['gleam', 'run', '-m', 'dev_server', '--', '--port', str(port)],
        cwd=server_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1  # Line buffered
    )

    # Print server output in real time
    def print_output():
        while True:
            output = server_proc.stdout.readline()
            error = server_proc.stderr.readline()
            if server_proc.poll() is not None and not output and not error:
                break
            if output:
                print(f"Server: {output.strip()}")
            if error:
                print(f"Error: {error.strip()}")

    # Start output printing in a separate thread
    import threading
    output_thread = threading.Thread(target=print_output)
    output_thread.daemon = True
    output_thread.start()

    # Wait for server to start
    time.sleep(2)  # Give server time to start

    if server_proc.poll() is not None:
        print("\nServer failed to start!")
        return 1

    url = f"http://localhost:{port}"
    print(f"\n🚀 Server running at: {url}")
    print("\nPress Ctrl+C to exit...")

    try:
        server_proc.wait()
    except KeyboardInterrupt:
        server_proc.terminate()
        print("\nServer stopped")

if __name__ == '__main__':
    sys.exit(main()) 