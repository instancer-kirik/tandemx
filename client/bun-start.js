#!/usr/bin/env bun
// bun-start.js - A standalone server for Tandemx with Variety Discount Shop Inventory API

import { serve } from "bun";
// Install @libsql/client with: bun add @libsql/client
import { createClient } from "@libsql/client";
import { Database } from "bun:sqlite";
import { join, extname, dirname } from "path";
import { existsSync, mkdirSync, writeFileSync, readFileSync } from "fs";
import { config } from "dotenv";
import { stat } from "fs/promises";

// Load environment variables from multiple locations
// First try the local .env file
config();

// Also try the parent directory .env file
try {
  config({ path: join(__dirname, '..', '.env') });
} catch (err) {
  // Ignore errors, we'll just use whatever was loaded
}

// Create colors for terminal output
const colors = {
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  reset: "\x1b[0m",
};

// Log with color
function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// Database setup
const PORT = parseInt(process.env.PORT || "8000");

// Initialize database connection
let db;
let isUsingTurso = false;

if (process.env.TURSO_DB === "true" && process.env.TURSO_DATABASE_URL) {
  // Use Turso
  log("green", "Connecting to Turso database...");
  db = createClient({
    url: process.env.TURSO_DATABASE_URL,
    authToken: process.env.TURSO_AUTH_TOKEN,
  });
  isUsingTurso = true;
  log("green", `Connected to Turso database: ${process.env.TURSO_DATABASE_URL.replace(/\?.*/, '')}`);
} else {
  // Fallback to local SQLite
  const DB_PATH = process.env.DB_PATH || join(__dirname, "..", "tandemx.db");
  const dbDir = DB_PATH.split("/").slice(0, -1).join("/");
  if (dbDir && !existsSync(dbDir)) {
    mkdirSync(dbDir, { recursive: true });
  }
  
  db = new Database(DB_PATH);
  isUsingTurso = false;
  log("yellow", `Using local SQLite database at: ${DB_PATH}`);
}

// Initialize database schema
async function initDatabase() {
  try {
    log("yellow", "Initializing database schema...");
    
    // Test connection first
    if (isUsingTurso) {
      log("yellow", "Testing Turso database connection...");
      try {
        await db.execute("SELECT 1");
        log("green", "Turso database connection successful");
      } catch (connErr) {
        log("red", `Turso connection failed: ${connErr.message}`);
        if (connErr.message.includes('401')) {
          log("red", "AUTH ERROR: Turso auth token is invalid or expired.");
          log("yellow", "To fix this, run: turso db tokens create tandemx --expiration none");
          log("yellow", "Then update TURSO_AUTH_TOKEN in your .env file");
        }
        throw connErr;
      }
    }
    
    const createProductsTable = `
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        base_price REAL NOT NULL,
        selling_price REAL,
        category TEXT,
        sku TEXT UNIQUE,
        barcode TEXT,
        stock_quantity INTEGER DEFAULT 0,
        location TEXT,
        supplier TEXT,
        min_stock_level INTEGER DEFAULT 5,
        sell_by_date TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        status TEXT DEFAULT 'active'
      )
    `;

    const createTransactionsTable = `
      CREATE TABLE IF NOT EXISTS inventory_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    `;

    // Create products table with additional fields for variety shop
    if (isUsingTurso) {
      await db.execute(createProductsTable);
      await db.execute(createTransactionsTable);
    } else {
      db.exec(createProductsTable);
      db.exec(createTransactionsTable);
    }

    log("green", "Database schema initialized successfully");

    // Check if we have any sample data, add if empty
    let count = 0;
    if (isUsingTurso) {
      const result = await db.execute("SELECT COUNT(*) as count FROM products");
      count = result.rows[0]?.count || 0;
    } else {
      const result = db.query("SELECT COUNT(*) as count FROM products").get();
      count = result.count;
    }
    
    if (count === 0) {
      if (isUsingTurso) {
        await db.execute(`
          INSERT INTO products (name, description, base_price, selling_price, category, sku, barcode, stock_quantity, location, supplier, sell_by_date, status) VALUES
          ('Dish Soap', 'Eco-friendly dish soap', 2.99, 1.99, 'Cleaning', 'CLN-001', '123456789', 50, 'Aisle 3', 'CleanCo', '2024-12-31', 'active'),
          ('Notebook', 'Spiral bound notebook', 1.49, 1.49, 'Stationery', 'STN-002', '234567890', 100, 'Aisle 1', 'PaperSupplies', NULL, 'active'),
          ('Picture Frame', '5x7 wooden frame', 4.99, 3.50, 'Home Decor', 'DEC-003', '345678901', 25, 'Aisle 5', 'DecorPlus', NULL, 'active'),
          ('Kitchen Towels', 'Pack of 3 kitchen towels', 3.99, 2.99, 'Household', 'HOU-004', '456789012', 40, 'Aisle 2', 'HomeGoods', '2024-06-30', 'active'),
          ('LED Flashlight', 'Compact LED flashlight', 5.99, 4.99, 'Hardware', 'HDW-005', '567890123', 30, 'Aisle 4', 'ToolTime', NULL, 'active')
        `);
      } else {
        db.exec(`
          INSERT INTO products (name, description, base_price, selling_price, category, sku, barcode, stock_quantity, location, supplier, sell_by_date, status) VALUES
          ('Dish Soap', 'Eco-friendly dish soap', 2.99, 1.99, 'Cleaning', 'CLN-001', '123456789', 50, 'Aisle 3', 'CleanCo', '2024-12-31', 'active'),
          ('Notebook', 'Spiral bound notebook', 1.49, 1.49, 'Stationery', 'STN-002', '234567890', 100, 'Aisle 1', 'PaperSupplies', NULL, 'active'),
          ('Picture Frame', '5x7 wooden frame', 4.99, 3.50, 'Home Decor', 'DEC-003', '345678901', 25, 'Aisle 5', 'DecorPlus', NULL, 'active'),
          ('Kitchen Towels', 'Pack of 3 kitchen towels', 3.99, 2.99, 'Household', 'HOU-004', '456789012', 40, 'Aisle 2', 'HomeGoods', '2024-06-30', 'active'),
          ('LED Flashlight', 'Compact LED flashlight', 5.99, 4.99, 'Hardware', 'HDW-005', '567890123', 30, 'Aisle 4', 'ToolTime', NULL, 'active')
        `);
      }
      log("yellow", "Added sample products to the database");
    }
  } catch (err) {
    log("red", `Database schema initialization error: ${err.message}`);
    throw err;
  }
}

