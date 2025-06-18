# TandemX with Bun - Quick Start Guide

## Using TandemX with Bun and Turso

The easiest way to run TandemX with Bun and Turso database:

```bash
# Install dependencies
bun install

# Start with Turso (default mode)
bun start
```

This will:
- Use a local SQLite database if no Turso credentials are provided
- Automatically bypass ElectricSQL
- Start the server with Turso database support

## Configuration Options

### Environment Setup

Create a `.env` file with your Turso credentials (optional):

```
TURSO_DATABASE_URL=libsql://your-db-name.turso.io
TURSO_AUTH_TOKEN=your_turso_auth_token_here
TURSO_DB=true
SERVER_PORT=8000
```

If you don't provide credentials, a local SQLite database will be used automatically.

### Available Commands

| Command | Description |
|---------|-------------|
| `bun start` | **RECOMMENDED**: Start with Turso (default) |
| `bun run bun:turso` | Alternative way to start with Turso |
| `bun run start:electric` | Start with ElectricSQL (not recommended) |
| `bun run start:no-db` | Start without any database |

## Troubleshooting

If you encounter issues:

1. Delete any existing database files: `rm tandemx.db*`
2. Make sure there are no conflicting `.env` variables
3. Try using `bun run bun:turso` as an alternative
4. Check that port 8000 is not already in use

## Testing the Shop API

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

## Further Information

For more detailed information, see the `TURSO_README.md` file.