#!/usr/bin/env node

/**
 * Script to generate environment config from .env file
 * Usage: node scripts/set-env.js
 */

import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';
import { writeFileSync } from 'fs';
import dotenv from 'dotenv';

// Get the directory name of the current module
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables from .env file
const envConfig = dotenv.config({ path: resolve(process.cwd(), '.env') }).parsed || {};

// Add Next.js prefixed variables
const nextPublicEnv = {};
for (const key in process.env) {
  if (key.startsWith('NEXT_PUBLIC_')) {
    const unprefixedKey = key.replace('NEXT_PUBLIC_', '');
    nextPublicEnv[unprefixedKey] = process.env[key];
  }
}

// Merge with .env variables, prioritizing unprefixed
const envVars = { ...nextPublicEnv, ...envConfig };

// Generate JavaScript file content
const fileContent = `// Generated at ${new Date().toISOString()}
// This file is auto-generated - do not edit directly!

window._env = ${JSON.stringify(envVars, null, 2)};
`;

// Write to public directory
const outputPath = resolve(process.cwd(), 'public', 'env-config.js');
writeFileSync(outputPath, fileContent);

console.log(`✅ Environment configuration written to ${outputPath}`); 