// Database helper functions to handle both Turso and local SQLite
const dbHelpers = {
  async execute(sql, args = []) {
    try {
      if (isUsingTurso) {
        if (typeof sql === 'string') {
          return await db.execute({ sql, args });
        } else {
          return await db.execute(sql);
        }
      } else {
        // For local SQLite, use query for SELECT and exec for others
        if (sql.trim().toUpperCase().startsWith('SELECT')) {
          if (args.length > 0) {
            const result = db.query(sql).all(...args);
            return { rows: result };
          } else {
            const result = db.query(sql).all();
            return { rows: result };
          }
        } else if (sql.trim().toUpperCase().startsWith('INSERT')) {
          const stmt = db.query(sql);
          const result = stmt.run(...args);
          return { lastInsertRowid: result.lastInsertRowid, changes: result.changes };
        } else {
          const stmt = db.query(sql);
          const result = stmt.run(...args);
          return { changes: result.changes };
        }
      }
    } catch (err) {
      log("red", `Database execute error: ${err.message}`);
      if (err.message.includes('401')) {
        log("red", "AUTH ERROR: Database authentication failed");
        log("yellow", "Your Turso auth token may be expired. Generate a new one with:");
        log("yellow", "turso db tokens create tandemx --expiration none");
      }
      throw err;
    }
  },

  async get(sql, args = []) {
    if (isUsingTurso) {
      const result = await db.execute({ sql, args });
      return result.rows[0] || null;
    } else {
      const stmt = db.query(sql);
      return stmt.get(...args) || null;
    }
  }
};

// Initialize the database
try {
  await initDatabase();
} catch (err) {
  log("red", `Database initialization error: ${err.message}`);
}

