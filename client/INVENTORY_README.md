# Variety Discount Shop Inventory System

This module provides inventory management capabilities for a variety discount shop. It runs alongside the main TandemX application and provides API endpoints for managing products, inventory transactions, and categories.

## Quick Start

```bash
# Start the server with inventory API
bun start

# Run inventory tests
bun run inventory:test
```

## Accessing the Inventory System

- **Web Interface**: http://localhost:8000/inventory
- **API Endpoints**: http://localhost:8000/inventory/api/shop/...

## Database

The system uses SQLite with the database file stored at:
- `tandemx.db` in the parent directory

## Available API Endpoints

### Products

- **List Products**: `GET /inventory/api/shop/products`
  - Query parameters:
    - `page`: Page number (default: 1)
    - `limit`: Items per page (default: 20, max: 100)
    - `category`: Filter by category
    - `low_stock`: Set to 'true' to show only low stock items

- **Get Product Details**: `GET /inventory/api/shop/products/{id}`

- **Create Product**: `POST /inventory/api/shop/products`
  ```json
  {
    "name": "Paper Towels",
    "description": "Pack of 2 rolls",
    "price": 2.99,
    "discount_price": 1.99,
    "category": "Household",
    "sku": "HOU-123",
    "barcode": "123456789",
    "stock_quantity": 50,
    "location": "Aisle 2",
    "supplier": "HomeGoods",
    "min_stock_level": 10,
    "status": "active"
  }
  ```

- **Update Product**: `PUT /inventory/api/shop/products/{id}`
  ```json
  {
    "price": 3.99,
    "discount_price": 2.49,
    "stock_quantity": 75
  }
  ```

### Inventory Transactions

- **Record Transaction**: `POST /inventory/api/shop/inventory/transactions`
  ```json
  {
    "product_id": 1,
    "quantity": 10,
    "transaction_type": "restock",
    "notes": "Restocked from supplier delivery"
  }
  ```
  Transaction types:
  - `restock`: Increases stock
  - `sale`: Decreases stock
  - `adjustment`: Decreases stock (for losses, damages, etc.)

- **Get Product Transactions**: `GET /inventory/api/shop/products/{id}/transactions`

### Other Endpoints

- **Get Low Stock Products**: `GET /inventory/api/shop/inventory/low-stock`
- **Get All Categories**: `GET /inventory/api/shop/categories`

## Web Interface

The inventory system includes a simple web interface for:

1. Viewing products
2. Adding new products
3. Recording inventory transactions
4. Checking low stock items
5. Testing API functionality

## Integration with Main Application

The inventory system can be accessed from the main TandemX application via a convenient shortcut link that appears in the bottom right corner of the screen.

## Product Fields

- `name` - Product name (required)
- `description` - Product description
- `price` - Regular price (required)
- `discount_price` - Sale price (optional)
- `category` - Product category
- `sku` - Stock keeping unit (required, must be unique)
- `barcode` - Product barcode
- `stock_quantity` - Current inventory count
- `location` - Where the product is located in the store
- `supplier` - Supplier information
- `min_stock_level` - Minimum stock threshold (defaults to 5)
- `status` - Product status ('active' or 'inactive')

## Running Tests

The inventory system includes automated tests to verify functionality:

```bash
bun run inventory:test
```

This will run a series of tests against the API endpoints to ensure everything is working correctly.