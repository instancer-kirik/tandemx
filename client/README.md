# TandemX Client

## Environment Configuration

This project uses Turso for database operations, with optional Supabase integration. To set up your environment:

1. Copy `.env.example` to `.env` in the root directory
2. For Turso database (recommended), add your credentials:
   ```
   TURSO_DATABASE_URL=libsql://your-db-name.turso.io
   TURSO_AUTH_TOKEN=your_turso_auth_token_here
   TURSO_DB=true
   ```
   (If you don't provide these, a local SQLite database will be used automatically)

3. Optionally, add Supabase credentials:
   ```
   SUPABASE_URL=your_supabase_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```
4. **IMPORTANT:** Never commit your `.env` file to version control
5. The application will load these credentials at runtime

## Running the App

With Bun (recommended):
```bash
bun install
bun start
```

With npm:
```bash
npm install
npm start
```

## Database Schema

The application uses the following tables:

### Turso/SQLite Schema (Shop Application):
- users - User accounts
- products - Product catalog 
- categories - Product categories
- product_categories - Many-to-many relationship
- orders - Order header information
- order_items - Line items for each order

### Supabase Schema (Optional):
- Meetings
- Contacts
- Calendar events
- Blog posts
- Interest submissions
- Planet models

## Troubleshooting

If you encounter any connection issues:

1. For database errors:
   - If using Turso: Check that your credentials are correct in the `.env` file
   - If no credentials are provided: The app will use a local SQLite database
   - Turso-specific issues can be checked with `turso db show your-db-name`

2. For Supabase issues:
   - Check that your Supabase project is running and accessible
   - Verify your credentials in the `.env` file
   - If running without Supabase credentials, it will use fallback data

3. If the server won't start:
   - Delete any existing local database: `rm ../tandemx.db*`
   - Make sure there are no conflicting `.env` variables
   - Check that port 8000 is not already in use

## Security Notes

- Never hardcode database credentials in your JavaScript files
- Always use environment variables or a secure backend API to provide credentials
- For production deployments on Fly.io, set environment variables using:
  ```
  fly secrets set TURSO_DATABASE_URL=libsql://your-db-name.turso.io
  fly secrets set TURSO_AUTH_TOKEN=your_turso_auth_token_here
  fly secrets set TURSO_DB=true
  ```
- In development, the application will attempt to fetch credentials from the `/api/config` endpoint

## Shop API Endpoints

The Shop API (using Turso database) is available at these endpoints:

- **GET /api/shop/products** - List products
- **GET /api/shop/products/{id}** - Get a specific product
- **POST /api/shop/products** - Create a new product
- **GET /api/shop/orders/{id}** - Get a specific order
- **POST /api/shop/orders** - Create a new order
