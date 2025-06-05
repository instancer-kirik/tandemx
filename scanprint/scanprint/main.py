import sys
import os
import random
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                            QHBoxLayout, QLabel, QLineEdit, QPushButton,
                            QComboBox, QGridLayout, QGroupBox, QStatusBar,
                            QMessageBox, QFileDialog, QCheckBox)
from PyQt6.QtCore import Qt, pyqtSignal, QTimer
import pandas as pd

# Import with absolute imports
from utils.inventory import (load_inventory, search_by_barcode)
from utils.labelgen import (generate_label, get_available_templates,
                          save_to_file, save_to_pdf, log_print_history)
from utils.printer import (print_text, print_label, get_system_printers, 
                         get_default_printer, print_pdf)

class BarcodeScanWidget(QWidget):
    scan_detected = pyqtSignal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Timer to detect barcode scanner input (typically fast input)
        self.input_timer = QTimer()
        self.input_timer.setSingleShot(True)
        self.input_timer.timeout.connect(self.process_input)
        self.input_buffer = ""
        
        # Demo data - sample barcodes for testing
        demo_env = os.environ.get("SCANPRINT_DEMO_BARCODES", "123456789012,723456789013,823456789014,923456789015")
        self.demo_barcodes = demo_env.split(",")
        
        # Initialize UI after setting up demo_barcodes
        self.init_ui()

    def init_ui(self):
        main_layout = QVBoxLayout()
        
        # Top row with scan input
        scan_layout = QHBoxLayout()
        self.scan_label = QLabel("Scan or Enter Barcode:")
        self.scan_input = QLineEdit()
        self.scan_input.setPlaceholderText("Scan barcode or enter manually...")
        self.scan_input.returnPressed.connect(self.on_return_pressed)
        self.scan_input.textChanged.connect(self.on_text_changed)

        self.search_btn = QPushButton("Search")
        self.search_btn.clicked.connect(self.on_return_pressed)

        scan_layout.addWidget(self.scan_label)
        scan_layout.addWidget(self.scan_input, 1)  # 1 = stretch factor
        scan_layout.addWidget(self.search_btn)
        
        # Demo row with sample barcodes
        demo_layout = QHBoxLayout()
        demo_label = QLabel("Demo:")
        demo_layout.addWidget(demo_label)
        
        # Add demo barcode buttons
        for barcode in self.demo_barcodes:
            demo_btn = QPushButton(f"Test {barcode[-4:]}")
            demo_btn.clicked.connect(lambda _, code=barcode: self.demo_scan(code))
            demo_btn.setToolTip(f"Simulate scanning barcode: {barcode}")
            demo_layout.addWidget(demo_btn)
        
        # Random barcode button
        random_btn = QPushButton("Random")
        random_btn.clicked.connect(self.demo_random_scan)
        random_btn.setToolTip("Generate and scan a random barcode")
        demo_layout.addWidget(random_btn)
        
        main_layout.addLayout(scan_layout)
        main_layout.addLayout(demo_layout)
        
        self.setLayout(main_layout)

    def set_focus(self):
        self.scan_input.setFocus()

    def clear_input(self):
        self.scan_input.clear()
        self.input_buffer = ""

    def get_barcode(self):
        return self.scan_input.text().strip()

    def on_text_changed(self, text):
        # Barcode scanners typically input characters rapidly
        # Restart timer each time a character is entered
        self.input_timer.start(50)  # 50ms delay
        self.input_buffer = text

    def process_input(self):
        # If timer expires, it might be a barcode scan
        if len(self.input_buffer) >= 8:  # Most barcodes are at least 8 chars
            self.scan_detected.emit(self.input_buffer)

    def on_return_pressed(self):
        barcode = self.get_barcode()
        if barcode:
            self.scan_detected.emit(barcode)
            
    def demo_scan(self, barcode):
        """Simulate scanning a specific barcode"""
        self.scan_input.setText(barcode)
        self.scan_detected.emit(barcode)
        
    def demo_random_scan(self):
        """Simulate scanning a random barcode"""
        # Generate a random 12-digit barcode
        random_barcode = ''.join(random.choices('0123456789', k=12))
        self.scan_input.setText(random_barcode)
        self.scan_detected.emit(random_barcode)


