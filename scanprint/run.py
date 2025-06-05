#!/usr/bin/env python3
"""
ScanPrint - Overstock Inventory Labeling System
Simple runner script for easy execution with UV or regular Python
"""

import sys
import os
from pathlib import Path

# Add the current directory to the path so imports work correctly
current_dir = Path(__file__).parent.absolute()
sys.path.insert(0, str(current_dir))

# Ensure default demo values are set (but turned off for normal mode)
os.environ.setdefault("SCANPRINT_DEMO_MODE", "0")
os.environ.setdefault("SCANPRINT_DEMO_BARCODES", "123456789012,723456789013,823456789014,923456789015")

# Import the main function from the scanprint package
try:
    from scanprint.main import main
except ImportError as e:
    print(f"Error importing scanprint module: {e}")
    print("\nThis could be due to missing dependencies. Try running:")
    print("  cd tandemx/scanprint")
    print("  uv pip install -e .")
    sys.exit(1)

if __name__ == "__main__":
    # Print welcome message
    print("=== ScanPrint Inventory Labeling System ===")
    print("Starting application...")
    
    # Run the main function
    try:
        main()
    except KeyboardInterrupt:
        print("\nApplication terminated by user.")
    except Exception as e:
        print(f"\nError running application: {e}")
        sys.exit(1)