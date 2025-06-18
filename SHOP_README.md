# Tandemx Shop - Turso libSQL Database Integration

## Overview

Tandemx Shop is a modern point-of-sale (POS) and e-commerce backend that uses Turso libSQL as its database. This solution provides a fast, reliable, and scalable database that works across multiple platforms and languages, including Gleam (targeting both JavaScript and Erlang) and Python.

## Why Turso?

[Turso](https://turso.tech/) is a distributed database built on libSQL (a SQLite fork) that offers:

- **Edge deployment**: Data close to your users
- **Serverless operations**: No database management overhead
- **libSQL compatibility**: Familiar SQL syntax with additional features
- **Developer-friendly**: Simple setup and operation
- **Multi-language support**: Connect from Python, JavaScript, Go, Rust, and many more

## Setup Instructions

### 1. Create a Turso Account and Database

1. Sign up at [Turso](https://turso.tech/)
2. Install the Turso CLI:
   ```bash
   curl -sSfL https://get.tur.so/install.sh | bash
   ```
3. Log in to your Turso account:
   ```bash
   turso auth login
   ```
4. Create a new database:
   ```bash
   turso db create tandemx-shop
   ```
5. Get your database URL and auth token:
   ```bash
   turso db show tandemx-shop --url
   turso db tokens create tandemx-shop
   ```

### 2. Configure Environment Variables

Copy the `.env.example` file to `.env` and update the Turso configuration:

```
TURSO_DATABASE_URL=libsql://your-db-name.turso.io
TURSO_AUTH_TOKEN=your_turso_auth_token_here
TURSO_DB_NAME=your_db_name_here
```

### 3. Initialize the Database Schema

Run the server with the `--setup-db` flag to initialize the database schema:

```bash
cd tandemx/server
gleam run -m dev_server -- --setup-db
```

## API Endpoints

The shop API is available at the following endpoints:

### Products

- **GET /api/shop/products**: List products (supports pagination with `page` and `limit` query parameters)
- **GET /api/shop/products/{id}**: Get a specific product
- **POST /api/shop/products**: Create a new product

### Orders

- **GET /api/shop/orders**: List orders
- **GET /api/shop/orders/{id}**: Get a specific order with items
- **POST /api/shop/orders**: Create a new order

## Client Libraries

### Python Client

A Python client is available at `clients/python/shop_client.py`. Here's a simple example:

```python
from shop_client import ShopClient

# Initialize client
client = ShopClient("http://localhost:8000")

# Create a product
product = client.create_product(
    name="Test Product",
    description="A test product",
    price=19.99,
    sku="TEST-123",
    stock_quantity=100
)

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
```

### Gleam Client

The Gleam client is built directly into the application, but you can also use the API from any Gleam application:

```gleam
import turso_db
import shop
import glibsql

// Get all products
fn get_all_products() {
  let conn = turso_db.get_connection()
  let products = shop.get_all_products(conn, 1, 20)
  turso_db.close_connection(conn)
  products
}

// Create a product using glibsql directly
fn create_product() {
  let config = glibsql.Config(url: "libsql://your-db-name.turso.io")
  let conn = glibsql.connect(config)
  
  case conn {
    Ok(db) -> {
      let result = glibsql.query(
        db,
        "INSERT INTO products (name, price, sku) VALUES (?, ?, ?)",
        [dynamic.from("Product Name"), dynamic.from(19.99), dynamic.from("SKU123")]
      )
      glibsql.close(db)
      result
    }
    Error(err) -> Error(err)
  }
}
```

## Database Schema

The shop uses the following tables in Turso:

- **users**: Customer accounts
- **products**: Product catalog
- **categories**: Product categories
- **product_categories**: Many-to-many relationship between products and categories
- **orders**: Order header information
- **order_items**: Line items for each order

All tables are created with optimized indexes for Turso's distributed architecture.

## Local Development

For local development, the system automatically connects to a local libSQL database file if no Turso credentials are provided.

To start the development server:

```bash
cd tandemx/server
gleam run -m dev_server
```

## Deployment on Fly.io

To deploy on Fly.io:

1. Update your `fly.toml` to include the database setup:

```toml
[deploy]
  release_command = "gleam run -m turso_db_setup"
```

2. Set your environment variables:

```bash
fly secrets set TURSO_DATABASE_URL=libsql://your-db-name.turso.io
fly secrets set TURSO_AUTH_TOKEN=your_turso_auth_token_here
fly secrets set TURSO_DB_NAME=your_db_name_here
```

3. Deploy:

```bash
fly deploy
```

## Cross-language Integration

This shop backend is designed to be accessed from multiple languages:

- **Gleam**: Built-in modules for direct database access
- **JavaScript**: Via the Gleam JS target or the HTTP API
- **Python**: Using the included Python client
- **Any language**: Via the RESTful HTTP API