class InventoryResultWidget(QWidget):
    generate_label_requested = pyqtSignal(dict)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.item_data = None
        self.init_ui()

    def init_ui(self):
        layout = QGridLayout()

        # Item details grid
        self.info_group = QGroupBox("Item Details")
        info_layout = QGridLayout()

        self.product_name_label = QLabel("Product:")
        self.product_name_value = QLabel("")
        self.product_name_value.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)

        self.sku_label = QLabel("SKU:")
        self.sku_value = QLabel("")
        self.sku_value.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)

        self.barcode_label = QLabel("Barcode:")
        self.barcode_value = QLabel("")
        self.barcode_value.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)

        self.department_label = QLabel("Department:")
        self.department_value = QLabel("")

        self.price_label = QLabel("Price:")
        self.price_value = QLabel("")

        self.cost_label = QLabel("Cost:")
        self.cost_value = QLabel("")

        self.quantity_label = QLabel("Quantity:")
        self.quantity_value = QLabel("")

        self.supplier_label = QLabel("Supplier:")
        self.supplier_value = QLabel("")

        # Add widgets to layout
        info_layout.addWidget(self.product_name_label, 0, 0)
        info_layout.addWidget(self.product_name_value, 0, 1)

        info_layout.addWidget(self.sku_label, 1, 0)
        info_layout.addWidget(self.sku_value, 1, 1)

        info_layout.addWidget(self.barcode_label, 2, 0)
        info_layout.addWidget(self.barcode_value, 2, 1)

        info_layout.addWidget(self.department_label, 3, 0)
        info_layout.addWidget(self.department_value, 3, 1)

        info_layout.addWidget(self.price_label, 4, 0)
        info_layout.addWidget(self.price_value, 4, 1)

        info_layout.addWidget(self.cost_label, 5, 0)
        info_layout.addWidget(self.cost_value, 5, 1)

        info_layout.addWidget(self.quantity_label, 6, 0)
        info_layout.addWidget(self.quantity_value, 6, 1)

        info_layout.addWidget(self.supplier_label, 7, 0)
        info_layout.addWidget(self.supplier_value, 7, 1)

        self.info_group.setLayout(info_layout)

        # Action buttons
        self.generate_btn = QPushButton("Generate Label")
        self.generate_btn.clicked.connect(self.on_generate_clicked)
        self.generate_btn.setEnabled(False)

        # Add to main layout
        layout.addWidget(self.info_group, 0, 0, 1, 2)
        layout.addWidget(self.generate_btn, 1, 0, 1, 2)

        self.setLayout(layout)

    def set_item(self, item_data):
        self.item_data = item_data

        if item_data:
            self.product_name_value.setText(str(item_data.get('product_name', '')))
            self.sku_value.setText(str(item_data.get('sku', '')))
            self.barcode_value.setText(str(item_data.get('barcode', '')))
            self.department_value.setText(str(item_data.get('department', '')))

            # Format price and cost with 2 decimal places
            price = item_data.get('price', 0)
            cost = item_data.get('cost', 0)
            self.price_value.setText(f"${price:.2f}")
            self.cost_value.setText(f"${cost:.2f}")

            self.quantity_value.setText(str(item_data.get('quantity', 0)))
            self.supplier_value.setText(str(item_data.get('supplier', '')))

            self.generate_btn.setEnabled(True)
        else:
            self.clear()

    def clear(self):
        self.item_data = None
        self.product_name_value.setText("")
        self.sku_value.setText("")
        self.barcode_value.setText("")
        self.department_value.setText("")
        self.price_value.setText("")
        self.cost_value.setText("")
        self.quantity_value.setText("")
        self.supplier_value.setText("")
        self.generate_btn.setEnabled(False)

    def on_generate_clicked(self):
        if self.item_data:
            self.generate_label_requested.emit(self.item_data)


