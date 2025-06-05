#!/usr/bin/env python3
"""
ScanPrint - Overstock Inventory Labeling System
Demo mode script for running with sample data and simulated printing
"""

import sys
import os
from pathlib import Path
import tempfile
import csv
import random
import json

# Add the current directory to the path so imports work correctly
current_dir = Path(__file__).parent.absolute()
sys.path.insert(0, str(current_dir))

# Create demo inventory file if it doesn't exist
def create_demo_inventory():
    """Create a sample inventory file for demo purposes"""
    inventory_dir = current_dir / "inventory"
    inventory_dir.mkdir(exist_ok=True)

    inventory_file = inventory_dir / "marktpos_export.csv"

    # Only create if it doesn't exist
    if inventory_file.exists():
        print(f"Using existing inventory file: {inventory_file}")
        return

    print(f"Creating demo inventory file: {inventory_file}")

    # Sample product data
    products = [
        {"Product Name": "Premium Wireless Headphones", "SKU": "AUDIO001", "Barcode": "712345678901", "Department": "Electronics", "Price": "149.99", "Cost": "89.99", "Quantity": "25", "Description": "Noise-cancelling wireless headphones", "Supplier": "AudioTech"},
        {"Product Name": "Organic Cotton T-Shirt", "SKU": "APRL100", "Barcode": "712345678902", "Department": "Apparel", "Price": "24.99", "Cost": "8.50", "Quantity": "100", "Description": "100% organic cotton t-shirt", "Supplier": "EcoClothing"},
        {"Product Name": "Stainless Steel Water Bottle", "SKU": "HOME210", "Barcode": "712345678903", "Department": "Home Goods", "Price": "19.99", "Cost": "7.25", "Quantity": "50", "Description": "24oz insulated water bottle", "Supplier": "EcoWare"},
        {"Product Name": "Bluetooth Smart Speaker", "SKU": "AUDIO025", "Barcode": "712345678904", "Department": "Electronics", "Price": "79.99", "Cost": "42.00", "Quantity": "30", "Description": "Portable smart speaker with voice assistant", "Supplier": "AudioTech"},
        {"Product Name": "Yoga Mat", "SKU": "FITNESS110", "Barcode": "712345678905", "Department": "Fitness", "Price": "34.99", "Cost": "15.75", "Quantity": "40", "Description": "Non-slip exercise yoga mat", "Supplier": "ActiveLife"},
        {"Product Name": "LED Desk Lamp", "SKU": "HOME185", "Barcode": "712345678906", "Department": "Home Goods", "Price": "45.99", "Cost": "22.50", "Quantity": "35", "Description": "Adjustable LED desk lamp with USB port", "Supplier": "BrightHome"},
        {"Product Name": "Wireless Charging Pad", "SKU": "TECH056", "Barcode": "712345678907", "Department": "Electronics", "Price": "29.99", "Cost": "14.25", "Quantity": "60", "Description": "Fast wireless charging pad for smartphones", "Supplier": "TechGear"},
        {"Product Name": "Ceramic Coffee Mug Set", "SKU": "HOME098", "Barcode": "712345678908", "Department": "Home Goods", "Price": "24.99", "Cost": "10.00", "Quantity": "45", "Description": "Set of 4 ceramic coffee mugs", "Supplier": "HomeStyle"},
        {"Product Name": "Bluetooth Fitness Tracker", "SKU": "FITNESS220", "Barcode": "712345678909", "Department": "Fitness", "Price": "59.99", "Cost": "28.50", "Quantity": "40", "Description": "Waterproof fitness tracker with heart rate monitor", "Supplier": "ActiveLife"},
        {"Product Name": "Portable Power Bank", "SKU": "TECH075", "Barcode": "712345678910", "Department": "Electronics", "Price": "39.99", "Cost": "18.75", "Quantity": "55", "Description": "10000mAh fast-charging power bank", "Supplier": "TechGear"}
    ]

    # Write the CSV file
    with open(inventory_file, 'w', newline='') as csvfile:
        fieldnames = ["Product Name", "SKU", "Barcode", "Department", "Price", "Cost", "Quantity", "Description", "Supplier"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(products)

# Create demo template directories and files
def create_demo_templates():
    """Create sample label templates for demo purposes"""
    templates_dir = current_dir / "labels" / "templates"
    templates_dir.mkdir(exist_ok=True, parents=True)

    # Create default template if it doesn't exist
    default_template = templates_dir / "default.txt"
    if not default_template.exists():
        with open(default_template, 'w') as f:
            f.write("""OVERSTOCK ITEM
{product_name}
Price: ${price:.2f}
SKU: {sku}
Barcode: {barcode}
Department: {department}""")

    # Create price tag template if it doesn't exist
    price_template = templates_dir / "price_tag.txt"
    if not price_template.exists():
        with open(price_template, 'w') as f:
            f.write("""SPECIAL PRICE
{product_name}
${price:.2f}
SKU: {sku}
{barcode}""")

# Set up environment for demo mode
def setup_demo_mode():
    """Set up the demo environment"""
    create_demo_inventory()
    create_demo_templates()

    # Set environment variables for demo mode
    os.environ["SCANPRINT_DEMO_MODE"] = "1"

    # Define demo barcodes from our sample inventory
    os.environ["SCANPRINT_DEMO_BARCODES"] = "712345678901,712345678902,712345678903,712345678904,712345678905"

    print("===== ScanPrint Demo Mode =====")
    print("Running with sample data and simulated printing")
    print("- Sample inventory created")
    print("- Label templates created")
    print("- Printing will be simulated")
    print("- Demo barcodes configured")
    print("================================")

if __name__ == "__main__":
    # Set up demo environment
    setup_demo_mode()

    # Import the main function after setting up demo mode
    try:
        from scanprint.main import main
    except ImportError as e:
        print(f"Error importing scanprint module: {e}")
        print("\nThis could be due to missing dependencies. Try running:")
        print("  cd tandemx/scanprint")
        print("  uv pip install -e .")
        sys.exit(1)

    # Run the main function
    try:
        main()
    except KeyboardInterrupt:
        print("\nDemo application terminated by user.")
    except Exception as e:
        print(f"\nError running demo application: {e}")
        sys.exit(1)
