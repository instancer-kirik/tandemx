# TandemX Troubleshooting Guide

## Common Issues and Solutions

### 1. API Config Endpoint Not Found (404)

**Error Messages:**
```
Failed to load resource: the server responded with a status of 404 (Not Found)
Server returned 404 when fetching config
```

**Solutions:**
- Ensure the server is running with `bun start`
- If you're seeing `/api/config` 404 errors in the console:
  - Check that the Supabase URL and key are properly set in `.env` file
  - Try accessing `/inventory` directly to test if the server is working
  - The system includes fallback Supabase values if not configured

### 2. Styles Not Loading

**Symptoms:**
- Website appears unstyled
- Missing CSS styles and layout

**Solutions:**
- Verify the CSS paths in your HTML files
- Try clearing your browser cache
- Ensure the server is properly serving files from the `/css` directory
- Check network tab in developer tools to see which CSS files are failing

### 3. Supabase Connection Issues

**Error Messages:**
```
Returning fallback project data (Supabase connection unavailable)
```

**Solutions:**
- Check your `.env` file contains valid Supabase credentials
- Ensure both `SUPABASE_URL` and `SUPABASE_KEY` are properly set
- If using the demo URL, be aware it has limited functionality
- Restart the server with `bun start` after modifying environment variables

### 4. Database Errors

**Symptoms:**
- API endpoints return 500 errors
- Database operations fail

**Solutions:**
- Check that the database file exists in the parent directory
- Ensure the database path has correct permissions
- Try backing up and recreating the database:
  ```
  cp tandemx.db tandemx.db.backup
  rm tandemx.db
  bun start  # This will create a fresh database
  ```

### 5. Client-Side JavaScript Errors

**Error Messages:**
```
Uncaught (in promise) {code: 4001, message: 'User rejected the request.'}
```

**Solutions:**
- This is likely a browser extension or wallet-related error
- Try disabling browser extensions and testing again
- If using Chrome, try an incognito window
- If a specific feature is failing, use the test scripts to diagnose:
  ```
  bun run inventory:test
  ```

### 6. Server Startup Failures

**Symptoms:**
- Server fails to start
- Port in use errors

**Solutions:**
- Check if another process is using port 8000
- Kill existing processes:
  ```
  lsof -i :8000  # Find process using port 8000
  kill -9 <PID>  # Kill the process
  ```
- Modify PORT in `.env` to use a different port

### 7. Turso/SQLite Issues

**Error Messages:**
```
SQLite error: database is locked
```

**Solutions:**
- Ensure only one process is accessing the database
- Check for lingering processes that might be using the database
- If persistent, restart the machine
- Try using the client directly with `-i` flag to the SQLite command

## Environment Variable Setup

### Basic Configuration

Create or edit your `.env` file with these variables:

```
PORT=8000
DB_PATH=../tandemx.db
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_public_anon_key
```

### Testing Configuration

For testing only:

```
PORT=8000
DB_PATH=../test_database.db
SUPABASE_URL=https://demo.supabase.co
SUPABASE_KEY=public-anon-key
```

## Running Diagnostics

Use these commands to diagnose problems:

1. Test inventory API functionality:
   ```
   bun run inventory:test
   ```

2. Check server logs:
   ```
   bun start 2>&1 | tee server.log
   ```

3. Verify database integrity:
   ```
   sqlite3 ../tandemx.db .dump > db_dump.sql
   ```

4. Check environment variables:
   ```
   bun -e "console.log(process.env)"
   ```

## Contact Support

If you're still experiencing issues:

1. Gather your server logs
2. Describe the exact steps to reproduce the problem
3. Note your environment (OS, Node/Bun version, browser)
4. Open an issue in the repository or contact support