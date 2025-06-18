import json
import requests
from typing import Dict, List, Optional, Tuple, Any, Union

class ShopClient:
    """
    Python client for the Tandemx Shop API.
    """
    
    def __init__(self, base_url: str, api_key: Optional[str] = None):
        """
        Initialize the shop client with the base URL and optional API key.
        
        Args:
            base_url: The base URL of the API (e.g., "http://localhost:8000")
            api_key: Optional API key for authentication
        """
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }
        
        if api_key:
            self.headers['Authorization'] = f'Bearer {api_key}'
    
    def _handle_response(self, response: requests.Response) -> Dict[str, Any]:
        """
        Handle API response, raising exceptions for error responses.
        
        Args:
            response: The requests Response object
            
        Returns:
            The parsed JSON response
            
        Raises:
            ValueError: If the API returns an error
        """
        if not response.ok:
            try:
                error_data = response.json()
                error_message = error_data.get('error', f"HTTP {response.status_code}")
            except Exception:
                error_message = f"HTTP {response.status_code}: {response.text}"
            
            raise ValueError(f"API Error: {error_message}")
        
        return response.json()
    
    # Product operations
    
    def get_products(self, page: int = 1, limit: int = 20) -> Dict[str, Any]:
        """
        Get a paginated list of products.
        
        Args:
            page: Page number (starting from 1)
            limit: Number of items per page (max 100)
            
        Returns:
            Dict containing product data and pagination metadata
        """
        url = f"{self.base_url}/api/shop/products"
        params = {'page': page, 'limit': limit}
        response = requests.get(url, params=params, headers=self.headers)
        return self._handle_response(response)
    
    def get_product(self, product_id: int) -> Dict[str, Any]:
        """
        Get a single product by ID.
        
        Args:
            product_id: The product ID
            
        Returns:
            Dict containing product data
        """
        url = f"{self.base_url}/api/shop/products/{product_id}"
        response = requests.get(url, headers=self.headers)
        return self._handle_response(response)
    
    def create_product(
        self, 
        name: str, 
        description: str, 
        price: float, 
        sku: str, 
        stock_quantity: int
    ) -> Dict[str, Any]:
        """
        Create a new product.
        
        Args:
            name: Product name
            description: Product description
            price: Product price
            sku: Stock keeping unit (unique identifier)
            stock_quantity: Initial stock quantity
            
        Returns:
            Dict containing the created product data
        """
        url = f"{self.base_url}/api/shop/products"
        data = {
            'name': name,
            'description': description,
            'price': price,
            'sku': sku,
            'stock_quantity': stock_quantity
        }
        response = requests.post(url, json=data, headers=self.headers)
        return self._handle_response(response)
    
    # Order operations
    
    def create_order(
        self, 
        items: List[Dict[str, Any]], 
        user_id: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Create a new order.
        
        Args:
            items: List of order items, each containing product_id, quantity, 
                  unit_price, name, and sku
            user_id: Optional user ID for registered users
            
        Returns:
            Dict containing the created order data
        """
        url = f"{self.base_url}/api/shop/orders"
        data = {
            'items': items
        }
        
        if user_id is not None:
            data['user_id'] = user_id
            
        response = requests.post(url, json=data, headers=self.headers)
        return self._handle_response(response)
    
    def get_order(self, order_id: int) -> Dict[str, Any]:
        """
        Get order details by ID.
        
        Args:
            order_id: The order ID
            
        Returns:
            Dict containing order data with items
        """
        url = f"{self.base_url}/api/shop/orders/{order_id}"
        response = requests.get(url, headers=self.headers)
        return self._handle_response(response)
    
    def get_orders(self, page: int = 1, limit: int = 20) -> Dict[str, Any]:
        """
        Get a paginated list of orders.
        
        Args:
            page: Page number (starting from 1)
            limit: Number of items per page (max 100)
            
        Returns:
            Dict containing order data and pagination metadata
        """
        url = f"{self.base_url}/api/shop/orders"
        params = {'page': page, 'limit': limit}
        response = requests.get(url, params=params, headers=self.headers)
        return self._handle_response(response)


# Example usage
if __name__ == "__main__":
    # Initialize client
    client = ShopClient("http://localhost:8000")
    
    try:
        # Create a product
        product = client.create_product(
            name="Test Product",
            description="A test product",
            price=19.99,
            sku="TEST-123",
            stock_quantity=100
        )
        print(f"Created product: {product['name']} (ID: {product['id']})")
        
        # Create an order
        order = client.create_order(
            items=[
                {
                    "product_id": product["id"],
                    "quantity": 2,
                    "unit_price": product["price"],
                    "name": product["name"],
                    "sku": product["sku"]
                }
            ]
        )
        print(f"Created order: {order['id']} (Total: {order['total_amount']})")
        
        # Get order details
        order_details = client.get_order(order["id"])
        print(f"Order has {len(order_details['items'])} items")
        
    except ValueError as e:
        print(f"Error: {e}")