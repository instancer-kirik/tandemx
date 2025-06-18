#!/usr/bin/env bun
// test-turso.js - Test Turso database connection and provide troubleshooting info

import { createClient } from "@libsql/client";
import { config } from "dotenv";
import { join } from "path";

// Load environment variables
config();
config({ path: join(__dirname, '..', '.env') });

const colors = {
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  blue: "\x1b[34m",
  reset: "\x1b[0m",
};

function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function testTursoConnection() {
  log("blue", "=== Turso Database Connection Test ===\n");
  
  // Check environment variables
  log("yellow", "Checking environment variables...");
  
  const dbUrl = process.env.TURSO_DATABASE_URL;
  const authToken = process.env.TURSO_AUTH_TOKEN;
  const dbName = process.env.TURSO_DB_NAME;
  const tursoEnabled = process.env.TURSO_DB;
  
  console.log(`TURSO_DB: ${tursoEnabled}`);
  console.log(`TURSO_DB_NAME: ${dbName}`);
  console.log(`TURSO_DATABASE_URL: ${dbUrl ? dbUrl.replace(/\?.*/, '') : 'NOT SET'}`);
  console.log(`TURSO_AUTH_TOKEN: ${authToken ? `${authToken.substring(0, 20)}...` : 'NOT SET'}`);
  
  if (!dbUrl || !authToken) {
    log("red", "\n❌ Missing required environment variables!");
    log("yellow", "\nTo fix this:");
    log("yellow", "1. Get your database URL:");
    log("blue", "   turso db show --url tandemx");
    log("yellow", "2. Create a new auth token:");
    log("blue", "   turso db tokens create tandemx --expiration none");
    log("yellow", "3. Update your .env file with the new values");
    return;
  }
  
  log("green", "✅ Environment variables found\n");
  
  // Test connection
  log("yellow", "Testing database connection...");
  
  try {
    const client = createClient({
      url: dbUrl,
      authToken: authToken,
    });
    
    // Simple connection test
    const result = await client.execute("SELECT 1 as test");
    log("green", "✅ Basic connection successful");
    
    // Test table creation (if needed)
    try {
      await client.execute(`
        CREATE TABLE IF NOT EXISTS connection_test (
          id INTEGER PRIMARY KEY,
          test_value TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);
      log("green", "✅ Table creation successful");
      
      // Test insert
      await client.execute({
        sql: "INSERT INTO connection_test (test_value) VALUES (?)",
        args: [`test_${Date.now()}`]
      });
      log("green", "✅ Insert operation successful");
      
      // Test select
      const testResult = await client.execute("SELECT COUNT(*) as count FROM connection_test");
      log("green", `✅ Select operation successful - ${testResult.rows[0].count} test records`);
      
      // Clean up test table
      await client.execute("DROP TABLE connection_test");
      log("green", "✅ Cleanup successful");
      
    } catch (tableErr) {
      log("red", `❌ Table operations failed: ${tableErr.message}`);
    }
    
    log("green", "\n🎉 All database tests passed!");
    
  } catch (err) {
    log("red", `❌ Connection failed: ${err.message}`);
    
    if (err.message.includes('401')) {
      log("red", "\n🔐 Authentication Error!");
      log("yellow", "Your auth token is invalid or expired.");
      log("yellow", "\nTo fix this:");
      log("blue", "1. turso db tokens create tandemx --expiration none");
      log("blue", "2. Copy the new token to your .env file as TURSO_AUTH_TOKEN");
      log("blue", "3. Restart your server");
    } else if (err.message.includes('404')) {
      log("red", "\n🗄️  Database Not Found!");
      log("yellow", "The database URL might be incorrect.");
      log("yellow", "\nTo fix this:");
      log("blue", "1. turso db list  # Check your databases");
      log("blue", "2. turso db show --url <database-name>");
      log("blue", "3. Update TURSO_DATABASE_URL in your .env file");
    } else {
      log("red", "\n🌐 Network or Other Error!");
      log("yellow", "This might be a network connectivity issue.");
      log("yellow", "Check your internet connection and try again.");
    }
  }
}

// Run the test
testTursoConnection().catch(console.error);