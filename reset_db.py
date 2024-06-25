import psycopg2
from psycopg2 import sql

# Define connection parameters
db_params = {
    'host': '127.0.0.1',
    'port': '5432',
    'dbname': 'test_awaazde',
    'user': 'postgres',
    'password': 'postgres'
}

# Connect to the database
conn = psycopg2.connect(**db_params)
conn.autocommit = True
cur = conn.cursor()

# Drop all tables, sequences, views, and materialized views
object_types = ['TABLE', 'SEQUENCE', 'VIEW', 'MATERIALIZED VIEW']

for object_type in object_types:
    cur.execute(sql.SQL("""
        DO $$ DECLARE
            r RECORD;
        BEGIN
            FOR r IN (SELECT schemaname, tablename
                      FROM pg_catalog.pg_tables
                      WHERE schemaname = 'public') LOOP
                EXECUTE 'DROP {} IF EXISTS ' || quote_ident(r.schemaname) || '.' || quote_ident(r.tablename) || ' CASCADE';
            END LOOP;
        END $$;
    """).format(sql.SQL(object_type)))

# Close connection
cur.close()
conn.close()

print("Database reset complete.")
