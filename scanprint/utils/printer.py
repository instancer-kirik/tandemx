import os
import tempfile
import platform
import subprocess
from typing import Optional, Dict, Any, Tuple, List, Union

# Constants for printer settings
DEFAULT_PRINTER = os.environ.get("SCANPRINT_DEFAULT_PRINTER", "")
DEMO_MODE = os.environ.get("SCANPRINT_DEMO_MODE", "0") == "1"

# Zebra ZD411 specific settings
ZEBRA_ZD411 = {
    "name": "Zebra ZD411",
    "dpi": 203,  # Default DPI for ZD411
    "width": 4.0,  # Default width in inches
    "height": 2.5,  # Default height in inches
    "margin_top": 0.1,  # Margins in inches
    "margin_bottom": 0.1,
    "margin_left": 0.1,
    "margin_right": 0.1,
    "orientation": "landscape",  # Default orientation
    "font_size": 10,  # Default font size
}

def get_system_printers() -> List[str]:
    """
    Get a list of available printers on the system.
    
    Returns:
        List of printer names
    """
    if DEMO_MODE:
        return ["Demo Printer", "Virtual PDF Printer", "Zebra ZD411", "Label Printer"]
    
    system = platform.system()
    printers = []
    
    try:
        if system == "Windows":
            # Use Windows specific command
            result = subprocess.run(
                ["wmic", "printer", "get", "name"],
                capture_output=True, text=True, check=False
            )
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')[1:]  # Skip header
                printers = [line.strip() for line in lines if line.strip()]
                
        elif system == "Darwin":  # macOS
            # Use macOS specific command
            result = subprocess.run(
                ["lpstat", "-p"],
                capture_output=True, text=True, check=False
            )
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                printers = [line.split()[1] for line in lines if line.startswith("printer")]
                
        elif system == "Linux":
            # Use CUPS command on Linux
            result = subprocess.run(
                ["lpstat", "-a"],
                capture_output=True, text=True, check=False
            )
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                printers = [line.split()[0] for line in lines if line]
    except Exception as e:
        print(f"Error getting system printers: {e}")
    
    return printers


def get_default_printer() -> Optional[str]:
    """
    Get the default printer name.
    
    Returns:
        Default printer name or None if not available
    """
    if DEMO_MODE:
        return "Demo Printer"
    
    # Check if environment variable is set
    if DEFAULT_PRINTER:
        return DEFAULT_PRINTER
    
    system = platform.system()
    try:
        if system == "Windows":
            # Use Windows specific command to get default printer
            result = subprocess.run(
                ["wmic", "printer", "where", "Default=TRUE", "get", "Name"],
                capture_output=True, text=True, check=False
            )
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')[1:]  # Skip header
                if lines and lines[0].strip():
                    return lines[0].strip()
        
        elif system == "Darwin":  # macOS
            # Use macOS specific command
            result = subprocess.run(
                ["lpstat", "-d"],
                capture_output=True, text=True, check=False
            )
            if result.returncode == 0 and "default destination" in result.stdout:
                return result.stdout.split(":")[-1].strip()
        
        elif system == "Linux":
            # Try CUPS command on Linux
            result = subprocess.run(
                ["lpstat", "-d"],
                capture_output=True, text=True, check=False
            )
            if result.returncode == 0 and "system default destination" in result.stdout:
                return result.stdout.split(":")[-1].strip()
    
    except Exception as e:
        print(f"Error getting default printer: {e}")
    
    return None


def print_text(text: str, printer_name: Optional[str] = None) -> Tuple[bool, str]:
    """
    Print plain text to a printer.
    
    Args:
        text: Text content to print
        printer_name: Name of the printer to use (None for default)
        
    Returns:
        Tuple of (success, message)
    """
    if DEMO_MODE:
        print(f"[DEMO MODE] Simulating printing to {'default printer' if not printer_name else printer_name}")
        print(f"--- Print Content ---\n{text}\n-------------------")
        return True, "Demo print successful"
    
    try:
        # Create a temporary file with the text content
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as temp:
            temp_path = temp.name
            temp.write(text)
        
        system = platform.system()
        cmd = []
        
        if system == "Windows":
            # Windows printing via PowerShell
            ps_cmd = f'Get-Content "{temp_path}" | Out-Printer'
            if printer_name:
                ps_cmd = f'Get-Content "{temp_path}" | Out-Printer -Name "{printer_name}"'
            
            cmd = ["powershell", "-Command", ps_cmd]
            
        elif system in ("Darwin", "Linux"):  # macOS or Linux
            # Use lp command
            cmd = ["lp", temp_path]
            if printer_name:
                cmd.extend(["-d", printer_name])
        
        # Execute the print command
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        
        # Clean up temporary file
        os.unlink(temp_path)
        
        if result.returncode == 0:
            return True, "Print job sent successfully"
        else:
            return False, f"Error printing: {result.stderr}"
            
    except Exception as e:
        return False, f"Error printing: {str(e)}"


