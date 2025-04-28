#!/usr/bin/env node

/**
 * Script to create an initial .env file
 * Usage: node scripts/create-env.js
 */

import { writeFileSync } from 'fs';
import { resolve } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// Get the directory name of the current module
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Generate .env file content
const fileContent = `# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-goes-here

# Alternative Next.js prefixed variables (use either these OR the ones above)
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-goes-here

# API Configuration 
API_URL=http://localhost:3000/api
`;

// Write to .env file
const outputPath = resolve(process.cwd(), '.env');
writeFileSync(outputPath, fileContent);

console.log(`✅ Initial .env file created at ${outputPath}`);
console.log('ℹ️ Please update with your actual credentials before running the app.'); 