class LabelPreviewWidget(QWidget):
    print_requested = pyqtSignal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.label_text = ""
        # Set demo mode based on environment variable or default to True
        self.demo_mode = os.environ.get("SCANPRINT_DEMO_MODE", "1") == "1"
        self.printer_name = None
        self.status_bar = None
        self.init_ui()

    def init_ui(self):
        print("DEBUG: Initializing LabelPreviewWidget UI")
        layout = QVBoxLayout()

        # Template selection
        template_layout = QHBoxLayout()
        self.template_label = QLabel("Template:")
        self.template_selector = QComboBox()

        # Printer selection
        printer_layout = QHBoxLayout()
        self.printer_label = QLabel("Printer:")
        self.printer_selector = QComboBox()
        self.refresh_printers_btn = QPushButton("Refresh")
        self.refresh_printers_btn.clicked.connect(self.refresh_printers)
        printer_layout.addWidget(self.printer_label)
        printer_layout.addWidget(self.printer_selector, 1)
        printer_layout.addWidget(self.refresh_printers_btn)

        # Load available templates and printers
        self.refresh_templates()
        self.refresh_printers()

        template_layout.addWidget(self.template_label)
        template_layout.addWidget(self.template_selector, 1)
        
        # Demo mode checkbox
        self.demo_checkbox = QCheckBox("Demo Mode (simulate printing)")
        self.demo_checkbox.setChecked(self.demo_mode)
        self.demo_checkbox.toggled.connect(self.toggle_demo_mode)
        
        # If demo mode is enforced by environment, disable checkbox
        if os.environ.get("SCANPRINT_DEMO_MODE") == "1":
            self.demo_checkbox.setEnabled(False)

        # Preview area
        self.preview_group = QGroupBox("Label Preview")
        preview_layout = QVBoxLayout()

        self.preview_text = QLabel("")
        self.preview_text.setAlignment(Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignLeft)
        self.preview_text.setStyleSheet("""
            background-color: white;
            border: 1px solid #ccc;
            padding: 10px;
            font-family: monospace;
            white-space: pre-wrap;
            margin: 5px;
        """)
        self.preview_text.setMinimumHeight(200)
        self.preview_text.setTextFormat(Qt.TextFormat.PlainText)
        self.preview_text.setWordWrap(True)

        preview_layout.addWidget(self.preview_text)
        self.preview_group.setLayout(preview_layout)

        # Action buttons
        action_layout = QHBoxLayout()

        self.save_text_btn = QPushButton("Save as Text")
        self.save_text_btn.clicked.connect(self.on_save_text)

        self.save_pdf_btn = QPushButton("Save as PDF")
        self.save_pdf_btn.clicked.connect(self.on_save_pdf)

        self.print_btn = QPushButton("Print")
        self.print_btn.clicked.connect(self.on_print)

        action_layout.addWidget(self.save_text_btn)
        action_layout.addWidget(self.save_pdf_btn)
        action_layout.addWidget(self.print_btn)

        # Main layout assembly
        layout.addLayout(template_layout)
        layout.addLayout(printer_layout)
        layout.addWidget(self.demo_checkbox)
        layout.addWidget(self.preview_group)
        layout.addLayout(action_layout)

        self.setLayout(layout)

        # Connect template selector to update preview
        self.template_selector.currentTextChanged.connect(self.on_template_changed)

    def refresh_templates(self):
        # Get available templates
        self.template_selector.clear()
        templates = get_available_templates()
        self.template_selector.addItems(templates)
        
    def refresh_printers(self):
        """Get available printers and update the printer selector"""
        current = self.printer_selector.currentText()
        self.printer_selector.clear()
        
        if self.demo_mode:
            printers = ["Demo Printer", "Virtual PDF Printer", "Zebra ZD411"]
        else:
            printers = get_system_printers()
            # Ensure Zebra ZD411 is in the list if not found in system printers
            if "Zebra ZD411" not in printers:
                printers.append("Zebra ZD411")
            
        self.printer_selector.addItems(printers)
        
        # Prefer Zebra ZD411 as default for label printing
        if "Zebra ZD411" in printers:
            index = printers.index("Zebra ZD411")
            self.printer_selector.setCurrentIndex(index)
        # Or use system default
        elif default := get_default_printer():
            if default in printers:
                index = printers.index(default)
                self.printer_selector.setCurrentIndex(index)
        # Or restore previous selection
        elif current and current in printers:
            index = printers.index(current)
            self.printer_selector.setCurrentIndex(index)

    def set_content(self, label_text):
        if not label_text:
            print("DEBUG: Empty label text received in set_content")
            self.clear()
            return
            
        self.label_text = label_text
        
        # Debug log
        print(f"DEBUG: Label preview text to set ({len(label_text)} chars):\n{label_text}")
        
        # Set the preview text
        self.preview_text.setText(label_text)
        
        # Force update the preview to be visible
        self.preview_text.setVisible(True)
        self.preview_text.repaint()
        
        # Debug log the current text in the widget
        current_text = self.preview_text.text()
        print(f"DEBUG: Preview text after setting ({len(current_text)} chars):\n{current_text}")

        # Enable buttons when we have content
        self.save_text_btn.setEnabled(bool(label_text))
        self.save_pdf_btn.setEnabled(bool(label_text))
        self.print_btn.setEnabled(bool(label_text))

    def clear(self):
        print("DEBUG: Clearing label preview")
        self.label_text = ""
        self.preview_text.setText("")
        self.preview_text.repaint()

        # Disable buttons when no content
        self.save_text_btn.setEnabled(False)
        self.save_pdf_btn.setEnabled(False)
        self.print_btn.setEnabled(False)

    def on_template_changed(self, template_name):
        print(f"DEBUG: Template changed to: {template_name}")
        # Re-emit the signal to regenerate label with the new template
        self.print_requested.emit(template_name)

    def on_save_text(self):
        if not self.label_text:
            return

        file_path, _ = QFileDialog.getSaveFileName(
            self, "Save Label as Text", "", "Text Files (*.txt);;All Files (*)"
        )

        if file_path:
            success = save_to_file(self.label_text, file_path)
            if success:
                QMessageBox.information(self, "Success", "Label saved successfully.")
            else:
                QMessageBox.warning(self, "Error", "Failed to save label.")

    def on_save_pdf(self):
        if not self.label_text:
            return

        file_path, _ = QFileDialog.getSaveFileName(
            self, "Save Label as PDF", "", "PDF Files (*.pdf);;All Files (*)"
        )

        if file_path:
            success = save_to_pdf(self.label_text, file_path)
            if success:
                QMessageBox.information(self, "Success", "PDF saved successfully.")
            else:
                QMessageBox.warning(self, "Error", "Failed to save PDF. Make sure ReportLab is installed.")

    def on_print(self):
        if not self.label_text:
            return
            
        template = self.template_selector.currentText()
        printer = self.printer_selector.currentText()
        
        if self.demo_mode:
            QMessageBox.information(
                self, "Demo Print", 
                f"[DEMO MODE] Label would be printed using template: {template}\n\n"
                f"Printer selected: {printer}\n\n"
                f"In a real environment, this would send the label to the printer."
            )
            # Show a simulated progress message
            QApplication.processEvents()
            if self.status_bar:
                QTimer.singleShot(500, lambda: self.status_bar.showMessage("Demo printing completed"))
            
            # Emit the signal to log the print
            self.print_requested.emit(template)
        else:
            if not printer:
                # No printer selected, try to get default
                printer = get_default_printer()
                
            if not printer:
                QMessageBox.warning(
                    self, "No Printer Selected", 
                    "No printer is selected or available. Please select a printer and try again."
                )
                return
                
            # Confirm printing
            confirm = QMessageBox.question(
                self, "Confirm Print", 
                f"Print label to {printer}?",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
            )
            
            if confirm == QMessageBox.StandardButton.Yes:
                # Show printing in progress
                if self.status_bar:
                    self.status_bar.showMessage(f"Sending label to {printer}...")
                QApplication.processEvents()
                
                # Print the label
                success, message = print_label(self.label_text, printer)
                if success:
                    QMessageBox.information(self, "Print Status", f"Label sent to printer: {printer}")
                    # Log the print operation
                    self.print_requested.emit(template)
                else:
                    QMessageBox.warning(self, "Print Error", f"Error printing label: {message}")
                        
            
    def toggle_demo_mode(self, enabled):
        """Toggle between demo mode and real printing"""
        self.demo_mode = enabled
        status = "enabled" if enabled else "disabled"
        print(f"Demo mode {status}")
        # Refresh printer list when demo mode changes
        self.refresh_printers()
        
        # Update the UI to reflect demo mode status
        if enabled:
            self.print_btn.setText("Demo Print")
        else:
            self.print_btn.setText("Print")


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.inventory_df = None
        self.current_item = None
        self.demo_inventory = None  # For demo/fallback data
        self.demo_mode = os.environ.get("SCANPRINT_DEMO_MODE", "0") == "1"
        self.init_ui()
        self.load_inventory_data()
        self.create_demo_inventory()  # Create demo data as fallback

    def init_ui(self):
        self.setWindowTitle("scanprint - Inventory Labeling System")
        self.setMinimumSize(800, 600)

        # Central widget and main layout
        central_widget = QWidget()
        main_layout = QVBoxLayout()

        # Scan widget
        self.scan_widget = BarcodeScanWidget()

        # Split the window into left (results) and right (preview) panels
        content_layout = QHBoxLayout()

        # Left panel - Search results
        self.result_widget = InventoryResultWidget()

        # Right panel - Label preview
        self.preview_widget = LabelPreviewWidget()
        
        # Add widgets to layouts
        content_layout.addWidget(self.result_widget, 1)
        content_layout.addWidget(self.preview_widget, 1)

        main_layout.addWidget(self.scan_widget)
        main_layout.addLayout(content_layout)

        # Status bar
        self.status_bar = QStatusBar()
        self.setStatusBar(self.status_bar)
        self.status_bar.showMessage("Ready. Scan a barcode to begin.")
        
        # Give the preview widget access to the status bar
        self.preview_widget.status_bar = self.status_bar

        # Set the main layout
        central_widget.setLayout(main_layout)
        self.setCentralWidget(central_widget)

        # Connect signals
        self.scan_widget.scan_detected.connect(self.on_barcode_scan)
        self.result_widget.generate_label_requested.connect(self.on_generate_label)
        self.preview_widget.print_requested.connect(self.on_print_label)

        # Set initial focus to the scan input
        self.scan_widget.set_focus()

    def load_inventory_data(self):
        # Default inventory file path - use module-relative path
        inventory_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "inventory", "marktpos_export.csv"
        )

        try:
            self.inventory_df = load_inventory(inventory_path)
            count = len(self.inventory_df)
            self.status_bar.showMessage(f"Loaded {count} inventory items.")
        except FileNotFoundError:
            self.status_bar.showMessage("Inventory file not found. Using demo data.")
            QMessageBox.warning(
                self, "Notice",
                f"Inventory file not found at:\n{inventory_path}\n\nSwitching to demo inventory data."
            )
            # We'll use demo inventory instead
        except ValueError as e:
            self.status_bar.showMessage(f"Error loading inventory: {e}. Using demo data.")
            QMessageBox.warning(
                self, "Notice",
                f"Error loading inventory data: {e}\n\nSwitching to demo inventory data."
            )
            # We'll use demo inventory instead
            
    def create_demo_inventory(self):
        """Create demo inventory data for testing without a real inventory file"""
        # Create a demo DataFrame with sample products
        demo_data = [
            {
                'product_name': 'Demo Product 1', 
                'sku': 'DP001', 
                'barcode': '123456789012',
                'department': 'Electronics', 
                'price': 19.99, 
                'cost': 10.50,
                'quantity': 25, 
                'supplier': 'Demo Supplier Inc.'
            },
            {
                'product_name': 'Demo Product 2', 
                'sku': 'DP002', 
                'barcode': '723456789013',
                'department': 'Home Goods', 
                'price': 34.95, 
                'cost': 18.25,
                'quantity': 12, 
                'supplier': 'Test Wholesale LLC'
            },
            {
                'product_name': 'Demo Product 3', 
                'sku': 'DP003', 
                'barcode': '823456789014',
                'department': 'Clothing', 
                'price': 24.50, 
                'cost': 12.75,
                'quantity': 18, 
                'supplier': 'Sample Distributors'
            },
            {
                'product_name': 'Demo Product 4', 
                'sku': 'DP004', 
                'barcode': '923456789015',
                'department': 'Food', 
                'price': 5.99, 
                'cost': 2.50,
                'quantity': 50, 
                'supplier': 'Mock Foods Co.'
            }
        ]
        
        self.demo_inventory = pd.DataFrame(demo_data)
        
        # If no real inventory was loaded, use the demo inventory
        if self.inventory_df is None:
            self.inventory_df = self.demo_inventory
            count = len(self.inventory_df)
            self.status_bar.showMessage(f"Using demo inventory with {count} items.")

    def on_barcode_scan(self, barcode):
        if self.inventory_df is None:
            self.status_bar.showMessage("No inventory data loaded.")
            return

        # Clear previous results
        self.current_item = None
        self.result_widget.clear()
        self.preview_widget.clear()

        # Search for item by barcode
        self.current_item = search_by_barcode(self.inventory_df, barcode)

        if self.current_item:
            self.status_bar.showMessage(f"Item found: {self.current_item.get('product_name', '')}")
            self.result_widget.set_item(self.current_item)
        else:
            # In demo mode, generate a fake item if not found
            if self.preview_widget.demo_mode:
                self.current_item = self.generate_demo_item(barcode)
                self.status_bar.showMessage(f"Demo item generated for barcode: {barcode}")
                self.result_widget.set_item(self.current_item)
            else:
                self.status_bar.showMessage(f"No item found with barcode: {barcode}")
                QMessageBox.information(
                    self, "Not Found",
                    f"No item found with barcode: {barcode}"
                )
                
    def generate_demo_item(self, barcode):
        """Generate a demo item for barcodes not found in inventory"""
        # Create a random demo product
        departments = ["Electronics", "Home Goods", "Clothing", "Food", "Toys", "Hardware"]
        suppliers = ["Demo Supplier Inc.", "Test Wholesale LLC", "Sample Distributors", "Mock Foods Co."]
        
        return {
            'product_name': f'Demo Product {barcode[-4:]}', 
            'sku': f'DP{barcode[-4:]}', 
            'barcode': barcode,
            'department': random.choice(departments), 
            'price': round(random.uniform(4.99, 99.99), 2), 
            'cost': round(random.uniform(2.50, 50.00), 2),
            'quantity': random.randint(5, 100), 
            'supplier': random.choice(suppliers)
        }

    def on_generate_label(self, item_data):
        if not item_data:
            print("DEBUG: No item data in on_generate_label")
            return

        # Get the selected template
        template_name = self.preview_widget.template_selector.currentText()
        print(f"DEBUG: Using template: {template_name}")

        # Generate the label
        label_text = generate_label(item_data, template_name)
        print(f"DEBUG: Generated label text ({len(label_text)} chars):\n{label_text}")

        # Update the preview
        self.preview_widget.set_content(label_text)
        
        # Make sure the preview is shown and refreshed
        self.preview_widget.preview_text.repaint()
        QApplication.processEvents()

        self.status_bar.showMessage(f"Label generated for {item_data.get('product_name', '')}")

    def on_print_label(self, template_name):
        if not self.current_item:
            return

        # Regenerate the label with the selected template
        label_text = generate_label(self.current_item, template_name)

        # Update the preview
        self.preview_widget.set_content(label_text)

        # Log the print history
        log_print_history(self.current_item, template_name)

        # Get the selected printer
        printer_name = self.preview_widget.printer_selector.currentText()

        if self.preview_widget.demo_mode:
            self.status_bar.showMessage(f"[DEMO] Label simulated printing to {printer_name} using template: {template_name}")
        else:
            # Use the printer module to actually print the label
            success, message = print_label(label_text, printer_name)
            if success:
                self.status_bar.showMessage(f"Label printed to {printer_name}: {message}")
            else:
                self.status_bar.showMessage(f"Error printing to {printer_name}: {message}")


def main():
    """Application entry point"""
    app = QApplication(sys.argv)

    # Set application style
    app.setStyle("Fusion")

    # Create and show the main window
    window = MainWindow()
    window.show()

    # Start the application event loop
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
