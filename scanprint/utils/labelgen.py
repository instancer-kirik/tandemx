import os
import datetime
from typing import Dict, List, Any
import re

# Default templates directory
TEMPLATE_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'labels', 'templates')
HISTORY_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'labels', 'history.csv')

def get_available_templates() -> List[str]:
    """
    Get a list of available label templates.
    
    Returns:
        List of template names (without file extension)
    """
    print(f"DEBUG: Getting available templates from: {TEMPLATE_DIR}")
    
    if not os.path.exists(TEMPLATE_DIR):
        print(f"DEBUG: Templates directory does not exist, creating it")
        os.makedirs(TEMPLATE_DIR, exist_ok=True)
        
        # Create default templates if none exist
        default_path = os.path.join(TEMPLATE_DIR, 'default.txt')
        print(f"DEBUG: Creating default template at: {default_path}")
        with open(default_path, 'w') as f:
            f.write("{product_name}\n"
                   "Price: ${price:.2f}\n"
                   "SKU: {sku}\n"
                   "Barcode: {barcode}\n"
                   "Dept: {department}")
        
        # Create a price tag template
        price_tag_path = os.path.join(TEMPLATE_DIR, 'price_tag.txt')
        print(f"DEBUG: Creating price tag template at: {price_tag_path}")
        with open(price_tag_path, 'w') as f:
            f.write("SPECIAL PRICE\n"
                   "{product_name}\n"
                   "${price:.2f}\n"
                   "SKU: {sku}\n"
                   "{barcode}")
            
        # Create a Zebra label template
        zebra_path = os.path.join(TEMPLATE_DIR, 'zebra_label.txt')
        print(f"DEBUG: Creating Zebra label template at: {zebra_path}")
        with open(zebra_path, 'w') as f:
            f.write("OVERSTOCK\n"
                   "{product_name}\n"
                   "${price:.2f}\n"
                   "SKU: {sku}\n"
                   "UPC: {barcode}")
    
    templates = [f[:-4] for f in os.listdir(TEMPLATE_DIR) 
                if f.endswith('.txt')]
    print(f"DEBUG: Found templates: {templates}")
    
    # Ensure we have at least one template
    if not templates:
        print("DEBUG: No templates found, creating default template")
        default_path = os.path.join(TEMPLATE_DIR, 'default.txt')
        with open(default_path, 'w') as f:
            f.write("{product_name}\n"
                   "Price: ${price:.2f}\n"
                   "SKU: {sku}\n"
                   "Barcode: {barcode}\n"
                   "Dept: {department}")
        templates = ['default']
    
    return templates


def load_template(template_name: str) -> str:
    """
    Load a template format from file.
    
    Args:
        template_name: Name of the template (without extension)
        
    Returns:
        Template format string
        
    Raises:
        FileNotFoundError: If template doesn't exist
    """
    template_path = os.path.join(TEMPLATE_DIR, f"{template_name}.txt")
    print(f"DEBUG: Looking for template at: {template_path}")
    
    if not os.path.exists(template_path):
        print(f"DEBUG: Template not found: {template_name}")
        raise FileNotFoundError(f"Template not found: {template_name}")
    
    with open(template_path, 'r') as f:
        content = f.read()
        print(f"DEBUG: Loaded template '{template_name}' with {len(content)} characters")
        return content


def generate_label(item_data: Dict[str, Any], template_name: str = 'default') -> str:
    """
    Create formatted label text for an item.
    
    Args:
        item_data: Dictionary with item data
        template_name: Name of the template to use
        
    Returns:
        Formatted label text
    """
    print(f"DEBUG: Generating label with template '{template_name}'")
    print(f"DEBUG: Item data: {item_data}")
    
    try:
        template = load_template(template_name)
        print(f"DEBUG: Loaded template: {template}")
    except FileNotFoundError:
        # Fall back to default template format
        template = ("{product_name}\n"
                   "Price: ${price:.2f}\n"
                   "SKU: {sku}\n"
                   "Barcode: {barcode}\n"
                   "Dept: {department}")
        print(f"DEBUG: Using fallback template: {template}")
    
    # Create a copy of the data to avoid modifying the original
    formatted_data = dict(item_data)
    
    # Format price with 2 decimal places if it exists
    if 'price' in formatted_data and formatted_data['price'] is not None:
        try:
            formatted_data['price'] = float(formatted_data['price'])
            print(f"DEBUG: Formatted price: {formatted_data['price']}")
        except (ValueError, TypeError) as e:
            print(f"DEBUG: Error formatting price: {e}")
            pass  # Keep original if conversion fails
    
    # Format cost with 2 decimal places if it exists
    if 'cost' in formatted_data and formatted_data['cost'] is not None:
        try:
            formatted_data['cost'] = float(formatted_data['cost'])
            print(f"DEBUG: Formatted cost: {formatted_data['cost']}")
        except (ValueError, TypeError) as e:
            print(f"DEBUG: Error formatting cost: {e}")
            pass
    
    # Ensure all fields exist with placeholder values
    for field in ['product_name', 'sku', 'barcode', 'department', 'price', 'cost', 'quantity', 'supplier', 'description']:
        if field not in formatted_data or formatted_data[field] is None:
            formatted_data[field] = f"<No {field}>"
            print(f"DEBUG: Added placeholder for missing field: {field}")
    
    # Apply the template using string formatting
    try:
        result = template.format(**formatted_data)
        print(f"DEBUG: Successfully formatted template, result length: {len(result)}")
        return result
    except KeyError as e:
        # Handle missing fields by replacing them with placeholders
        missing_field = str(e).strip("'")
        print(f"DEBUG: Missing field in template: {missing_field}")
        # Create a placeholder for the missing field
        formatted_data[missing_field] = f"<No {missing_field}>"
        # Try again with the added placeholder
        try:
            result = template.format(**formatted_data)
            print(f"DEBUG: Successfully formatted with placeholder, result length: {len(result)}")
            return result
        except Exception as e:
            print(f"DEBUG: Template formatting failed again: {e}")
            # If still failing, use a simplified template
            fallback = (f"{formatted_data['product_name']}\n"
                       f"Price: ${formatted_data['price']:.2f}\n"
                       f"SKU: {formatted_data['sku']}\n"
                       f"Barcode: {formatted_data['barcode']}")
            print(f"DEBUG: Using simplified fallback template: {fallback}")
            return fallback


