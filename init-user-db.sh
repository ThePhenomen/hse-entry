#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE TABLE mytbl (
        id serial PRIMARY KEY,
        number integer NOT NULL
    );
EOSQL