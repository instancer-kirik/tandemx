# scanprint: Overstock Inventory Labeling System

A PyQt6 desktop application for scanning barcodes, retrieving product data from MarktPOS inventory, and generating printable labels for overstock/liquidation retail inventory.

## 📁 Core File Structure

```
scanprint/
├── main.py                   # Application entry point
├── inventory/                # Inventory data storage
│   ├── marktpos_export.csv   # Primary data store from MarktPOS
│   └── archive/              # Backup storage
├── labels/                   # Label management
│   ├── templates/            # Label format templates
│   └── history.csv           # Print history log
├── ui/                       # UI components
│   ├── widgets.py            # Custom PyQt6 widgets
│   └── styles.qss            # UI styling
└── utils/                    # Core utility modules
    ├── inventory.py          # Inventory management
    ├── labelgen.py           # Label generation
    └── printer.py            # Printer integration
```

## 🧩 Module Functions

### `main.py`
- `main()` → Initialize and run application
- `create_app()` → PyQt6 QApplication setup
- `setup_window(app)` → Configure main window
- `connect_signals()` → Wire up UI event handlers

### `utils/inventory.py`
- `load_inventory(filepath)` → DataFrame: Load CSV inventory data
- `search_by_barcode(inventory_df, barcode)` → Dict: Find item by barcode
- `search_by_sku(inventory_df, sku)` → Dict: Find item by SKU
- `search_by_name(inventory_df, name)` → DataFrame: Find items by name
- `get_departments(inventory_df)` → List[str]: Get unique departments
- `filter_by_department(inventory_df, department)` → DataFrame: Filter items
- `get_suppliers(inventory_df)` → List[str]: Get unique suppliers
- `filter_by_supplier(inventory_df, supplier)` → DataFrame: Filter by supplier

### `utils/labelgen.py`
- `generate_label(item_data, template_name)` → str: Create formatted label text
- `get_available_templates()` → List[str]: List template options
- `load_template(template_name)` → str: Load template format
- `save_to_pdf(label_text, output_path)` → bool: Export as PDF
- `save_to_file(label_text, output_path)` → bool: Export as text file
- `log_print_history(item_data, template_used)` → None: Record in history.csv

### `utils/printer.py`
- `get_available_printers()` → List[str]: List system printers
- `print_label(label_text, printer_name=None)` → bool: Send to printer
- `print_preview(label_text)` → None: Show print preview dialog
- `configure_printer(printer_name)` → Dict: Set printer options

### `ui/widgets.py`
- `BarcodeScanWidget(QWidget)`: Barcode input with scan detection
  - `set_focus()` → None: Focus input field
  - `clear_input()` → None: Reset field
  - `get_barcode()` → str: Get current barcode
  - `scan_detected` → Signal: Emitted on scan

- `LabelPreviewWidget(QWidget)`: Display label preview
  - `set_content(label_text)` → None: Update preview
  - `clear()` → None: Clear preview
  - `print_requested` → Signal: Print button clicked

- `InventoryResultWidget(QWidget)`: Display found item details
  - `set_item(item_data)` → None: Update displayed item
  - `clear()` → None: Clear displayed item
  - `generate_label_requested` → Signal: Generate button clicked

## 📊 Data Structures

### Inventory Item (Dict)
```python
{
    'product_name': str,    # Product name
    'sku': str,             # Internal SKU
    'barcode': str,         # UPC/Barcode
    'department': str,      # Product department/category
    'price': float,         # Retail price
    'cost': float,          # Cost basis
    'quantity': int,        # Current stock quantity
    'description': str,     # Extended description
    'supplier': str,        # Supplier/vendor name
}
```

### Label Template (String Format)
```
{product_name}
Price: ${price}
SKU: {sku}
Barcode: {barcode}
Dept: {department}
```

### Print History Record (CSV Row)
```
timestamp,barcode,sku,product_name,price,department,template
```

## 🚀 Development Roadmap

| Feature | Status | Priority |
|---------|--------|----------|
| Barcode search & label preview | ✅ Complete | High |
| Print to file | ✅ Complete | High |
| OS-level print integration | 🔄 In Progress | Medium |
| Auto-detect barcode scanner input | 🔄 In Progress | Medium |
| Editable label templates | 📋 Planned | Medium |
| Template preview in GUI | 📋 Planned | Low |
| SQLite backend upgrade | 📋 Optional | Low |
| Bulk label mode | 📋 Optional | Low |

## 🧪 Testing Strategy

- Unit tests for core functions in `utils/` modules
- Integration tests for UI workflows
- Manual testing with real barcode scanners
- Sample inventory data for testing

## 📦 Dependencies

- PyQt6: UI framework
- pandas: Data handling
- reportlab: PDF generation (optional)
- pytest: Testing framework
