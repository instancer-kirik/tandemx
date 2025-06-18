# PostgreSQL Setup with Fly.io for TandemX

This guide outlines the steps to set up a PostgreSQL database on Fly.io for the TandemX application.

## Prerequisites

- [Fly.io CLI](https://fly.io/docs/hands-on/install-flyctl/) installed and authenticated
- Your TandemX application already deployed on Fly.io or ready to be deployed

## Creating a PostgreSQL Database on Fly.io

1. Create a new PostgreSQL database cluster:

```bash
fly postgres create --name tandemx-db --region iad --vm-size shared-cpu-1x --volume-size 10
```

This creates a PostgreSQL database with the following specifications:
- Name: `tandemx-db`
- Region: IAD (Washington D.C.)
- VM Size: `shared-cpu-1x` (1 shared CPU)
- Volume Size: 10GB

2. After creation, Fly.io will output connection details. Save these for the next steps.

## Attaching the Database to Your Application

1. Attach the PostgreSQL database to your TandemX application:

```bash
fly postgres attach --app tandemx --postgres-app tandemx-db
```

This command will:
- Create a `DATABASE_URL` environment variable in your application
- Set up network connectivity between your app and database

## Configuring Your Gleam Application

1. Update your Gleam application to use the `DATABASE_URL` environment variable.

In your server code, you'll need to add database connection handling:

```gleam
// Example database connection code
fn get_database_url() -> Result(String, String) {
  case env.string("DATABASE_URL") {
    Ok(url) -> Ok(url)
    Error(_) -> Error("DATABASE_URL not set")
  }
}
```

2. Create a schema migration file in your project:

```sql
-- schema.sql
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add other tables as needed
```

3. Run migrations during application startup:

```gleam
fn run_migrations() -> Result(Nil, String) {
  case get_database_url() {
    Ok(url) -> {
      // Run migrations here using the database URL
      // For example, using a PostgreSQL client to execute SQL files
      Ok(Nil)
    }
    Error(e) -> Error(e)
  }
}
```

## Setting Up Local Development

For local development, create a `.env` file:

```
DATABASE_URL=postgres://postgres:password@localhost:5432/tandemx
```

You can run a local PostgreSQL instance using Docker:

```bash
docker run --name tandemx-postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=tandemx -p 5432:5432 -d postgres:14
```

## Managing Database Secrets

For secure credentials management, use Fly.io secrets:

```bash
fly secrets set DATABASE_USER=your_username DATABASE_PASSWORD=your_secure_password
```

## Database Backup and Restore

To backup your database:

```bash
fly postgres backup tandemx-db
```

To restore from a backup:

```bash
fly postgres restore tandemx-db --backup-id <backup-id>
```

## Connecting to the Database

To connect to your database for manual operations:

```bash
fly postgres connect -a tandemx-db
```

This will open a PostgreSQL shell connected to your database.

## Troubleshooting

If you encounter connection issues:

1. Verify your app and database are in the same region
2. Check that the `DATABASE_URL` environment variable is correctly set
3. Ensure your application has the correct privileges to access the database
4. Check Fly.io logs for connection errors: `fly logs -a tandemx`

## References

- [Fly.io PostgreSQL Documentation](https://fly.io/docs/postgres/)
- [Fly.io App Configuration](https://fly.io/docs/reference/configuration/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)