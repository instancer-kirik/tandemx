# TandemX Client

## Environment Configuration

This project uses Supabase for database operations. The environment is already pre-configured with your Supabase credentials in:

1. The root `.env` file
2. The `client/.env` file
3. The `client/public/env-config.js` file for browser access

The client will automatically use these credentials regardless of where it's running.

## Running the App

Simply run:
```bash
npm start
```

## Database Schema

The application uses the following tables:
- Meetings
- Contacts
- Calendar events
- Blog posts
- Interest submissions
- Planet models

## Troubleshooting

If you encounter any connection issues:

1. Check that your Supabase project is running and accessible
2. Verify the credentials in both the root `.env` and `client/.env` files
3. Make sure the credentials in `client/public/env-config.js` match