def print_pdf(pdf_path: str, printer_name: Optional[str] = None) -> Tuple[bool, str]:
    """
    Print a PDF file to a printer.
    
    Args:
        pdf_path: Path to the PDF file
        printer_name: Name of the printer to use (None for default)
        
    Returns:
        Tuple of (success, message)
    """
    if DEMO_MODE:
        print(f"[DEMO MODE] Simulating printing PDF to {'default printer' if not printer_name else printer_name}")
        print(f"PDF Path: {pdf_path}")
        return True, "Demo PDF print successful"
    
    if not os.path.exists(pdf_path):
        return False, f"PDF file not found: {pdf_path}"
    
    try:
        system = platform.system()
        cmd = []
        
        if system == "Windows":
            # Windows printing via PowerShell and AcroRd32 (Adobe Reader) or SumatraPDF
            # First, try with SumatraPDF if available
            sumatra_cmd = f'SumatraPDF -print-to "{printer_name}" "{pdf_path}"' if printer_name else f'SumatraPDF -print-to-default "{pdf_path}"'
            
            # Try with Adobe Reader if SumatraPDF fails
            adobe_cmd = f'Start-Process -FilePath "AcroRd32.exe" -ArgumentList "/t", "{pdf_path}", "{printer_name}" -Wait'
            
            cmd = ["powershell", "-Command", f"try {{ {sumatra_cmd} }} catch {{ {adobe_cmd} }}"]
            
        elif system == "Darwin":  # macOS
            # Use lp command on macOS
            cmd = ["lp", pdf_path]
            if printer_name:
                cmd.extend(["-d", printer_name])
                
        elif system == "Linux":
            # Use lp command on Linux
            cmd = ["lp", pdf_path]
            if printer_name:
                cmd.extend(["-d", printer_name])
        
        # Execute the print command
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        
        if result.returncode == 0:
            return True, "PDF print job sent successfully"
        else:
            return False, f"Error printing PDF: {result.stderr}"
            
    except Exception as e:
        return False, f"Error printing PDF: {str(e)}"


def print_label(label_text: str, printer_name: Optional[str] = None) -> Tuple[bool, str]:
    """
    Print a label to a label printer.
    
    Args:
        label_text: Text content for the label
        printer_name: Name of the printer to use (None for default)
        
    Returns:
        Tuple of (success, message)
    """
    # Check if this is a Zebra printer
    if printer_name and "Zebra" in printer_name:
        return print_to_zebra(label_text, printer_name)
    
    # For other printers, use standard printing
    return print_text(label_text, printer_name)


def get_printer_status(printer_name: Optional[str] = None) -> Dict[str, Any]:
    """
    Get the status of a printer.
    
    Args:
        printer_name: Name of the printer to check (None for default)
        
    Returns:
        Dictionary with printer status information
    """
    if DEMO_MODE:
        return {
            "name": printer_name or "Demo Printer",
            "status": "Ready",
            "jobs": 0,
            "is_default": True if not printer_name else False,
            "is_available": True
        }
    
    # Default status
    status = {
        "name": printer_name or get_default_printer() or "Unknown",
        "status": "Unknown",
        "jobs": 0,
        "is_default": False,
        "is_available": False
    }
    
    try:
        system = platform.system()
        
        # If no printer name provided, use default
        if not printer_name:
            printer_name = get_default_printer()
            if printer_name:
                status["name"] = printer_name
                status["is_default"] = True
        
        # Get list of available printers
        printers = get_system_printers()
        status["is_available"] = printer_name in printers
        
        if system == "Windows":
            # Check printer status on Windows
            result = subprocess.run(
                ["wmic", "printer", "where", f'name="{printer_name}"', "get", "PrinterStatus"],
                capture_output=True, text=True, check=False
            )
            
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                if len(lines) > 1:
                    # Map numeric status to string
                    status_map = {
                        "3": "Ready",
                        "4": "Printing",
                        "5": "Error",
                    }
                    printer_status = lines[1].strip()
                    status["status"] = status_map.get(printer_status, f"Status {printer_status}")
            
            # Check for print jobs
            result = subprocess.run(
                ["wmic", "printjob", "get", "JobId"],
                capture_output=True, text=True, check=False
            )
            
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                status["jobs"] = max(0, len(lines) - 1)  # Subtract header
                
        elif system in ("Darwin", "Linux"):  # macOS or Linux
            # Check printer status using lpstat
            if printer_name:
                result = subprocess.run(
                    ["lpstat", "-p", printer_name],
                    capture_output=True, text=True, check=False
                )
                
                if result.returncode == 0:
                    if "enabled" in result.stdout:
                        status["status"] = "Ready"
                    elif "disabled" in result.stdout:
                        status["status"] = "Disabled"
            
            # Check for print jobs
            if printer_name:
                result = subprocess.run(
                    ["lpstat", "-o", printer_name],
                    capture_output=True, text=True, check=False
                )
                
                if result.returncode == 0:
                    lines = result.stdout.strip().split('\n')
                    status["jobs"] = len([line for line in lines if line])
    
    except Exception as e:
        status["status"] = f"Error: {str(e)}"
    
    return status


