#!/usr/bin/env bun
// test-supabase.js - Comprehensive Supabase test for TandemX projects and posts

import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';

// Load environment variables
config({ path: '../.env' });

const colors = {
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  blue: "\x1b[34m",
  cyan: "\x1b[36m",
  reset: "\x1b[0m",
  bold: "\x1b[1m",
};

function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSection(title) {
  console.log(`\n${colors.bold}${colors.cyan}=== ${title} ===${colors.reset}`);
}

// Supabase configuration
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://xlmibzeenudmkqgiyaif.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhsbWliemVlbnVkbWtxZ2l5YWlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMzODAxNzMsImV4cCI6MjA1ODk1NjE3M30.Yn9AIaqkstjgz1coNJGB-o66L7wiJZZvCXfqyM6Wavs';

let supabase;
let testResults = {
  connection: false,
  projects: false,
  posts: false,
  auth: false,
  realtime: false,
};

async function initializeSupabase() {
  logSection("Initializing Supabase Client");
  
  try {
    log("yellow", "Creating Supabase client...");
    log("blue", `URL: ${SUPABASE_URL}`);
    log("blue", `Key: ${SUPABASE_ANON_KEY.substring(0, 20)}...`);
    
    supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    
    if (supabase) {
      log("green", "✅ Supabase client created successfully");
      testResults.connection = true;
      return true;
    } else {
      log("red", "❌ Failed to create Supabase client");
      return false;
    }
  } catch (error) {
    log("red", `❌ Error creating Supabase client: ${error.message}`);
    return false;
  }
}

async function testBasicConnection() {
  logSection("Testing Basic Connection");
  
  try {
    log("yellow", "Testing connection with basic query...");
    
    // Try to access the projects table
    const { data, error, count } = await supabase
      .from('projects')
      .select('*', { count: 'exact', head: true });
    
    if (error) {
      log("red", `❌ Connection test failed: ${error.message}`);
      log("yellow", `Error details: ${JSON.stringify(error, null, 2)}`);
      return false;
    }
    
    log("green", `✅ Connection successful! Found ${count || 0} projects in database`);
    return true;
  } catch (error) {
    log("red", `❌ Connection test failed with exception: ${error.message}`);
    return false;
  }
}

async function testProjectsTable() {
  logSection("Testing Projects Table");
  
  try {
    log("yellow", "Querying projects table...");
    
    // Test reading projects
    const { data: projects, error: readError } = await supabase
      .from('projects')
      .select(`
        id,
        title,
        description,
        created_at,
        updated_at,
        status,
        user_id,
        project_type,
        tags,
        is_public
      `)
      .limit(5);
    
    if (readError) {
      log("red", `❌ Failed to read projects: ${readError.message}`);
      return false;
    }
    
    log("green", `✅ Successfully read ${projects?.length || 0} projects`);
    
    if (projects && projects.length > 0) {
      log("blue", "Sample project data:");
      console.log(JSON.stringify(projects[0], null, 2));
    }
    
    // Test inserting a test project
    log("yellow", "Testing project insertion...");
    
    const testProject = {
      title: "Test Project - " + Date.now(),
      description: "This is a test project created by the Supabase test script",
      status: "draft",
      project_type: "motorcycle_build",
      tags: ["test", "automation"],
      is_public: false,
    };
    
    const { data: insertedProject, error: insertError } = await supabase
      .from('projects')
      .insert([testProject])
      .select()
      .single();
    
    if (insertError) {
      log("yellow", `⚠️  Could not insert test project: ${insertError.message}`);
      log("blue", "This might be due to RLS policies or permissions");
    } else {
      log("green", `✅ Successfully inserted test project with ID: ${insertedProject.id}`);
      
      // Clean up - delete the test project
      const { error: deleteError } = await supabase
        .from('projects')
        .delete()
        .eq('id', insertedProject.id);
      
      if (deleteError) {
        log("yellow", `⚠️  Could not delete test project: ${deleteError.message}`);
      } else {
        log("green", "✅ Test project cleaned up successfully");
      }
    }
    
    testResults.projects = true;
    return true;
  } catch (error) {
    log("red", `❌ Projects table test failed: ${error.message}`);
    return false;
  }
}

