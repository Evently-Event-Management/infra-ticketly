#!/bin/bash
# This script runs on the first startup of the PostgreSQL container.
# It creates multiple databases required by the microservices.

set -e

# Function to perform database creation
# It connects to the default 'postgres' database to run the CREATE DATABASE command.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
    CREATE DATABASE keycloak;
    CREATE DATABASE event_service;
    CREATE DATABASE order_service;
    CREATE DATABASE payment_service;
EOSQL