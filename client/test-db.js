// Simple test to verify Supabase connection
import {
  create_client,
  query_table,
  select_all,
  run_query
} from './supabase/build/dev/javascript/supabase/supabase_ffi.mjs'

// Initialize the client
const url = 'https://xlmibzeenudmkqgiyaif.supabase.co'
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhsbWliemVlbnVkbWtxZ2l5YWlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMzODAxNzMsImV4cCI6MjA1ODk1NjE3M30.Yn9AIaqkstjgz1coNJGB-o66L7wiJZZvCXfqyM6Wavs'
const client = create_client(url, key)

async function testDb() {
  try {
    const query = select_all(query_table(client, 'planet_models'))
    const result = await run_query(query)
    
    if (result instanceof Error) {
      console.error('Error:', result)
      return
    }
    
    console.log('Success! Data:', result)
  } catch (error) {
    console.error('Error:', error)
  }
}

testDb() 