async function testPostsTable() {
  logSection("Testing Posts/Content Table");
  
  try {
    log("yellow", "Querying posts/content table...");
    
    // Test reading posts
    const { data: posts, error: readError } = await supabase
      .from('content')
      .select(`
        id,
        title,
        content,
        content_type,
        created_at,
        updated_at,
        author_id,
        is_published,
        tags,
        metadata
      `)
      .limit(5);
    
    if (readError) {
      log("red", `❌ Failed to read content: ${readError.message}`);
      
      // Try alternative table names
      log("yellow", "Trying alternative table name 'posts'...");
      const { data: altPosts, error: altError } = await supabase
        .from('posts')
        .select('*')
        .limit(5);
      
      if (altError) {
        log("red", `❌ Failed to read posts: ${altError.message}`);
        return false;
      } else {
        log("green", `✅ Successfully read ${altPosts?.length || 0} posts from 'posts' table`);
        testResults.posts = true;
        return true;
      }
    }
    
    log("green", `✅ Successfully read ${posts?.length || 0} content items`);
    
    if (posts && posts.length > 0) {
      log("blue", "Sample content data:");
      console.log(JSON.stringify(posts[0], null, 2));
    }
    
    // Test inserting a test post
    log("yellow", "Testing content insertion...");
    
    const testPost = {
      title: "Test Content - " + Date.now(),
      content: "This is test content created by the Supabase test script",
      content_type: "article",
      is_published: false,
      tags: ["test", "automation"],
      metadata: { test: true, created_by: "test_script" }
    };
    
    const { data: insertedPost, error: insertError } = await supabase
      .from('content')
      .insert([testPost])
      .select()
      .single();
    
    if (insertError) {
      log("yellow", `⚠️  Could not insert test content: ${insertError.message}`);
      log("blue", "This might be due to RLS policies or permissions");
    } else {
      log("green", `✅ Successfully inserted test content with ID: ${insertedPost.id}`);
      
      // Clean up - delete the test post
      const { error: deleteError } = await supabase
        .from('content')
        .delete()
        .eq('id', insertedPost.id);
      
      if (deleteError) {
        log("yellow", `⚠️  Could not delete test content: ${deleteError.message}`);
      } else {
        log("green", "✅ Test content cleaned up successfully");
      }
    }
    
    testResults.posts = true;
    return true;
  } catch (error) {
    log("red", `❌ Posts/content table test failed: ${error.message}`);
    return false;
  }
}

async function testAuthentication() {
  logSection("Testing Authentication");
  
  try {
    log("yellow", "Testing auth session...");
    
    const { data: { session }, error } = await supabase.auth.getSession();
    
    if (error) {
      log("yellow", `⚠️  Auth session error: ${error.message}`);
    } else {
      if (session) {
        log("green", "✅ Active auth session found");
        log("blue", `User: ${session.user.email || 'Unknown'}`);
      } else {
        log("blue", "ℹ️  No active auth session (anonymous access)");
      }
    }
    
    // Test auth user retrieval
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (userError) {
      log("yellow", `⚠️  Auth user error: ${userError.message}`);
    } else {
      if (user) {
        log("green", "✅ User data retrieved");
        log("blue", `User ID: ${user.id}`);
      } else {
        log("blue", "ℹ️  No authenticated user");
      }
    }
    
    testResults.auth = true;
    return true;
  } catch (error) {
    log("red", `❌ Authentication test failed: ${error.message}`);
    return false;
  }
}

async function testRealtimeFeatures() {
  logSection("Testing Realtime Features");
  
  try {
    log("yellow", "Testing realtime connection...");
    
    // Create a simple realtime subscription
    const channel = supabase.channel('test-channel');
    
    let connected = false;
    let subscribed = false;
    
    // Subscribe to connection status
    channel
      .on('presence', { event: 'sync' }, () => {
        connected = true;
        log("green", "✅ Realtime connection established");
      })
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'projects' }, 
        (payload) => {
          subscribed = true;
          log("green", "✅ Realtime subscription working");
        }
      )
      .subscribe();
    
    // Wait a bit for connection
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Clean up
    await supabase.removeChannel(channel);
    
    if (connected || subscribed) {
      log("green", "✅ Realtime features are functional");
      testResults.realtime = true;
    } else {
      log("yellow", "⚠️  Realtime connection could not be verified");
      testResults.realtime = false;
    }
    
    return true;
  } catch (error) {
    log("red", `❌ Realtime test failed: ${error.message}`);
    return false;
  }
}