// API handlers
const handlers = {
  // List products
  // Get all products
  async getProducts(req) {
    try {
      const url = new URL(req.url);
      const page = parseInt(url.searchParams.get("page") || "1");
      const limit = Math.min(parseInt(url.searchParams.get("limit") || "20"), 100);
      const category = url.searchParams.get("category");
      const lowStock = url.searchParams.get("low_stock");
      const offset = (page - 1) * limit;
      
      let query = "SELECT * FROM products";
      let params = [];
      let whereClause = "";
      
      // Apply filters
      if (category) {
        whereClause = "WHERE category = ?";
        params.push(category);
      }
      
      if (lowStock === 'true') {
        whereClause = whereClause ? `${whereClause} AND stock_quantity <= min_stock_level` : "WHERE stock_quantity <= min_stock_level";
      }
      
      query = `${query} ${whereClause} ORDER BY created_at DESC LIMIT ? OFFSET ?`;
      params.push(limit, offset);
      
      const productsResult = await dbHelpers.execute(query, params);
      const countQuery = `SELECT COUNT(*) as count FROM products ${whereClause}`;
      const countResult = await dbHelpers.execute(countQuery, whereClause ? params.slice(0, -2) : []);
      
      log("green", `Retrieved ${productsResult.rows.length} products`);

      return new Response(
        JSON.stringify({
          data: productsResult.rows,
          meta: {
            page,
            page_size: limit,
            total_count: countResult.rows[0]?.count || 0,
          }
        }),
        { 
          status: 200,
          headers: { "Content-Type": "application/json" }
        }
      );
    } catch (err) {
      log("red", `Error getting products: ${err.message}`);
      return new Response(
        JSON.stringify({ error: `Failed to get products: ${err.message}` }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json" }
        }
      );
    }
  },

  // Get a product by ID
  async getProduct(req, id) {
    try {
      const product = await dbHelpers.get("SELECT * FROM products WHERE id = ?", [id]);
      
      if (!product) {
        log("yellow", `Product not found: ${id}`);
        return new Response(
          JSON.stringify({ error: `Product not found: ${id}` }),
          { 
            status: 404,
            headers: { "Content-Type": "application/json" }
          }
        );
      }

      log("green", `Retrieved product: ${id}`);
      return new Response(
        JSON.stringify(product),
        { 
          status: 200,
          headers: { "Content-Type": "application/json" }
        }
      );
    } catch (err) {
      log("red", `Error getting product ${id}: ${err.message}`);
      return new Response(
        JSON.stringify({ error: `Failed to get product: ${err.message}` }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json" }
        }
      );
    }
  },

  // Create a product
  async createProduct(req) {
    try {
      const data = await req.json();
      log("yellow", `Creating product with data: ${JSON.stringify(data)}`);
      
      // Validate required fields
      if (!data.name || !data.price || !data.sku) {
        log("red", "Missing required fields for product creation");
        return new Response(
          JSON.stringify({ error: "Missing required fields: name, price (base_price), sku" }),
          { 
            status: 400,
            headers: { "Content-Type": "application/json" }
          }
        );
      }

      // Insert the product
      const insertResult = await dbHelpers.execute(`
        INSERT INTO products (
          name, description, base_price, selling_price, category, 
          sku, barcode, stock_quantity, location, supplier, 
          min_stock_level, sell_by_date, status
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        data.name,
        data.description || "",
        data.price, // This becomes base_price
        data.selling_price || data.price, // Default to base_price if not provided
        data.category || null,
        data.sku,
        data.barcode || null,
        data.stock_quantity || 0,
        data.location || null,
        data.supplier || null,
        data.min_stock_level || 5,
        data.sell_by_date || null,
        data.status || "active"
      ]);

      // Get the created product
      const product = await dbHelpers.get("SELECT * FROM products WHERE id = ?", [insertResult.lastInsertRowid]);
      log("green", `Product created successfully with ID: ${product.id}`);

      return new Response(
        JSON.stringify(product),
        { 
          status: 201,
          headers: { "Content-Type": "application/json" }
        }
      );
    } catch (err) {
      log("red", `Error creating product: ${err.message}`);
      return new Response(
        JSON.stringify({ error: `Failed to create product: ${err.message}` }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json" }
        }
      );
    }
  },

  // Update product
  async updateProduct(req, id) {
    try {
      const data = await req.json();
      log("yellow", `Updating product ${id} with data: ${JSON.stringify(data)}`);
      
      const product = await dbHelpers.get("SELECT * FROM products WHERE id = ?", [id]);
      
      if (!product) {
        log("yellow", `Product not found for update: ${id}`);
        return new Response(
          JSON.stringify({ error: `Product not found: ${id}` }),
          { 
            status: 404,
            headers: { "Content-Type": "application/json" }
          }
        );
      }
      
      // Build update query dynamically - updated field names
      const validFields = [
        'name', 'description', 'base_price', 'selling_price', 'category',
        'sku', 'barcode', 'stock_quantity', 'location', 'supplier',
        'min_stock_level', 'sell_by_date', 'status'
      ];
      
      const updates = [];
      const values = [];
      
      validFields.forEach(field => {
        // Handle legacy field names
        let fieldValue = data[field];
        if (field === 'base_price' && data.price !== undefined) {
          fieldValue = data.price;
        }
        if (field === 'selling_price' && data.discount_price !== undefined) {
          fieldValue = data.discount_price;
        }
        
        if (fieldValue !== undefined) {
          updates.push(`${field} = ?`);
          values.push(fieldValue);
        }
      });
      
      // Add updated_at
      updates.push("updated_at = CURRENT_TIMESTAMP");
      
      if (updates.length === 1) { // Only updated_at
        return new Response(
          JSON.stringify({ error: "No valid fields to update" }),
          { 
            status: 400,
            headers: { "Content-Type": "application/json" }
          }
        );
      }
      
      // Add ID as the last parameter
      values.push(id);
      
      await dbHelpers.execute(`UPDATE products SET ${updates.join(", ")} WHERE id = ?`, values);

      // Get updated product
      const updatedProduct = await dbHelpers.get("SELECT * FROM products WHERE id = ?", [id]);

      log("green", `Product ${id} updated successfully`);
      return new Response(
        JSON.stringify(updatedProduct),
        { 
          status: 200,
          headers: { "Content-Type": "application/json" }
        }
      );
    } catch (err) {
      log("red", `Error updating product ${id}: ${err.message}`);
      return new Response(
        JSON.stringify({ error: `Failed to update product: ${err.message}` }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json" }
        }
      );
    }
  },

  // Record inventory transaction
  async recordInventoryTransaction(req) {
    try {
      const data = await req.json();
      log("yellow", `Recording transaction: ${JSON.stringify(data)}`);
      
      // Validate required fields
      if (!data.product_id || data.quantity === undefined || !data.transaction_type) {
        log("red", "Missing required fields for transaction");
        return new Response(
          JSON.stringify({ error: "Missing required fields: product_id, quantity, transaction_type" }),
          { 
            status: 400,
            headers: { "Content-Type": "application/json" }
          }
        );
      }

      // Check if product exists
      const product = await dbHelpers.get("SELECT * FROM products WHERE id = ?", [data.product_id]);
      
      if (!product) {
        log("yellow", `Product not found for transaction: ${data.product_id}`);
        return new Response(
          JSON.stringify({ error: `Product not found: ${data.product_id}` }),
          { 
            status: 404,
            headers: { "Content-Type": "application/json" }
          }
        );
      }
      
      // Insert transaction record
      const transactionResult = await dbHelpers.execute(`
        INSERT INTO inventory_transactions (product_id, quantity, transaction_type, notes)
        VALUES (?, ?, ?, ?)
      `, [
        data.product_id,
        data.quantity,
        data.transaction_type,
        data.notes || null
      ]);
      
      // Update product stock quantity
      let newQuantity = product.stock_quantity;
      if (data.transaction_type === "restock") {
        newQuantity += data.quantity;
      } else if (data.transaction_type === "sale" || data.transaction_type === "adjustment") {
        newQuantity -= data.quantity;
      }
      
      // Ensure stock can't go below zero
      if (newQuantity < 0) newQuantity = 0;
      
      await dbHelpers.execute(`
        UPDATE products
        SET stock_quantity = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `, [newQuantity, data.product_id]);
      
      // Get the created transaction
      const transaction = await dbHelpers.get("SELECT * FROM inventory_transactions WHERE id = ?", [transactionResult.lastInsertRowid]);
      
      log("green", `Transaction recorded successfully for product ${data.product_id}. New stock: ${newQuantity}`);
      
      return new Response(
        JSON.stringify({
          transaction: transaction,
          new_stock_level: newQuantity
        }),
        {
            status: 201,
            headers: { "Content-Type": "application/json" }
          }
        );
    } catch (err) {
      log("red", `Error recording transaction: ${err.message}`);
      return new Response(
        JSON.stringify({ error: `Failed to record inventory transaction: ${err.message}` }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json" }
        }
      );
    }
  },

  // Get inventory transactions for a product
  async getProductTransactions(req, productId) {
    try {
      const url = new URL(req.url);
      const page = parseInt(url.searchParams.get("page") || "1");
      const limit = Math.min(parseInt(url.searchParams.get("limit") || "20"), 100);
      const offset = (page - 1) * limit;

      const transactionsResult = await dbHelpers.execute(`
        SELECT * FROM inventory_transactions 
        WHERE product_id = ? 
        ORDER BY created_at DESC 
        LIMIT ? OFFSET ?
      `, [productId, limit, offset]);

      const countResult = await dbHelpers.execute(`
        SELECT COUNT(*) as count FROM inventory_transactions 
        WHERE product_id = ?
      `, [productId]);

      log("green", `Retrieved ${transactionsResult.rows.length} transactions for product ${productId}`);

      return new Response(
        JSON.stringify({
          data: transactionsResult.rows,
          meta: {
            page,
            page_size: limit,
            total_count: countResult.rows[0]?.count || 0,
          }
        }),
        { 
          status: 200,
          headers: { "Content-Type": "application/json" }
        }
      );
    } catch (err) {
      log("red", `Error getting transactions for product ${productId}: ${err.message}`);
      return new Response(
        JSON.stringify({ error: `Failed to get transactions: ${err.message}` }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json" }
        }
      );
    }
  },

  // Get low stock products
  async getLowStockProducts(req) {
    try {
      const result = await dbHelpers.execute(`
        SELECT * FROM products 
        WHERE stock_quantity <= min_stock_level 
        AND status = 'active'
        ORDER BY (stock_quantity * 1.0 / min_stock_level) ASC
      `);

      log("green", `Retrieved ${result.rows.length} low stock products`);

      return new Response(
        JSON.stringify({
          data: result.rows,
          count: result.rows.length
        }),
        { 
          status: 200,
          headers: { "Content-Type": "application/json" }
        }
      );
    } catch (err) {
      log("red", `Error getting low stock products: ${err.message}`);
      return new Response(
        JSON.stringify({ error: `Failed to get low stock products: ${err.message}` }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json" }
        }
      );
    }
  },

  // Get product categories
  async getCategories() {
    try {
      const result = await dbHelpers.execute(`
        SELECT DISTINCT category FROM products 
        WHERE category IS NOT NULL 
        ORDER BY category
      `);

      const categories = result.rows.map(row => row.category);
      log("green", `Retrieved ${categories.length} categories`);

      return new Response(
        JSON.stringify(categories),
        { 
          status: 200,
          headers: { "Content-Type": "application/json" }
        }
      );
    } catch (err) {
      log("red", `Error getting categories: ${err.message}`);
      return new Response(
        JSON.stringify({ error: `Failed to get categories: ${err.message}` }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json" }
        }
      );
    }
  },

  // Handle 404
  notFound() {
    return new Response(
      JSON.stringify({ error: "Not found" }),
      { 
        status: 404,
        headers: { "Content-Type": "application/json" }
      }
    );
  },
  
  // Method not allowed
  methodNotAllowed() {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { 
        status: 405,
        headers: { "Content-Type": "application/json" }
      }
    );
  },
  
  // Serve static HTML
  serveHtml(content) {
    return new Response(content, { 
      status: 200,
      headers: { "Content-Type": "text/html; charset=utf-8" }
    });
  },
  
  // Serve JSON response
  serveJson(data) {
    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { 
        "Content-Type": "application/json", 
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
        "Cache-Control": "no-cache"
      }
    });
  }
};

// Create inventory API documentation
const inventoryDocs = `
<!DOCTYPE html>
<html>
<head>
  <title>Variety Discount Shop Inventory API</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 900px; margin: 0 auto; padding: 2rem; line-height: 1.6; }
    h1 { color: #333; }
    pre { background: #f4f4f4; padding: 1rem; border-radius: 4px; overflow-x: auto; }
    .endpoint { margin-bottom: 2rem; }
    .method { font-weight: bold; color: #e36209; }
    .get { color: #0D904F; }
    .post { color: #0D47A1; }
    .put { color: #FFA000; }
    .test-area { margin-top: 3rem; padding: 1.5rem; border: 1px solid #ddd; border-radius: 8px; background: #f9f9f9; }
    .test-area h2 { color: #333; margin-top: 0; }
    .test-area button { background: #0D47A1; color: white; border: none; padding: 0.5rem 1rem; border-radius: 4px; cursor: pointer; margin-right: 0.5rem; }
    .test-area button:hover { background: #0D66CC; }
    .result { margin-top: 1rem; padding: 1rem; background: #f0f0f0; border-radius: 4px; white-space: pre-wrap; display: none; }
    .log { margin-top: 1rem; padding: 1rem; background: #f0f0f0; border-radius: 4px; height: 200px; overflow-y: auto; font-family: monospace; }
    table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
    th, td { padding: 0.5rem; text-align: left; border: 1px solid #ddd; }
    th { background: #f0f0f0; }
    .product-form { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-top: 1rem; }
    .product-form label { display: block; margin-bottom: 0.5rem; }
    .product-form input, .product-form select { width: 100%; padding: 0.5rem; box-sizing: border-box; }
    .product-form button { grid-column: span 2; }
  </style>
</head>
<body>
  <h1>Variety Discount Shop Inventory API</h1>
  <p>Welcome to the Variety Discount Shop Inventory API. Below are the available endpoints:</p>
  
  <div class="endpoint">
    <h2><span class="method get">GET</span> /inventory/api/shop/products</h2>
    <p>List all products. Supports pagination and filtering.</p>
    <p><strong>Query Parameters:</strong></p>
    <ul>
      <li><code>page</code> - Page number (default: 1)</li>
      <li><code>limit</code> - Items per page (default: 20, max: 100)</li>
      <li><code>category</code> - Filter by category</li>
      <li><code>low_stock</code> - Set to 'true' to show only low stock items</li>
    </ul>
    <pre>curl http://localhost:${PORT}/inventory/api/shop/products?page=1&limit=10&category=Cleaning</pre>
  </div>
  
  <div class="endpoint">
    <h2><span class="method get">GET</span> /inventory/api/shop/products/{id}</h2>
    <p>Get a specific product by ID.</p>
    <pre>curl http://localhost:${PORT}/inventory/api/shop/products/1</pre>
  </div>
  
  <div class="endpoint">
    <h2><span class="method post">POST</span> /inventory/api/shop/products</h2>
    <p>Create a new product.</p>
    <pre>curl -X POST http://localhost:${PORT}/inventory/api/shop/products \
  -H "Content-Type: application/json" \
  -d '{
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
    "min_stock_level": 10
  }'</pre>
  </div>

  <div class="endpoint">
    <h2><span class="method put">PUT</span> /inventory/api/shop/products/{id}</h2>
    <p>Update an existing product.</p>
    <pre>curl -X PUT http://localhost:${PORT}/inventory/api/shop/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "price": 3.99,
    "discount_price": 2.49,
    "stock_quantity": 75
  }'</pre>
  </div>
  
  <div class="endpoint">
    <h2><span class="method post">POST</span> /inventory/api/shop/inventory/transactions</h2>
    <p>Record an inventory transaction (restock, sale, adjustment).</p>
    <pre>curl -X POST http://localhost:${PORT}/inventory/api/shop/inventory/transactions \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 1,
    "quantity": 10,
    "transaction_type": "restock",
    "notes": "Restocked from supplier delivery"
  }'</pre>
  </div>
  
  <div class="endpoint">
    <h2><span class="method get">GET</span> /inventory/api/shop/products/{id}/transactions</h2>
    <p>Get inventory transaction history for a product.</p>
    <pre>curl http://localhost:${PORT}/inventory/api/shop/products/1/transactions</pre>
  </div>
  
  <div class="endpoint">
    <h2><span class="method get">GET</span> /inventory/api/shop/inventory/low-stock</h2>
    <p>Get all products that are below their minimum stock level.</p>
    <pre>curl http://localhost:${PORT}/inventory/api/shop/inventory/low-stock</pre>
  </div>
  
  <div class="endpoint">
    <h2><span class="method get">GET</span> /inventory/api/shop/categories</h2>
    <p>Get all product categories.</p>
    <pre>curl http://localhost:${PORT}/inventory/api/shop/categories</pre>
  </div>
  
  <div class="test-area">
    <h2>Test Inventory API</h2>
    
    <h3>Products</h3>
    <button id="load-products">Load Products</button>
    <button id="load-low-stock">Load Low Stock</button>
    <button id="load-categories">Load Categories</button>
    
    <table id="products-table" style="display:none;">
      <thead>
        <tr>
          <th>ID</th>
          <th>Name</th>
          <th>Price</th>
          <th>Stock</th>
          <th>Category</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody id="products-body">
      </tbody>
    </table>
    
    <div class="log" id="api-log"></div>
    
    <h3>Add New Product</h3>
    <form id="product-form" class="product-form">
      <div>
        <label for="name">Name</label>
        <input type="text" id="name" required>
      </div>
      <div>
        <label for="description">Description</label>
        <input type="text" id="description">
      </div>
      <div>
        <label for="price">Base Price</label>
        <input type="number" id="price" step="0.01" required>
      </div>
      <div>
        <label for="selling_price">Current Selling Price</label>
        <input type="number" id="selling_price" step="0.01">
      </div>
      <div>
        <label for="sell_by_date">Sell By Date (optional)</label>
        <input type="date" id="sell_by_date">
      </div>
      <div>
        <label for="category">Category</label>
        <input type="text" id="category">
      </div>
      <div>
        <label for="sku">SKU</label>
        <input type="text" id="sku" required>
      </div>
      <div>
        <label for="barcode">Barcode</label>
        <input type="text" id="barcode">
      </div>
      <div>
        <label for="stock_quantity">Stock Quantity</label>
        <input type="number" id="stock_quantity" value="0">
      </div>
      <div>
        <label for="location">Location</label>
        <input type="text" id="location">
      </div>
      <div>
        <label for="supplier">Supplier</label>
        <input type="text" id="supplier">
      </div>
      <div>
        <label for="min_stock_level">Min Stock Level</label>
        <input type="number" id="min_stock_level" value="5">
      </div>
      <div>
        <label for="status">Status</label>
        <select id="status">
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>
      
      <button type="submit">Add Product</button>
    </form>
    
    <h3>Record Transaction</h3>
    <form id="transaction-form" class="product-form">
      <div>
        <label for="product_id">Product ID</label>
        <input type="number" id="product_id" required>
      </div>
      <div>
        <label for="quantity">Quantity</label>
        <input type="number" id="quantity" required>
      </div>
      <div>
        <label for="transaction_type">Transaction Type</label>
        <select id="transaction_type">
          <option value="restock">Restock</option>
          <option value="sale">Sale</option>
          <option value="adjustment">Adjustment</option>
        </select>
      </div>
      <div>
        <label for="notes">Notes</label>
        <input type="text" id="notes">
      </div>
      
      <button type="submit">Record Transaction</button>
    </form>
  </div>
  
  <script>
    // Helper function to log API responses
    function logToConsole(message) {
      const log = document.getElementById('api-log');
      const entry = document.createElement('div');
      entry.textContent = message;
      log.appendChild(entry);
      log.scrollTop = log.scrollHeight;
    }
    
    // Load products
    document.getElementById('load-products').addEventListener('click', async () => {
      try {
        logToConsole('Loading products...');
        const response = await fetch('/inventory/api/shop/products');
        const data = await response.json();
        
        const table = document.getElementById('products-table');
        const tbody = document.getElementById('products-body');
        
        // Clear existing rows
        tbody.innerHTML = '';
        
        // Add product rows
        data.data.forEach(product => {
          const row = document.createElement('tr');
          
          row.innerHTML = \`
            <td>\${product.id}</td>
            <td>\${product.name}</td>
            <td>$\${(product.selling_price || product.base_price).toFixed(2)}</td>
            <td>\${product.stock_quantity}</td>
            <td>\${product.category || 'N/A'}</td>
            <td>
              <button onclick="viewProduct(\${product.id})">View</button>
            </td>
          \`;
          
          tbody.appendChild(row);
        });
        
        table.style.display = 'table';
        logToConsole(\`Loaded \${data.data.length} products\`);
      } catch (error) {
        logToConsole(\`Error: \${error.message}\`);
      }
    });
    
    // Load low stock products
    document.getElementById('load-low-stock').addEventListener('click', async () => {
      try {
        logToConsole('Loading low stock products...');
        const response = await fetch('/inventory/api/shop/inventory/low-stock');
        const data = await response.json();
        
        const table = document.getElementById('products-table');
        const tbody = document.getElementById('products-body');
        
        // Clear existing rows
        tbody.innerHTML = '';
        
        // Add product rows
        data.data.forEach(product => {
          const row = document.createElement('tr');
          
          row.innerHTML = \`
            <td>\${product.id}</td>
            <td>\${product.name}</td>
            <td>$\${(product.selling_price || product.base_price).toFixed(2)}</td>
            <td>\${product.stock_quantity}</td>
            <td>\${product.category || 'N/A'}</td>
            <td>
              <button onclick="viewProduct(\${product.id})">View</button>
            </td>
          \`;
          
          tbody.appendChild(row);
        });
        
        table.style.display = 'table';
        logToConsole(\`Loaded \${data.data.length} low stock products\`);
      } catch (error) {
        logToConsole(\`Error: \${error.message}\`);
      }
    });
    
    // Load categories
    document.getElementById('load-categories').addEventListener('click', async () => {
      try {
        logToConsole('Loading categories...');
        const response = await fetch('/inventory/api/shop/categories');
        const categories = await response.json();
        
        logToConsole(\`Categories: \${categories.join(', ')}\`);
      } catch (error) {
        logToConsole(\`Error: \${error.message}\`);
      }
    });
    
    // Add product form handler
    document.getElementById('product-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const formData = {
        name: document.getElementById('name').value,
        description: document.getElementById('description').value,
        price: parseFloat(document.getElementById('price').value), // This becomes base_price
        selling_price: document.getElementById('selling_price').value ? 
                       parseFloat(document.getElementById('selling_price').value) : null,
        category: document.getElementById('category').value,
        sku: document.getElementById('sku').value,
        barcode: document.getElementById('barcode').value,
        stock_quantity: parseInt(document.getElementById('stock_quantity').value),
        location: document.getElementById('location').value,
        supplier: document.getElementById('supplier').value,
        min_stock_level: parseInt(document.getElementById('min_stock_level').value),
        sell_by_date: document.getElementById('sell_by_date').value || null,
        status: document.getElementById('status').value
      };
      
      try {
        logToConsole(\`Adding product: \${formData.name}...\`);
        const response = await fetch('/inventory/api/shop/products', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(formData)
        });
        
        const result = await response.json();
        
        if (response.ok) {
          logToConsole(\`Product added successfully. ID: \${result.id}\`);
          document.getElementById('product-form').reset();
        } else {
          logToConsole(\`Error: \${result.error || 'Unknown error'}\`);
        }
      } catch (error) {
        logToConsole(\`Error: \${error.message}\`);
      }
    });
    
    // Transaction form handler
    document.getElementById('transaction-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const formData = {
        product_id: parseInt(document.getElementById('product_id').value),
        quantity: parseInt(document.getElementById('quantity').value),
        transaction_type: document.getElementById('transaction_type').value,
        notes: document.getElementById('notes').value
      };
      
      try {
        logToConsole(\`Recording \${formData.transaction_type} transaction for product #\${formData.product_id}...\`);
        const response = await fetch('/inventory/api/shop/inventory/transactions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(formData)
        });
        
        const result = await response.json();
        
        if (response.ok) {
          logToConsole(\`Transaction recorded successfully. New stock level: \${result.new_stock_level}\`);
          document.getElementById('transaction-form').reset();
        } else {
          logToConsole(\`Error: \${result.error || 'Unknown error'}\`);
        }
      } catch (error) {
        logToConsole(\`Error: \${error.message}\`);
      }
    });
    
    // View product details
    window.viewProduct = async (id) => {
      try {
        logToConsole(\`Loading details for product #\${id}...\`);
        const response = await fetch(\`/inventory/api/shop/products/\${id}\`);
        const product = await response.json();
        
        logToConsole(JSON.stringify(product, null, 2));
      } catch (error) {
        logToConsole(\`Error: \${error.message}\`);
      }
    };
  </script>
</body>
</html>
`;

// Read the existing index.html file for the main TandemX application
let homepage;
try {
  homepage = readFileSync(join(__dirname, "index.html"), "utf8");
} catch (err) {
  // Fallback homepage if index.html is not found
  homepage = `
<!DOCTYPE html>
<html>
<head>
  <title>TandemX</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 800px; margin: 0 auto; padding: 2rem; line-height: 1.6; }
    h1 { color: #333; }
    a { color: #0066cc; text-decoration: none; }
    a:hover { text-decoration: underline; }
    .card { background: #f4f4f4; padding: 1rem; border-radius: 4px; margin-bottom: 1rem; }
  </style>
</head>
<body>
  <h1>Welcome to TandemX</h1>
  <p>This is the main TandemX server. The original application functionality is preserved.</p>
  
  <div class="card">
    <h2><a href="/inventory">Variety Discount Shop Inventory System</a></h2>
    <p>Access the inventory management system for the variety discount shop.</p>
  </div>
</body>
</html>
  `;
}

// Start the server
serve({
  port: PORT,
  async fetch(req) {
    const url = new URL(req.url);
    let path = url.pathname.split("/").filter(Boolean);
    
    // Special case for /api/config which sometimes gets processed as a single path component
    if (path.length === 1 && path[0].startsWith('api/config')) {
      path = ['api', 'config'];
    }
    
    // Log request
    log("yellow", `${req.method} ${url.pathname}`);
    
    try {
      // Inventory API Routes
      if (path[0] === "inventory") {
        // Serve inventory documentation at /inventory
        if (path.length === 1) {
          return handlers.serveHtml(inventoryDocs);
        }
        
        // Handle inventory API
        if (path.length > 1 && path[1] === "api" && path[2] === "shop") {
          // Products endpoints
          if (path[3] === "products") {
            if (path.length === 4) {
              if (req.method === "GET") return await handlers.getProducts(req);
              if (req.method === "POST") return await handlers.createProduct(req);
              return handlers.methodNotAllowed();
            } else if (path.length === 5) {
              if (req.method === "GET") return await handlers.getProduct(req, path[4]);
              if (req.method === "PUT") return await handlers.updateProduct(req, path[4]);
              return handlers.methodNotAllowed();
            } else if (path.length === 6 && path[5] === "transactions") {
              if (req.method === "GET") return await handlers.getProductTransactions(req, path[4]);
              return handlers.methodNotAllowed();
            }
          }
          
          // Inventory endpoints
          if (path[3] === "inventory") {
            if (path.length === 5) {
              if (path[4] === "low-stock" && req.method === "GET") {
                return await handlers.getLowStockProducts(req);
              }
              if (path[4] === "transactions" && req.method === "POST") {
                return await handlers.recordInventoryTransaction(req);
              }
            }
          }
          
          // Categories endpoint
          if (path[3] === "categories" && path.length === 4 && req.method === "GET") {
            return await handlers.getCategories();
          }
          
          // Return 404 for unknown API routes
          return handlers.notFound();
        }
      }
      
      // Legacy API support (for any existing integrations)
      if (path[0] === "api" && path[1] === "shop") {
        log("yellow", `Legacy API call: ${req.method} ${url.pathname} - Consider updating to /inventory/api/shop/`);
        // Products endpoints
        if (path[2] === "products") {
          if (path.length === 3) {
            if (req.method === "GET") return await handlers.getProducts(req);
            if (req.method === "POST") return await handlers.createProduct(req);
            return handlers.methodNotAllowed();
          } else if (path.length === 4) {
            if (req.method === "GET") return await handlers.getProduct(req, path[3]);
            if (req.method === "PUT") return await handlers.updateProduct(req, path[3]);
            return handlers.methodNotAllowed();
          } else if (path.length === 5 && path[4] === "transactions") {
            if (req.method === "GET") return await handlers.getProductTransactions(req, path[3]);
            return handlers.methodNotAllowed();
          }
        }
        
        // Other legacy endpoints support
        if (path[2] === "inventory") {
          if (path.length === 4) {
            if (path[3] === "low-stock" && req.method === "GET") {
              return await handlers.getLowStockProducts(req);
            }
            if (path[3] === "transactions" && req.method === "POST") {
              return await handlers.recordInventoryTransaction(req);
            }
          }
        }
        
        if (path[2] === "categories" && path.length === 3 && req.method === "GET") {
          return await handlers.getCategories();
        }
        
        return handlers.notFound();
      }
      
      // Home page and static files for main TandemX application
      if (path.length === 0) {
        return handlers.serveHtml(homepage);
      } else {
        // Handle API config endpoint for Supabase credentials
        if ((path[0] === 'api' && path[1] === 'config') || path[0] === 'api/config') {
          // Return configuration from environment variables
          return handlers.serveJson({
            supabase: {
              url: process.env.SUPABASE_URL || 'https://demo.supabase.co',
              key: process.env.SUPABASE_KEY || 'public-anon-key',
              // Don't include private keys in client-side config
            },
            version: '1.0.0',
            env: process.env.NODE_ENV || 'development'
          });
        }
      
        // CSS file check from index.html references
          if (path[0] === 'css' && path.length > 1) {
            // Check possible locations for CSS files
            const possiblePaths = [
              join(__dirname, 'css', path[1]),              // /css/file.css
              join(__dirname, 'public', path[1]),           // /public/file.css
              join(__dirname, path[0], path[1]),            // /css/file.css
              join(__dirname, '..', 'public', path[1]),     // ../public/file.css
              join(__dirname, '..', 'client', 'public', path[1]) // ../client/public/file.css
            ];
          
          log("yellow", `Looking for CSS file: ${path[1]}`);
          
          for (const cssPath of possiblePaths) {
            log("yellow", `  Checking: ${cssPath}`);
            if (existsSync(cssPath)) {
              log("green", `  Found CSS file at: ${cssPath}`);
              const content = readFileSync(cssPath);
              return new Response(content, { 
                status: 200,
                headers: { "Content-Type": "text/css" }
              });
            }
          }
          
          log("red", `  CSS file not found: ${path[1]} - searched ${possiblePaths.length} locations`);
        }
        
        // Check assets in public directory
        if (path[0] === 'assets' && path.length > 1) {
          const assetPath = join(__dirname, 'assets', path[1]);
          if (existsSync(assetPath)) {
            const content = readFileSync(assetPath);
            const ext = extname(path[1]).slice(1).toLowerCase();
            const contentTypes = {
              'svg': 'image/svg+xml',
              'png': 'image/png',
              'jpg': 'image/jpeg',
              'jpeg': 'image/jpeg',
              'gif': 'image/gif',
              'ico': 'image/x-icon'
            };
            const contentType = contentTypes[ext] || 'application/octet-stream';
            
            return new Response(content, { 
              status: 200,
              headers: { "Content-Type": contentType }
            });
          }
        }
        
        // Check for files in the public directory
        if (path.length === 1) {
          const publicPath = join(__dirname, 'public', path[0]);
          if (existsSync(publicPath)) {
            const content = readFileSync(publicPath);
            const ext = extname(path[0]).slice(1).toLowerCase();
            
            const contentTypes = {
              'html': 'text/html',
              'css': 'text/css',
              'js': 'application/javascript',
              'json': 'application/json',
              'txt': 'text/plain'
            };
            
            const contentType = contentTypes[ext] || 'application/octet-stream';
            
            return new Response(content, { 
              status: 200,
              headers: { "Content-Type": contentType }
            });
          }
        }
        
        // Try to serve static files from main directory
        const staticPath = join(__dirname, ...path);
        try {
          const stats = await stat(staticPath);
          if (stats.isFile()) {
            const content = readFileSync(staticPath);
            
            // Determine content type based on file extension
            const ext = extname(path[path.length - 1]).slice(1).toLowerCase();
            let contentType = 'application/octet-stream';
            
            const contentTypes = {
              'html': 'text/html',
              'css': 'text/css',
              'js': 'application/javascript',
              'mjs': 'application/javascript',
              'json': 'application/json',
              'png': 'image/png',
              'jpg': 'image/jpeg',
              'jpeg': 'image/jpeg',
              'gif': 'image/gif',
              'svg': 'image/svg+xml',
              'ico': 'image/x-icon',
              'txt': 'text/plain'
            };
            
            if (contentTypes[ext]) {
              contentType = contentTypes[ext];
            }
            
            return new Response(content, { 
              status: 200,
              headers: { "Content-Type": contentType }
            });
          }
        } catch (err) {
          // File not found or error reading file, continue to 404
          log("yellow", `  Static file not found or error: ${staticPath} - ${err.message}`);
        }
        
        // Check for build directory files (specially for the Gleam frontend)
        if (path[0] === 'build' && path.length > 1) {
          const buildPath = join(__dirname, ...path);
          try {
            const stats = await stat(buildPath);
            if (stats.isFile()) {
              const content = readFileSync(buildPath);
              
              const ext = extname(buildPath).slice(1).toLowerCase();
              const contentTypes = {
                'mjs': 'application/javascript',
                'js': 'application/javascript',
                'css': 'text/css',
                'json': 'application/json',
                'wasm': 'application/wasm',
              };
              
              const contentType = contentTypes[ext] || 'application/octet-stream';
              
              return new Response(content, { 
                status: 200,
                headers: { "Content-Type": contentType }
              });
            }
          } catch (err) {
            // File not found, continue to 404
            log("yellow", `  Build file not found: ${buildPath} - ${err.message}`);
          }
        }
      }
      
      // 404 for unknown routes
      log("red", `404 - Route not found: ${req.method} ${url.pathname}`);
      return handlers.notFound();
    } catch (err) {
      // Handle unexpected errors
      log("red", `Error handling request: ${err.message}`);
      console.error(err);
      return new Response(
        JSON.stringify({ error: "Internal server error", message: err.message, stack: err.stack }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json" }
        }
      );
    }
  },
});

// Log which environment variables we successfully loaded
if (process.env.SUPABASE_URL) {
  log("green", `Loaded Supabase URL: ${process.env.SUPABASE_URL}`);
} else {
  log("yellow", "No Supabase URL found in environment variables");
}

if (process.env.SUPABASE_KEY) {
  log("green", "Loaded Supabase key from environment variables");
} else {
  log("yellow", "No Supabase key found in environment variables");
}

// Set fallback values for missing environment variables
process.env.SUPABASE_URL = process.env.SUPABASE_URL || "https://demo.supabase.co";
process.env.SUPABASE_KEY = process.env.SUPABASE_KEY || "public-anon-key";

// Log what we're using
log("yellow", `Using Supabase URL: ${process.env.SUPABASE_URL}`);
log("yellow", `Using Supabase key: ${process.env.SUPABASE_KEY ? "configured key" : "default key"}`);

log("green", `TandemX server with Variety Shop Inventory API is running on http://localhost:${PORT}`);
log("green", `Inventory API available at: http://localhost:${PORT}/inventory`);
log("green", `Main TandemX application available at: http://localhost:${PORT}/`);
log("yellow", `To access only the inventory system, use: http://localhost:${PORT}/inventory`);

// Log server startup completion
log("green", "Server initialization complete");