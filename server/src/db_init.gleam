import gleam/io

pub fn init_db() -> Nil {
  io.println(
    "Wishlist feature will use Lemon Squeezy for payments and localStorage for wishlists",
  )
  io.println("No need for additional database setup")
  // Note: ElectricSQL is configured in docker-compose but not fully implemented
  // For now, we'll use localStorage for the wishlist items on the client side
}
// Database functionality is commented out since we're using localStorage instead
// Uncomment if you implement database support later

// fn create_tables(conn: db.Database) -> Nil {
//   // Create wishlist items table
//   io.println("Creating wishlist_items table...")
//   let _wishlist_result =
//     db.execute(
//       conn,
//       "CREATE TABLE IF NOT EXISTS wishlist_items (
//       id SERIAL PRIMARY KEY,
//       product_id VARCHAR(255) NOT NULL,
//       user_id VARCHAR(255) NOT NULL,
//       added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
//       UNIQUE(product_id, user_id)
//     )",
//       [],
//     )
//
//   // Create products table
//   io.println("Creating products table...")
//   let _products_result =
//     db.execute(
//       conn,
//       "CREATE TABLE IF NOT EXISTS products (
//       id VARCHAR(255) PRIMARY KEY,
//       name VARCHAR(255) NOT NULL,
//       description TEXT,
//       category VARCHAR(100) NOT NULL,
//       price DECIMAL(10, 2) NOT NULL,
//       sale_price DECIMAL(10, 2),
//       image_url VARCHAR(255),
//       badge VARCHAR(50),
//       created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
//     )",
//       [],
//     )
//
//   // Create product_specs table
//   io.println("Creating product_specs table...")
//   let _specs_result =
//     db.execute(
//       conn,
//       "CREATE TABLE IF NOT EXISTS product_specs (
//       id SERIAL PRIMARY KEY,
//       product_id VARCHAR(255) REFERENCES products(id) ON DELETE CASCADE,
//       spec_key VARCHAR(100) NOT NULL,
//       spec_value VARCHAR(255) NOT NULL,
//       UNIQUE(product_id, spec_key)
//     )",
//       [],
//     )
//
//   // Create cart_items table
//   io.println("Creating cart_items table...")
//   let _cart_result =
//     db.execute(
//       conn,
//       "CREATE TABLE IF NOT EXISTS cart_items (
//       id SERIAL PRIMARY KEY,
//       product_id VARCHAR(255) REFERENCES products(id) ON DELETE CASCADE,
//       user_id VARCHAR(255) NOT NULL,
//       quantity INT NOT NULL DEFAULT 1,
//       added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
//       UNIQUE(product_id, user_id)
//     )",
//       [],
//     )
//
//   // Enable Electric sync on tables
//   io.println("Enabling ElectricSQL sync on tables...")
//   let _enable_results = [
//     db.execute(conn, "ALTER TABLE wishlist_items ENABLE ELECTRIC", []),
//     db.execute(conn, "ALTER TABLE products ENABLE ELECTRIC", []),
//     db.execute(conn, "ALTER TABLE product_specs ENABLE ELECTRIC", []),
//     db.execute(conn, "ALTER TABLE cart_items ENABLE ELECTRIC", []),
//   ]
// }
//
// fn seed_products(conn: db.Database) -> Nil {
//   // Product data is now in the wishlist_api.gleam file
//   // This function is not needed as we're using mock data
//   io.println("Using mock products data from wishlist_api.gleam")
// }
