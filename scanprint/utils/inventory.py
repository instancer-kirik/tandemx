import pandas as pd
import os
from typing import Dict, List, Optional, Any


def load_inventory(filepath: str) -> pd.DataFrame:
    """
    Load inventory data from MarktPOS CSV export.
    
    Args:
        filepath: Path to the CSV file
        
    Returns:
        DataFrame containing inventory data
        
    Raises:
        FileNotFoundError: If the inventory file doesn't exist
        ValueError: If the CSV is missing required columns
    """
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Inventory file not found: {filepath}")
    
    # Load CSV with pandas
    df = pd.read_csv(filepath)
    
    # Check for required columns
    required_columns = [
        "Product Name", "SKU", "Barcode", "Department", 
        "Price", "Cost", "Quantity"
    ]
    
    missing_columns = [col for col in required_columns if col not in df.columns]
    if missing_columns:
        raise ValueError(f"Missing required columns: {', '.join(missing_columns)}")
    
    # Convert column names to lowercase with underscores for easier access
    df.columns = [col.lower().replace(' ', '_') for col in df.columns]
    
    # Convert numeric columns to appropriate types
    df['price'] = pd.to_numeric(df['price'], errors='coerce')
    df['cost'] = pd.to_numeric(df['cost'], errors='coerce')
    # Convert to integer type safely (handles NaN values)
    df['quantity'] = pd.to_numeric(df['quantity'], errors='coerce')
    df['quantity'] = df['quantity'].fillna(0).astype(int)
    
    # Ensure barcode and SKU are treated as strings
    df['barcode'] = df['barcode'].fillna('').astype(str)
    df['sku'] = df['sku'].fillna('').astype(str)
    
    return df


def search_by_barcode(inventory_df: pd.DataFrame, barcode: str) -> Optional[Dict[str, Any]]:
    """
    Find an item by its barcode.
    
    Args:
        inventory_df: Inventory DataFrame
        barcode: Barcode to search for
        
    Returns:
        Dictionary with item data or None if not found
    """
    # Convert barcode to string to ensure matching works correctly
    barcode = str(barcode).strip()
    
    # Find items with matching barcode
    result = inventory_df[inventory_df['barcode'] == barcode]
    
    if len(result) == 0:
        return None
    
    # Convert the first matching row to a dictionary
    return result.iloc[0].to_dict()


def search_by_sku(inventory_df: pd.DataFrame, sku: str) -> Optional[Dict[str, Any]]:
    """
    Find an item by its SKU.
    
    Args:
        inventory_df: Inventory DataFrame
        sku: SKU to search for
        
    Returns:
        Dictionary with item data or None if not found
    """
    # Convert SKU to string and strip whitespace
    sku = str(sku).strip()
    
    # Find items with matching SKU
    result = inventory_df[inventory_df['sku'] == sku]
    
    if len(result) == 0:
        return None
    
    # Convert the first matching row to a dictionary
    return result.iloc[0].to_dict()


def search_by_name(inventory_df: pd.DataFrame, name: str) -> pd.DataFrame:
    """
    Search for items by product name (partial match).
    
    Args:
        inventory_df: Inventory DataFrame
        name: Product name to search for (partial match)
        
    Returns:
        DataFrame with matching items
    """
    # Case-insensitive search using string contains
    result = inventory_df[inventory_df['product_name'].str.contains(name, case=False, na=False)]
    return result.copy()


def get_departments(inventory_df: pd.DataFrame) -> List[str]:
    """
    Get a list of unique departments.
    
    Args:
        inventory_df: Inventory DataFrame
        
    Returns:
        List of unique department names
    """
    return sorted(inventory_df['department'].unique().tolist())


def filter_by_department(inventory_df: pd.DataFrame, department: str) -> pd.DataFrame:
    """
    Filter inventory items by department.
    
    Args:
        inventory_df: Inventory DataFrame
        department: Department name to filter by
        
    Returns:
        DataFrame with items in the specified department
    """
    result = inventory_df[inventory_df['department'] == department]
    return result.copy()


def get_suppliers(inventory_df: pd.DataFrame) -> List[str]:
    """
    Get a list of unique suppliers.
    
    Args:
        inventory_df: Inventory DataFrame
        
    Returns:
        List of unique supplier names
    """
    return sorted(inventory_df['supplier'].unique().tolist())


def filter_by_supplier(inventory_df: pd.DataFrame, supplier: str) -> pd.DataFrame:
    """
    Filter inventory items by supplier.
    
    Args:
        inventory_df: Inventory DataFrame
        supplier: Supplier name to filter by
        
    Returns:
        DataFrame with items from the specified supplier
    """
    result = inventory_df[inventory_df['supplier'] == supplier]
    return result.copy()


def get_low_stock_items(inventory_df: pd.DataFrame, threshold: int = 10) -> pd.DataFrame:
    """
    Get items with stock quantity below a certain threshold.
    
    Args:
        inventory_df: Inventory DataFrame
        threshold: Quantity threshold
        
    Returns:
        DataFrame with low stock items
    """
    result = inventory_df[inventory_df['quantity'] <= threshold].sort_values('quantity', ascending=True)
    return result.copy()


def get_overstock_items(inventory_df: pd.DataFrame, threshold: int = 100) -> pd.DataFrame:
    """
    Get items with stock quantity above a certain threshold.
    
    Args:
        inventory_df: Inventory DataFrame
        threshold: Quantity threshold
        
    Returns:
        DataFrame with overstock items
    """
    result = inventory_df[inventory_df['quantity'] >= threshold]
    result = result.sort_values(by='quantity', ascending=False)
    return result.copy()


def calculate_inventory_value(inventory_df: pd.DataFrame) -> Dict[str, float]:
    """
    Calculate the total value of inventory at cost and retail prices.
    
    Args:
        inventory_df: Inventory DataFrame
        
    Returns:
        Dictionary with total cost and retail values
    """
    # Calculate extended cost (cost * quantity) and retail value (price * quantity)
    cost_value = (inventory_df['cost'] * inventory_df['quantity']).sum()
    retail_value = (inventory_df['price'] * inventory_df['quantity']).sum()
    
    return {
        'cost_value': cost_value,
        'retail_value': retail_value,
        'potential_profit': retail_value - cost_value
    }