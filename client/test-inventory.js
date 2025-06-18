#!/usr/bin/env bun
// test-inventory.js - Test script for the Variety Shop Inventory API

import { fetch } from 'bun';

// Color output helpers
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// Configuration
const PORT = process.env.PORT || 8000;
const BASE_URL = `http://localhost:${PORT}/inventory/api/shop`;
// Fallback to old path if inventory endpoint fails
const FALLBACK_URL = `http://localhost:${PORT}/api/shop`;

// Sample test data
const testProduct = {
  name: "Test Product",
  description: "A product created for testing",
  price: 9.99,
  discount_price: 7.99,
  category: "Test",
  sku: `TEST-${Date.now()}`,
  barcode: `BAR${Date.now()}`,
  stock_quantity: 50,
  location: "Test Location",
  supplier: "Test Supplier",
  min_stock_level: 10
};

// Simple testing framework
async function runTests() {
  let testProductId = null;
  let testsFailed = 0;
  let testsPassed = 0;
  // Try primary URL first, then fallback if needed
  let activeBaseUrl = BASE_URL;
  
  log('cyan', '=== Variety Shop Inventory API Tests ===');
  
  // Test connection to see which URL works
  try {
    log('yellow', '\n[TEST] Testing API connectivity...');
    const response = await fetch(`${BASE_URL}/products`);
    if (response.status === 200) {
      log('green', '✓ Using primary inventory API endpoint');
      activeBaseUrl = BASE_URL;
    }
  } catch (error) {
    log('yellow', `! Primary endpoint failed, trying fallback: ${error.message}`);
    try {
      const fallbackResponse = await fetch(`${FALLBACK_URL}/products`);
      if (fallbackResponse.status === 200) {
        log('green', '✓ Using fallback API endpoint');
        activeBaseUrl = FALLBACK_URL;
      } else {
        log('red', '✗ Both API endpoints failed');
      }
    } catch (fallbackError) {
      log('red', `✗ Both API endpoints failed: ${fallbackError.message}`);
    }
  }
  
  // Test 1: Get all products
  try {
    log('yellow', '\n[TEST] Getting all products...');
    const response = await fetch(`${activeBaseUrl}/products`);
    const data = await response.json();
    
    if (response.status === 200 && Array.isArray(data.data)) {
      log('green', `✓ Success! Found ${data.data.length} products`);
      testsPassed++;
    } else {
      log('red', '✗ Failed to get products list');
      testsFailed++;
    }
  } catch (error) {
    log('red', `✗ Error: ${error.message}`);
    testsFailed++;
  }

  // Test 2: Create a new product
  try {
    log('yellow', '\n[TEST] Creating a new product...');
    const response = await fetch(`${activeBaseUrl}/products`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(testProduct)
    });
    
    const data = await response.json();
    
    if (response.status === 201 && data.id) {
      testProductId = data.id;
      log('green', `✓ Success! Created product with ID: ${testProductId}`);
      testsPassed++;
    } else {
      log('red', `✗ Failed to create product: ${JSON.stringify(data)}`);
      testsFailed++;
    }
  } catch (error) {
    log('red', `✗ Error: ${error.message}`);
    testsFailed++;
  }

  // Test 3: Get the created product
  if (testProductId) {
    try {
      log('yellow', '\n[TEST] Getting the created product...');
      const response = await fetch(`${activeBaseUrl}/products/${testProductId}`);
      const data = await response.json();
      
      if (response.status === 200 && data.id === testProductId) {
        log('green', `✓ Success! Retrieved product: ${data.name}`);
        testsPassed++;
      } else {
        log('red', '✗ Failed to get the created product');
        testsFailed++;
      }
    } catch (error) {
      log('red', `✗ Error: ${error.message}`);
      testsFailed++;
    }
  }

  // Test 4: Update the product
  if (testProductId) {
    try {
      log('yellow', '\n[TEST] Updating the product...');
      const updateData = {
        price: 12.99,
        description: "Updated test product description"
      };
      
      const response = await fetch(`${activeBaseUrl}/products/${testProductId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updateData)
      });
      
      const data = await response.json();
      
      if (response.status === 200 && data.price === 12.99) {
        log('green', `✓ Success! Updated product price to ${data.price}`);
        testsPassed++;
      } else {
        log('red', '✗ Failed to update the product');
        testsFailed++;
      }
    } catch (error) {
      log('red', `✗ Error: ${error.message}`);
      testsFailed++;
    }
  }

  // Test 5: Record a restock transaction
  if (testProductId) {
    try {
      log('yellow', '\n[TEST] Recording a restock transaction...');
      const transactionData = {
        product_id: testProductId,
        quantity: 10,
        transaction_type: "restock",
        notes: "Test restock"
      };
      
      const response = await fetch(`${activeBaseUrl}/inventory/transactions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(transactionData)
      });
      
      const data = await response.json();
      
      if (response.status === 201 && data.new_stock_level) {
        log('green', `✓ Success! Recorded restock transaction. New stock level: ${data.new_stock_level}`);
        testsPassed++;
      } else {
        log('red', '✗ Failed to record restock transaction');
        testsFailed++;
      }
    } catch (error) {
      log('red', `✗ Error: ${error.message}`);
      testsFailed++;
    }
  }

  // Test 6: Record a sale transaction
  if (testProductId) {
    try {
      log('yellow', '\n[TEST] Recording a sale transaction...');
      const transactionData = {
        product_id: testProductId,
        quantity: 5,
        transaction_type: "sale",
        notes: "Test sale"
      };
      
      const response = await fetch(`${activeBaseUrl}/inventory/transactions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(transactionData)
      });
      
      const data = await response.json();
      
      if (response.status === 201 && data.new_stock_level) {
        log('green', `✓ Success! Recorded sale transaction. New stock level: ${data.new_stock_level}`);
        testsPassed++;
      } else {
        log('red', '✗ Failed to record sale transaction');
        testsFailed++;
      }
    } catch (error) {
      log('red', `✗ Error: ${error.message}`);
      testsFailed++;
    }
  }

  // Test 7: Get transaction history for the product
  if (testProductId) {
    try {
      log('yellow', '\n[TEST] Getting transaction history...');
      const response = await fetch(`${activeBaseUrl}/products/${testProductId}/transactions`);
      const data = await response.json();
      
      if (response.status === 200 && Array.isArray(data.data)) {
        log('green', `✓ Success! Found ${data.data.length} transactions for the product`);
        testsPassed++;
      } else {
        log('red', '✗ Failed to get transaction history');
        testsFailed++;
      }
    } catch (error) {
      log('red', `✗ Error: ${error.message}`);
      testsFailed++;
    }
  }

  // Test 8: Get categories
  try {
    log('yellow', '\n[TEST] Getting product categories...');
    const response = await fetch(`${activeBaseUrl}/categories`);
    const data = await response.json();
    
    if (response.status === 200 && Array.isArray(data)) {
      log('green', `✓ Success! Found ${data.length} categories`);
      testsPassed++;
    } else {
      log('red', '✗ Failed to get categories');
      testsFailed++;
    }
  } catch (error) {
    log('red', `✗ Error: ${error.message}`);
    testsFailed++;
  }

  // Test summary
  log('cyan', '\n=== Test Summary ===');
  log('green', `Tests passed: ${testsPassed}`);
  log('red', `Tests failed: ${testsFailed}`);
  
  if (testsFailed === 0) {
    log('green', '\n✓ All tests passed! The inventory system is working correctly.');
  } else {
    log('red', '\n✗ Some tests failed. Please check the error messages above.');
  }
}

// Run the tests
runTests().catch(error => {
  log('red', `Unhandled error: ${error.message}`);
  process.exit(1);
});