def print_to_zebra(label_text: str, printer_name: str = "Zebra ZD411") -> Tuple[bool, str]:
    """
    Print a label to a Zebra label printer using ZPL commands.
    
    Args:
        label_text: Text content for the label
        printer_name: Name of the Zebra printer
        
    Returns:
        Tuple of (success, message)
    """
    if DEMO_MODE:
        print(f"[DEMO MODE] Simulating printing to Zebra printer: {printer_name}")
        print(f"--- ZPL Content ---\n{format_as_zpl(label_text)}\n-------------------")
        return True, "Demo Zebra print successful"
    
    try:
        # Convert label text to ZPL format
        zpl_data = format_as_zpl(label_text)
        
        # Create a temporary file with the ZPL content
        with tempfile.NamedTemporaryFile(mode='w', suffix='.zpl', delete=False) as temp:
            temp_path = temp.name
            temp.write(zpl_data)
        
        system = platform.system()
        
        if system == "Windows":
            # Use direct printing to Zebra on Windows
            cmd = ["powershell", "-Command", f'Get-Content "{temp_path}" | Out-Printer -Name "{printer_name}"']
        elif system in ("Darwin", "Linux"):
            # Use lp command with raw output for Zebra
            cmd = ["lp", "-d", printer_name, "-o", "raw", temp_path]
        
        # Execute the print command
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        
        # Clean up temporary file
        os.unlink(temp_path)
        
        if result.returncode == 0:
            return True, "Label sent to Zebra printer successfully"
        else:
            return False, f"Error printing to Zebra printer: {result.stderr}"
            
    except Exception as e:
        return False, f"Error printing to Zebra printer: {str(e)}"


def format_as_zpl(label_text: str) -> str:
    """
    Convert plain text to ZPL format for Zebra printers.
    
    Args:
        label_text: Plain text content for the label
        
    Returns:
        ZPL formatted data
    """
    # Basic ZPL template for a text label
    # Start with label format command
    zpl = "^XA"
    
    # Set print width and label dimensions based on ZD411 settings
    zpl += "^PW609"  # Print width for 4" printer at 203 DPI (4 * 203 = 812 dots, but 609 is safe for margins)
    
    # Split text into lines
    lines = label_text.split('\n')
    
    # Start y position (in dots)
    y_pos = 30
    
    # Add each line as text
    for line in lines:
        # Skip empty lines
        if not line.strip():
            y_pos += 30
            continue
            
        # Escape any special characters
        escaped_line = line.replace("^", "\\^").replace("~", "\\~")
        
        # Add text field
        zpl += f"^FO30,{y_pos}^A0N,30,30^FD{escaped_line}^FS"
        
        # Increment y position for next line
        y_pos += 40
    
    # End label format
    zpl += "^XZ"
    
    return zpl


def set_default_printer(printer_name: str) -> Tuple[bool, str]:
    """
    Set the default printer.
    
    Args:
        printer_name: Name of the printer to set as default
        
    Returns:
        Tuple of (success, message)
    """
    if DEMO_MODE:
        print(f"[DEMO MODE] Setting {printer_name} as default printer")
        # Set environment variable for demo mode
        os.environ["SCANPRINT_DEFAULT_PRINTER"] = printer_name
        return True, f"Demo default printer set to {printer_name}"
    
    try:
        system = platform.system()
        
        if system == "Windows":
            # Set default printer on Windows using PowerShell
            cmd = ["powershell", "-Command", f'(New-Object -ComObject WScript.Network).SetDefaultPrinter("{printer_name}")']
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)
            
        elif system == "Darwin":  # macOS
            # Set default printer on macOS
            cmd = ["lpoptions", "-d", printer_name]
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)
            
        elif system == "Linux":
            # Set default printer on Linux using CUPS
            cmd = ["lpoptions", "-d", printer_name]
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        
        if result.returncode == 0:
            # Also set environment variable for consistent behavior
            os.environ["SCANPRINT_DEFAULT_PRINTER"] = printer_name
            return True, f"Default printer set to {printer_name}"
        else:
            return False, f"Error setting default printer: {result.stderr}"
            
    except Exception as e:
        return False, f"Error setting default printer: {str(e)}"