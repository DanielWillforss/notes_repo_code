

#!/bin/bash

#to make script runnable
#chmod +x setup_postgres.sh
#sudo ./setup_postgres.sh

set -e

DB_USER="admin"
DB_PASS="admin"

echo "Checking for PostgreSQL installation..."

if ! command -v psql >/dev/null 2>&1; then
    echo "PostgreSQL not found. Installing..."
    apt update
    apt install -y postgresql postgresql-client
else
    echo "PostgreSQL is already installed."
fi

echo "Ensuring PostgreSQL service is running..."

if ! systemctl is-active --quiet postgresql; then
    echo "Starting PostgreSQL..."
    systemctl start postgresql
else
    echo "PostgreSQL is running."
fi

echo "Checking if PostgreSQL user '$DB_USER' exists..."

USER_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'")

if [ "$USER_EXISTS" != "1" ]; then
    echo "Creating PostgreSQL superuser '$DB_USER'..."
    sudo -u postgres psql <<EOF
CREATE ROLE $DB_USER WITH
    LOGIN
    SUPERUSER
    CREATEDB
    CREATEROLE
    PASSWORD '$DB_PASS';
EOF
    echo "User '$DB_USER' created."
else
    echo "User '$DB_USER' already exists."
fi

echo "PostgreSQL setup complete."
