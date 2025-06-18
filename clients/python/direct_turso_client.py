import os
import httpx
import sqlite3
import urllib.parse
from typing import Dict, List, Any, Optional, Tuple, Union


class TursoClient:
    """
    A Python client for directly connecting to Turso databases.
    
    This client supports both:
    1. HTTP API access to remote Turso databases
    2. Local SQLite connection for development
    """
    
    def __init__(
        self, 
        database_url: Optional[str] = None,
        auth_token: Optional[str] = None,
        db_name: Optional[str] = None,
        local_path: str = "tandemx.db"
    ):
        """
        Initialize the Turso client.
        
        Args:
            database_url: Full Turso database URL (overrides other parameters if provided)
            auth_token: Turso authentication token
            db_name: Turso database name
            local_path: Path to local SQLite database (used if no remote connection info provided)
        """
        self.database_url = database_url or os.environ.get("TURSO_DATABASE_URL")
        self.auth_token = auth_token or os.environ.get("TURSO_AUTH_TOKEN")
        self.db_name = db_name or os.environ.get("TURSO_DB_NAME")
        self.local_path = local_path
        self.connection = None
        self.is_remote = False
        
        # Try to connect
        self._connect()
    
    def _connect(self) -> None:
        """Establish a connection to either remote Turso or local SQLite"""
        if self.database_url:
            # Use provided database URL
            self.is_remote = "turso.io" in self.database_url or "libsql" in self.database_url
        elif self.db_name and self.auth_token:
            # Construct URL from components
            self.database_url = f"https://{self.db_name}.turso.io"
            self.is_remote = True
        else:
            # Default to local SQLite
            self.database_url = f"file:{self.local_path}"
            self.is_remote = False
        
        if not self.is_remote:
            # Local SQLite connection
            self.connection = sqlite3.connect(self.database_url.replace("file:", ""))
            self.connection.row_factory = sqlite3.Row
        # For remote, we'll use HTTP for each query, so no persistent connection needed
    
    def close(self) -> None:
        """Close the database connection if it exists"""
        if not self.is_remote and self.connection:
            self.connection.close()
            self.connection = None
    
    def _http_query(self, query: str, params: List[Any] = None) -> Dict[str, Any]:
        """Execute a query via HTTP API (for remote Turso)"""
        if not params:
            params = []
            
        # Convert parameters to the format expected by the Turso HTTP API
        converted_params = []
        for param in params:
            if isinstance(param, int):
                converted_params.append({"type": "integer", "value": param})
            elif isinstance(param, float):
                converted_params.append({"type": "float", "value": param})
            elif isinstance(param, bool):
                converted_params.append({"type": "boolean", "value": param})
            elif param is None:
                converted_params.append({"type": "null", "value": None})
            else:
                converted_params.append({"type": "text", "value": str(param)})
        
        # Prepare request
        headers = {
            "Content-Type": "application/json",
        }
        
        if self.auth_token:
            headers["Authorization"] = f"Bearer {self.auth_token}"
        
        data = {
            "stmt": query,
            "params": converted_params
        }
        
        # Make request
        with httpx.Client() as client:
            response = client.post(
                f"{self.database_url}/execute",
                json=data,
                headers=headers,
                timeout=30.0
            )
            
            if response.status_code != 200:
                raise Exception(f"Query failed: {response.status_code} - {response.text}")
                
            return response.json()
    
    def _local_query(self, query: str, params: List[Any] = None) -> Dict[str, Any]:
        """Execute a query via local SQLite connection"""
        if not params:
            params = []
            
        cursor = self.connection.cursor()
        try:
            cursor.execute(query, params)
            
            if query.strip().upper().startswith(("SELECT", "PRAGMA")):
                rows = cursor.fetchall()
                columns = [desc[0] for desc in cursor.description] if cursor.description else []
                
                # Convert sqlite3.Row objects to dictionaries
                result_rows = []
                for row in rows:
                    result_rows.append({columns[i]: row[i] for i in range(len(columns))})
                
                return {
                    "results": {
                        "columns": columns,
                        "rows": result_rows
                    }
                }
            else:
                self.connection.commit()
                return {
                    "results": {
                        "last_insert_rowid": cursor.lastrowid,
                        "rows_affected": cursor.rowcount
                    }
                }
        except sqlite3.Error as e:
            self.connection.rollback()
            raise Exception(f"Query failed: {str(e)}")
        finally:
            cursor.close()
    
    def execute(self, query: str, params: List[Any] = None) -> Dict[str, Any]:
        """
        Execute a SQL query with parameters.
        
        Args:
            query: SQL query string
            params: List of parameters for the query
            
        Returns:
            Dictionary with query results
        """
        if self.is_remote:
            return self._http_query(query, params)
        else:
            return self._local_query(query, params)
    
    def execute_batch(self, queries: List[Tuple[str, List[Any]]]) -> List[Dict[str, Any]]:
        """
        Execute multiple SQL queries in sequence.
        
        Args:
            queries: List of (query, params) tuples
            
        Returns:
            List of result dictionaries
        """
        results = []
        
        if self.is_remote:
            # For remote, execute each query separately via HTTP
            for query, params in queries:
                results.append(self._http_query(query, params))
        else:
            # For local, use a transaction
            if not self.connection:
                raise Exception("No active connection")
                
            try:
                self.connection.execute("BEGIN TRANSACTION")
                for query, params in queries:
                    results.append(self._local_query(query, params or []))
                self.connection.execute("COMMIT")
            except Exception as e:
                self.connection.execute("ROLLBACK")
                raise e
                
        return results
    
    # Higher-level helper methods for common operations
    
    def get_products(self, limit: int = 20, offset: int = 0) -> List[Dict[str, Any]]:
        """Get a list of products with pagination"""
        result = self.execute(
            "SELECT * FROM products ORDER BY created_at DESC LIMIT ? OFFSET ?",
            [limit, offset]
        )
        
        if self.is_remote:
            return result.get("results", {}).get("rows", [])
        else:
            return result.get("results", {}).get("rows", [])
    
    def get_product(self, product_id: int) -> Optional[Dict[str, Any]]:
        """Get a single product by ID"""
        result = self.execute(
            "SELECT * FROM products WHERE id = ?",
            [product_id]
        )
        
        rows = result.get("results", {}).get("rows", [])
        return rows[0] if rows else None
    
    def create_product(
        self, 
        name: str, 
        description: str, 
        price: float, 
        sku: str, 
        stock_quantity: int
    ) -> Dict[str, Any]:
        """Create a new product"""
        result = self.execute(
            """
            INSERT INTO products (name, description, price, sku, stock_quantity, status) 
            VALUES (?, ?, ?, ?, ?, 'active')
            RETURNING *
            """,
            [name, description, price, sku, stock_quantity]
        )
        
        rows = result.get("results", {}).get("rows", [])
        if rows:
            return rows[0]
        else:
            # Get the ID of the inserted row
            last_id = result.get("results", {}).get("last_insert_rowid")
            if last_id:
                # Fetch the inserted product
                get_result = self.execute("SELECT * FROM products WHERE id = ?", [last_id])
                rows = get_result.get("results", {}).get("rows", [])
                if rows:
                    return rows[0]
        
        raise Exception("Failed to create product")
    
    def create_order(
        self, 
        items: List[Dict[str, Any]], 
        user_id: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Create a new order with items.
        
        Args:
            items: List of order items, each with product_id, quantity, unit_price
            user_id: Optional user ID
            
        Returns:
            Created order with items
        """
        # Calculate total amount
        total_amount = sum(item["unit_price"] * item["quantity"] for item in items)
        
        # Start a batch of queries
        queries = []
        
        # Create order
        if user_id:
            order_query = (
                "INSERT INTO orders (user_id, total_amount, status) VALUES (?, ?, 'pending') RETURNING id",
                [user_id, total_amount]
            )
        else:
            order_query = (
                "INSERT INTO orders (total_amount, status) VALUES (?, 'pending') RETURNING id",
                [total_amount]
            )
        
        # Execute the queries as a batch or transaction
        if self.is_remote:
            # For remote, we need to execute one by one
            order_result = self.execute(*order_query)
            order_rows = order_result.get("results", {}).get("rows", [])
            
            if order_rows:
                order_id = order_rows[0].get("id")
            else:
                order_id = order_result.get("results", {}).get("last_insert_rowid")
                
            if not order_id:
                raise Exception("Failed to create order")
                
            # Add order items
            for item in items:
                self.execute(
                    "INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)",
                    [order_id, item["product_id"], item["quantity"], item["unit_price"]]
                )
                
                # Update product stock
                self.execute(
                    "UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?",
                    [item["quantity"], item["product_id"]]
                )
        else:
            # For local, use a transaction
            try:
                self.connection.execute("BEGIN TRANSACTION")
                
                # Create order
                cursor = self.connection.cursor()
                if user_id:
                    cursor.execute(
                        "INSERT INTO orders (user_id, total_amount, status) VALUES (?, ?, 'pending')",
                        [user_id, total_amount]
                    )
                else:
                    cursor.execute(
                        "INSERT INTO orders (total_amount, status) VALUES (?, 'pending')",
                        [total_amount]
                    )
                
                order_id = cursor.lastrowid
                
                # Add order items
                for item in items:
                    cursor.execute(
                        "INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)",
                        [order_id, item["product_id"], item["quantity"], item["unit_price"]]
                    )
                    
                    # Update product stock
                    cursor.execute(
                        "UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?",
                        [item["quantity"], item["product_id"]]
                    )
                
                self.connection.commit()
            except Exception as e:
                self.connection.rollback()
                raise e
        
        # Get the created order with items
        return self.get_order(order_id)
    
    def get_order(self, order_id: int) -> Dict[str, Any]:
        """Get order details with items"""
        # Get order details
        order_result = self.execute(
            "SELECT * FROM orders WHERE id = ?",
            [order_id]
        )
        
        order_rows = order_result.get("results", {}).get("rows", [])
        if not order_rows:
            raise Exception(f"Order {order_id} not found")
            
        order = order_rows[0]
        
        # Get order items
        items_result = self.execute(
            """
            SELECT oi.*, p.name as product_name, p.sku
            FROM order_items oi
            JOIN products p ON oi.product_id = p.id
            WHERE oi.order_id = ?
            """,
            [order_id]
        )
        
        # Add items to order
        order["items"] = items_result.get("results", {}).get("rows", [])
        
        return order


# Example usage
if __name__ == "__main__":
    # For local development
    client = TursoClient(local_path="shop.db")
    
    # For production with environment variables
    # client = TursoClient()
    
    # Initialize schema if needed
    client.execute("""
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            price REAL NOT NULL,
            sku TEXT UNIQUE,
            stock_quantity INTEGER DEFAULT 0,
            status TEXT DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
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
                "unit_price": product["price"]
            }
        ]
    )
    
    print(f"Created order: {order['id']} with {len(order['items'])} items")
    
    # Clean up
    client.close()