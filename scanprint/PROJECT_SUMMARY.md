# scanprint Project Summary

## Project Overview

scanprint is a PyQt6 desktop application for scanning barcodes, retrieving product data from MarktPOS inventory, and generating printable labels for overstock/liquidation retail inventory. This tool bridges the gap between POS inventory systems and the need for custom price labeling in retail environments.

## Key Components

### Core Data Flow
1. **Input**: Barcode scan or manual entry
2. **Processing**: Lookup in MarktPOS exported inventory CSV
3. **Output**: Formatted label generation and printing/exporting

### Technical Stack
- **Frontend**: PyQt6 for desktop UI
- **Data Handling**: pandas for CSV processing
- **Export Options**: Plain text and PDF (via reportlab)
- **Package Management**: UV for dependency management

## Code Organization

The project follows a modular structure with clear separation of concerns:

### Data Layer
- `inventory.py`: CSV parsing, data searching and filtering
- MarktPOS CSV format support with field mapping

### Business Logic
- `labelgen.py`: Template-based label generation
- Customizable label formats using Python string formatting
- Print history logging

### Presentation Layer
- PyQt6-based UI with responsive design
- Custom widgets for barcode scanning, item display, and label preview
- Template selection and output options

## Setup and Configuration

The project uses modern Python tooling:
- UV for dependency management and virtual environments
- pyproject.toml for project configuration
- Cross-platform setup scripts (setup.sh and setup.bat)

## Development Practices

- Type hints throughout the codebase
- Comprehensive documentation with docstrings
- Modular architecture for easy extension
- Cross-platform compatibility considerations

## Data Structures

### Inventory Item
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

## Future Enhancements

1. **SQLite Integration**: Optional database backend for larger inventories
2. **Template Editor**: Visual editor for creating and modifying label templates
3. **Bulk Operations**: Support for batch processing multiple items
4. **Direct API Integration**: Connect directly to MarktPOS API rather than CSV export
5. **Label Printer Support**: Direct integration with specialized label printers

## Lessons Learned

- Simple data formats (CSV) are sufficient for initial versions
- Template-based approach allows for flexible label designs without code changes
- PyQt6 provides good cross-platform desktop experience
- UV simplifies Python dependency management

## Conclusion

scanprint demonstrates how a focused desktop application can bridge gaps in retail workflows. By connecting inventory data to physical labeling needs, it solves a specific pain point for retail operations dealing with overstock or liquidation inventory.
