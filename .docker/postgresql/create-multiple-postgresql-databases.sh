#!/bin/bash

set -e
set -u

function create_user_and_database() {
    local database=$(echo $1 | tr ',' ' ' | awk  '{print $1}')
    local owner=$(echo $1 | tr ',' ' ' | awk  '{print $2}')
    local password=$(echo $1 | tr ',' ' ' | awk  '{print $3}')

    echo "  Creating user '$owner' with password and database '$database'"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$owner') THEN
                CREATE USER $owner WITH PASSWORD '$password';
            END IF;
        END
        \$\$;
        CREATE DATABASE $database WITH OWNER = $owner;  -- Explicitly set owner during creation
        GRANT ALL PRIVILEGES ON DATABASE $database TO $owner;
EOSQL

    # Connect to the new database and ensure schema privileges
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname="$database" <<-EOSQL
        -- Ensure the user owns the public schema
        ALTER SCHEMA public OWNER TO $owner;

        -- Grant all privileges on the public schema
        GRANT ALL PRIVILEGES ON SCHEMA public TO $owner;

        -- Grant all privileges on all tables and sequences in public schema
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $owner;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $owner;

        -- Set default privileges for future tables and sequences
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $owner;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $owner;
EOSQL
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
    echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
    for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ':' ' '); do
        create_user_and_database $db
    done
    echo "Multiple databases created"
fi
