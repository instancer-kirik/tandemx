# scanprint: Overstock Inventory Labeling System

A PyQt6 desktop application for scanning barcodes, retrieving product data from MarktPOS inventory, and generating printable labels for overstock/liquidation retail inventory.

## 📁 Project Structure

```
scanprint/
├── run.py                    # Standard application runner
├── run_demo.py               # Demo mode with sample data
├── NO install.sh, install.bat, install_and_run, setup, setup_and_run, setup_and_run_demo, setup_and_run_demo_and_run, or install_uv
├── pyproject.toml            # Project configuration
├── requirements.txt          # Dependencies list
├── .gitignore                # Git ignore rules
├── scanprint/                # Main application package
│   ├── __init__.py           # Package initialization
│   └── main.py               # Application entry point
├── inventory/                # Inventory data storage
│   ├── marktpos_export.csv   # Primary data store from MarktPOS
│   └── archive/              # Backup storage
├── labels/                   # Label management
│   ├── templates/            # Label format templates
│   │   ├── default.txt       # Default label template
│   │   └── price_tag.txt     # Price tag template
│   └── history.csv           # Print history log
└── utils/                    # Core utility modules
    ├── inventory.py          # Inventory management
    ├── labelgen.py           # Label generation
    └── printer.py            # Printer integration
```

## 📦 Features

- **Fast Barcode Scanning**: Directly scan product barcodes or enter them manually
- **Inventory Lookup**: Instantly retrieve product details from your MarktPOS export
- **Label Templates**: Multiple customizable label formats
- **Export Options**: Save as text or PDF files
- **Print History**: Keep logs of all printed labels

## 🚀 Getting Started

### Prerequisites

- Python 3.8+
- UV package manager (automatically installed by the install script)

### Installation

will distribute as exe and AppImage, on release
install uv
https://docs.astral.sh/uv/getting-started/installation/#__tabbed_1_2


3. Place your MarktPOS inventory export in the `inventory` folder as `marktpos_export.csv`
4. Run the application:

```bash
# Or with UV:
uv run run.py
```

### Running in Demo Mode

If you want to try the application without setting up your own inventory data:

```bash

# Or with UV:
uv run run_demo.py


```

Demo mode will:
- Create sample inventory data if it doesn't exist
- Set up example label templates
- Simulate printing operations
- Provide sample barcodes for testing
- Allow you to explore all features without real hardware

### Expected CSV Format

scanprint expects your MarktPOS export to have the following column headers:

```
Product Name,SKU,Barcode,Department,Price,Cost,Quantity,Description,Supplier
```

## 📋 Usage

1. **Scan a Barcode**: Enter a barcode in the input field or scan with a connected barcode scanner
   - In demo mode, try barcode `712345678901` through `712345678910`
   - You can also use the test buttons to quickly scan demo barcodes
2. **View Product Details**: Product information will display in the left panel
3. **Generate Label**: Click "Generate Label" to create a label preview
4. **Select Template**: Choose from available templates in the dropdown
5. **Print or Export**: Save as text/PDF or send directly to printer
   - In demo mode, printing is simulated

## 🏷️ Custom Label Templates

Create your own label templates in the `labels/templates` folder. Templates use Python's string formatting syntax:

```
{product_name}
Price: ${price:.2f}
SKU: {sku}
Barcode: {barcode}
Dept: {department}
```

Available fields:
- `product_name`
- `sku`
- `barcode`
- `department`
- `price`
- `cost`
- `quantity`
- `description`
- `supplier`

## 📊 Data Management

- Inventory data is read-only within the application
- Update your inventory by replacing the CSV file with a fresh export from MarktPOS
- Print history is recorded in `labels/history.csv`

## 🔧 Development

See the `PROJECT_HEADERS_REFINED.md` file for a detailed overview of the project structure and available functions.



## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
