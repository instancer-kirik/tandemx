# Using Turso Database with TandemX

This guide explains how to set up and use the Turso database with TandemX, including specific instructions for Bun users.

## Quick Start with Bun

```bash
# Install dependencies
bun install

# Run with the dedicated Bun-specific Turso script (RECOMMENDED)
bun run bun:turso

# Alternative methods:
# Start the app with Turso database
TURSO_DB=true bun start

# Or use the dedicated Turso script
bun run start:turso
```

## Setup Steps

1. **Create a Turso Account**:
   - Sign up at [Turso](https://turso.tech/)
   - Install the Turso CLI: `curl -sSfL https://get.tur.so/install.sh | bash`
   - Login: `turso auth login`

2. **Create a Turso Database**:
   ```bash
   turso db create tandemx-shop
   turso db tokens create tandemx-shop
   ```

3. **Configure Environment Variables**:
   - Copy the .env.turso file to .env:
     ```bash
     cp .env.turso .env
     ```
   - Update with your Turso credentials:
     ```
     TURSO_DATABASE_URL=libsql://your-db-name.turso.io
     TURSO_AUTH_TOKEN=your_turso_auth_token_here
     TURSO_DB_NAME=your_db_name_here
     TURSO_DB=true
     ```

4. **Start the Application**:
   ```bash
   # Using bun with the dedicated Turso script (RECOMMENDED METHOD)
   bun run bun:turso
   
   # Alternative methods:
   # Standard start (will use Turso if .env is configured)
   bun start
   
   # Explicitly enable Turso
   TURSO_DB=true bun start
   
   # Or use the dedicated script
   bun run start:turso
   ```

## Using Local SQLite for Development

If you don't provide Turso credentials, the system will automatically use a local SQLite database:

```bash
# This will use a local SQLite database without requiring credentials
bun run bun:turso
```

The Bun-specific script (`bun:turso`) automatically:
- Sets up a local SQLite database if no credentials are provided
- Creates the necessary flag files to bypass ElectricSQL
- Ensures proper environment configuration

The local database will be created at `tandemx.db` in your project root.

## API Endpoints

The shop API is available at the following endpoints:

- **GET /api/shop/products**: List products
- **GET /api/shop/products/{id}**: Get a specific product
- **POST /api/shop/products**: Create a new product
- **GET /api/shop/orders/{id}**: Get a specific order
- **POST /api/shop/orders**: Create a new order

## Testing the API

Test creating a product:

```bash
curl -X POST http://localhost:8000/api/shop/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "description": "A test product",
    "price": 19.99,
    "sku": "TEST-123",
    "stock_quantity": 100
  }'
```

## Troubleshooting

- **Database Connection Issues**: Check if your .env file is properly set up with the correct Turso credentials.
- **Missing Tables**: Ensure the database initialization ran successfully. You can manually run it with:
  ```bash
  cd server
  gleam run -m turso_db_setup
  ```
- **API Errors**: Make sure you started the application with Turso enabled. The most reliable way is using `bun run bun:turso`.
- **ElectricSQL Errors**: If you see errors related to ElectricSQL, make sure you're using the `bun run bun:turso` command which completely bypasses ElectricSQL.

## Python Client

A Python client is available at `clients/python/shop_client.py` for interacting with the shop API:

```python
from shop_client import ShopClient

client = ShopClient("http://localhost:8000")
product = client.create_product(
    name="Test Product",
    description="A test product",
    price=19.99,
    sku="TEST-123",
    stock_quantity=100
)
```

For direct database access, use `clients/python/direct_turso_client.py`.