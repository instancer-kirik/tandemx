// bun-turso.js - Helper script to run TandemX with Turso database
import { spawn } from 'child_process';
import { existsSync, writeFileSync } from 'fs';
import { join } from 'path';
import { config } from 'dotenv';

// Load environment variables from .env file if it exists
config();

// Set environment variables for Turso
process.env.TURSO_DB = 'true';

// Default to local SQLite database if no URL is provided
if (!process.env.TURSO_DATABASE_URL) {
  process.env.TURSO_DATABASE_URL = 'file:tandemx.db';
  console.log('\x1b[33m%s\x1b[0m', 'TURSO_DATABASE_URL not set. Using local SQLite database.');
}

// Create the .use_turso file to signal Turso mode
const useTursoPath = join(__dirname, '..', 'server', '.use_turso');
writeFileSync(useTursoPath, 'Using Turso database via bun-turso.js');

// Create the .disable_electric file to bypass ElectricSQL
const disableElectricPath = join(__dirname, '..', 'server', '.disable_electric');
writeFileSync(disableElectricPath, 'ElectricSQL disabled via bun-turso.js');

// Log configuration
console.log('\x1b[32m%s\x1b[0m', 'TandemX starting with Turso database...');
console.log('\x1b[32m%s\x1b[0m', `Database URL: ${process.env.TURSO_DATABASE_URL.replace(/\?authToken=.*/, '?authToken=******')}`);

// Run the application
const args = ['./run.sh', '--use-turso'];

// Add any additional arguments passed to this script
process.argv.slice(2).forEach(arg => {
  args.push(arg);
});

// Spawn the run.sh process with the environment variables
const child = spawn('/bin/bash', args, {
  stdio: 'inherit',
  env: process.env
});

// Handle process exit
child.on('exit', (code) => {
  console.log('\x1b[33m%s\x1b[0m', `TandemX exited with code ${code}`);
  process.exit(code);
});

// Handle process errors
child.on('error', (err) => {
  console.error('\x1b[31m%s\x1b[0m', 'Failed to start TandemX:', err);
  process.exit(1);
});

// Handle SIGINT (Ctrl+C)
process.on('SIGINT', () => {
  console.log('\x1b[33m%s\x1b[0m', 'Shutting down TandemX...');
  child.kill('SIGINT');
});