def save_to_file(label_text: str, output_path: str) -> bool:
    """
    Export a label as a text file.
    
    Args:
        label_text: The formatted label text
        output_path: Path to save the text file
        
    Returns:
        True if successful, False otherwise
    """
    try:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        with open(output_path, 'w') as f:
            f.write(label_text)
        return True
    except Exception as e:
        print(f"Error saving label to file: {e}")
        return False


def save_to_pdf(label_text: str, output_path: str) -> bool:
    """
    Export a label as a PDF file.
    
    Args:
        label_text: The formatted label text
        output_path: Path to save the PDF file
        
    Returns:
        True if successful, False otherwise
        
    Note:
        This requires reportlab to be installed.
        Run: pip install reportlab
    """
    # Try to import reportlab - dependency will be optional
    reportlab_available = False
    try:
        # Only import when needed to avoid dependency issues
        import reportlab
        from reportlab.lib.pagesizes import letter
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
        from reportlab.lib.styles import getSampleStyleSheet
        reportlab_available = True
    except ImportError:
        print("ReportLab is required for PDF generation. Install with: pip install reportlab")
        return False
        
    if not reportlab_available:
        return False
    
    try:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Create a PDF document
        doc = SimpleDocTemplate(output_path, pagesize=letter)
        styles = getSampleStyleSheet()
        
        # Convert label text to paragraphs
        label_parts = label_text.split('\n')
        story = []
        
        # Add each line as a paragraph
        for i, part in enumerate(label_parts):
            style = styles['Title'] if i == 0 else styles['Normal']
            story.append(Paragraph(part, style))
            if i < len(label_parts) - 1:
                story.append(Spacer(1, 6))  # Add space between paragraphs
        
        # Build the PDF
        doc.build(story)
        return True
    except Exception as e:
        print(f"Error saving label to PDF: {e}")
        return False


def log_print_history(item_data: Dict[str, Any], template_used: str) -> None:
    """
    Record a printed label in the history log.
    
    Args:
        item_data: Dictionary with item data
        template_used: Name of the template used
    """
    # Ensure history directory exists
    os.makedirs(os.path.dirname(HISTORY_FILE), exist_ok=True)
    
    # Create history file with headers if it doesn't exist
    if not os.path.exists(HISTORY_FILE):
        with open(HISTORY_FILE, 'w') as f:
            f.write("timestamp,barcode,sku,product_name,price,department,template\n")
    
    # Format the record
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    barcode = item_data.get('barcode', '')
    sku = item_data.get('sku', '')
    product_name = item_data.get('product_name', '').replace(',', ' ')  # Avoid CSV issues
    price = item_data.get('price', 0)
    department = item_data.get('department', '').replace(',', ' ')  # Avoid CSV issues
    
    # Append to history file
    with open(HISTORY_FILE, 'a') as f:
        f.write(f"{timestamp},{barcode},{sku},{product_name},{price},{department},{template_used}\n")


def create_custom_template(template_name: str, template_content: str) -> bool:
    """
    Create a new custom label template.
    
    Args:
        template_name: Name for the new template
        template_content: Template format string
        
    Returns:
        True if successful, False otherwise
    """
    try:
        # Ensure template directory exists
        os.makedirs(TEMPLATE_DIR, exist_ok=True)
        
        # Sanitize template name
        template_name = re.sub(r'[^\w\-]', '_', template_name)
        
        # Save the template
        template_path = os.path.join(TEMPLATE_DIR, f"{template_name}.txt")
        with open(template_path, 'w') as f:
            f.write(template_content)
        
        return True
    except Exception as e:
        print(f"Error creating template: {e}")
        return False