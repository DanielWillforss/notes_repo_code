#!/bin/bash

#chmod +x make_test_db.sh
#sudo ./make_test_db.sh

set -e

# Absolute path to the directory this script lives in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# Config
DB_NAME=test_db
DB_USER=admin
DB_PASS='admin'
MIGRATIONS_DIR="$SCRIPT_DIR/sql_migrations"
SEEDS_DIR="$SCRIPT_DIR/sql_seeds"

# Export password to avoid interactive prompt
export PGPASSWORD=$DB_PASS

echo "Dropping database $DB_NAME if it exists..."
dropdb -h localhost -U $DB_USER --if-exists $DB_NAME

echo "Creating database $DB_NAME..."
createdb -h localhost -U $DB_USER -O $DB_USER $DB_NAME

echo "Running migration scripts..."
for file in $MIGRATIONS_DIR/*.sql; do
    echo "Applying $file..."
    psql -h localhost -U $DB_USER -d $DB_NAME -f "$file"
done

echo "Running test seed scripts..."
for file in $SEEDS_DIR/test_*.sql; do
    if [ -e "$file" ]; then
        echo "Applying $file..."
        #psql -h localhost -U $DB_USER -d $DB_NAME -f "$file"
    fi
done

echo "Database setup complete."

# Unset password
unset PGPASSWORD