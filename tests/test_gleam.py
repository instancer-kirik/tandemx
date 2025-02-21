import pytest
import os
import http.client
from tandemx.run_browser import main

def test_gleam_server():
    # Start the server
    main_process = Process(target=main)
    main_process.start()
    
    try:
        # Give it a moment to start
        time.sleep(2)
        
        # Test server connection
        conn = http.client.HTTPConnection("localhost:8000")
        conn.request("GET", "/")
        response = conn.getresponse()
        
        # Check response
        assert response.status == 200
        html = response.read().decode()
        assert 'import { main } from \'/priv/static/todomvc.mjs\'' in html
        
        # Test JS file exists
        conn.request("GET", "/priv/static/todomvc.mjs")
        response = conn.getresponse()
        assert response.status == 200
        
    finally:
        main_process.terminate()
        main_process.join()

def test_file_setup():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    build_dir = os.path.join(current_dir, "build/dev/javascript")
    static_dir = os.path.join(build_dir, "priv/static")
    
    # Test build
    assert os.path.exists(build_dir), "Build directory not created"
    assert os.path.exists(static_dir), "Static directory not created"
    assert os.path.exists(os.path.join(build_dir, "index.html")), "index.html not copied"
    assert os.path.exists(os.path.join(static_dir, "todomvc.mjs")), "todomvc.mjs not copied" 