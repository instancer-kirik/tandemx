// Supabase client test script
import { create_client } from './access_content_ffi.js';

// Supabase credentials - same as in access_content_ffi.js
const url = 'https://xlmibzeenudmkqgiyaif.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhsbWliemVlbnVkbWtxZ2l5YWlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMzODAxNzMsImV4cCI6MjA1ODk1NjE3M30.Yn9AIaqkstjgz1coNJGB-o66L7wiJZZvCXfqyM6Wavs';

// Initialize Supabase client and test connection
async function testSupabaseConnection() {
  console.log('Starting Supabase client test...');
  
  try {
    // Initialize client
    const supabaseClient = create_client(url, key);
    console.log('Supabase client created successfully:', supabaseClient);
    
    // Test a simple query to the projects table
    console.log('Testing query to projects table...');
    const { data, error } = await supabaseClient
      .from('projects')
      .select('*');
    
    if (error) {
      console.error('Error querying projects table:', error);
      return false;
    }
    
    console.log('Successfully queried projects table. Data:', data);
    return true;
  } catch (e) {
    console.error('Exception in Supabase test:', e);
    return false;
  }
}

// Run the test when the script is loaded
testSupabaseConnection()
  .then(success => {
    if (success) {
      console.log('✅ Supabase test completed successfully');
    } else {
      console.error('❌ Supabase test failed');
    }
  })
  .catch(err => {
    console.error('❌ Uncaught error in Supabase test:', err);
  });

// Export the test function for potential use in other modules
export { testSupabaseConnection };