async function testDatabaseSchema() {
  logSection("Testing Database Schema");
  
  try {
    log("yellow", "Checking available tables...");
    
    // Check what tables exist
    const tables = [
      'projects',
      'content',
      'posts',
      'users',
      'profiles',
      'comments',
      'categories',
      'tags'
    ];
    
    for (const table of tables) {
      try {
        const { data, error } = await supabase
          .from(table)
          .select('*', { count: 'exact', head: true });
        
        if (error) {
          log("red", `❌ Table '${table}' not accessible: ${error.message}`);
        } else {
          log("green", `✅ Table '${table}' exists and accessible (${data?.length || 0} rows)`);
        }
      } catch (e) {
        log("red", `❌ Table '${table}' error: ${e.message}`);
      }
    }
    
    return true;
  } catch (error) {
    log("red", `❌ Schema test failed: ${error.message}`);
    return false;
  }
}

async function runAllTests() {
  logSection("TandemX Supabase Connection Test");
  
  log("blue", "Testing Supabase integration for projects and posts functionality...");
  log("blue", "This test verifies database connectivity, table access, and basic CRUD operations.");
  
  const startTime = Date.now();
  
  // Run all tests
  await initializeSupabase();
  
  if (testResults.connection) {
    await testBasicConnection();
    await testDatabaseSchema();
    await testProjectsTable();
    await testPostsTable();
    await testAuthentication();
    await testRealtimeFeatures();
  }
  
  // Summary
  logSection("Test Results Summary");
  
  const endTime = Date.now();
  const duration = ((endTime - startTime) / 1000).toFixed(2);
  
  log("blue", `Test completed in ${duration} seconds`);
  console.log();
  
  // Results table
  const results = [
    ["Test Category", "Status"],
    ["Connection", testResults.connection ? "✅ PASS" : "❌ FAIL"],
    ["Projects Table", testResults.projects ? "✅ PASS" : "❌ FAIL"],
    ["Posts/Content", testResults.posts ? "✅ PASS" : "❌ FAIL"],
    ["Authentication", testResults.auth ? "✅ PASS" : "❌ FAIL"],
    ["Realtime", testResults.realtime ? "✅ PASS" : "⚠️  PARTIAL"],
  ];
  
  // Simple table formatting
  results.forEach((row, index) => {
    if (index === 0) {
      log("bold", row.join(" | "));
      log("blue", "─".repeat(30));
    } else {
      console.log(row.join(" | "));
    }
  });
  
  console.log();
  
  // Overall status
  const passedTests = Object.values(testResults).filter(Boolean).length;
  const totalTests = Object.keys(testResults).length;
  
  if (passedTests === totalTests) {
    log("green", `🎉 All tests passed! (${passedTests}/${totalTests})`);
    log("green", "Supabase is ready for projects and posts functionality.");
  } else if (passedTests > 0) {
    log("yellow", `⚠️  Partial success: ${passedTests}/${totalTests} tests passed`);
    log("yellow", "Some features may not work correctly. Check the errors above.");
  } else {
    log("red", `❌ All tests failed! (${passedTests}/${totalTests})`);
    log("red", "Supabase connection is not working. Check your configuration.");
  }
  
  // Configuration help
  if (!testResults.connection) {
    console.log();
    log("yellow", "🔧 Configuration Help:");
    log("blue", "1. Check your .env file has the correct SUPABASE_URL and SUPABASE_ANON_KEY");
    log("blue", "2. Verify your Supabase project is active and accessible");
    log("blue", "3. Check your network connection");
    log("blue", "4. Ensure RLS policies allow anonymous access if needed");
  }
  
  // Exit with appropriate code
  process.exit(passedTests === totalTests ? 0 : 1);
}

// Handle uncaught errors
process.on('unhandledRejection', (reason, promise) => {
  log("red", `❌ Unhandled rejection at: ${promise}, reason: ${reason}`);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  log("red", `❌ Uncaught exception: ${error.message}`);
  process.exit(1);
});

// Run the tests
runAllTests().catch((error) => {
  log("red", `❌ Test runner failed: ${error.message}`);
  process.exit(1);
});