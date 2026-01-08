#!/bin/bash

# Database initialization script for Docker deployment
# Uses the production schema.sql dumped from test server

set -e

echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h db -p 5432 -U postgres; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done

echo "PostgreSQL is ready!"

# Check if database is already initialized
if psql -h db -U postgres -d whatsapp_db -c "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' LIMIT 1;" | grep -q 1; then
  echo "Database already initialized, skipping schema import"
else
  echo "Initializing database with production schema..."
  psql -h db -U postgres -d whatsapp_db -f /docker-entrypoint-initdb.d/schema.sql
  echo "Database initialized successfully!"
fi
