// Simple test to verify Supabase connection
import { initDb } from './src/db_ffi.js';

async function testConnection() {
  console.log('🔍 Testing Supabase connection...');
  const supabase = initDb();
  
  try {
    // Try a simple query to verify connection
    const { data, error } = await supabase.from('planet_models').select('*').limit(1);
    
    if (error) {
      console.error('❌ Connection error:', error.message);
      process.exit(1);
    }
    
    console.log('✅ Connection successful!');
    console.log('📊 Sample data:', data);
    
    process.exit(0);
  } catch (err) {
    console.error('❌ Unexpected error:', err.message);
    process.exit(1);
  }
}

testConnection(); 