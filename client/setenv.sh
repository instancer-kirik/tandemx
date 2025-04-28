#!/bin/bash
# Shell script for setting environment variables
# Usage: source setenv.sh

# Load variables from .env
if [ -f .env ]; then
  echo "📋 Loading environment variables from .env"
  export $(grep -v '^#' .env | xargs)
  echo "✅ Environment variables loaded"
else
  echo "❌ No .env file found. Running setup script."
  npm run setup
  export $(grep -v '^#' .env | xargs)
  echo "✅ Environment variables created and loaded"
fi

# Print status
echo "🔑 Using Supabase URL: ${SUPABASE_URL:-${NEXT_PUBLIC_SUPABASE_URL:-Not set}}"
echo "🔒 Using Supabase key: ${SUPABASE_ANON_KEY:0:5}...${SUPABASE_ANON_KEY: -5} (or Next.js version if available)"

# Remind about source command
echo ""
echo "⚠️  Remember: You need to run this script with 'source setenv.sh', not './setenv.sh'"
echo "⚠️  If you ran it directly, the environment variables won't be set in your shell." 