#!/bin/sh
# entrypoint.sh

# Wait for the database to be ready
echo "Waiting for DB to be ready..."
while ! nc -z db 3306; do
  sleep 1
done
echo "DB is ready."

# Run migrations
echo "Running migrations..."
yarn migration:start

# Start the application
echo "Starting the application..."
exec yarn start

