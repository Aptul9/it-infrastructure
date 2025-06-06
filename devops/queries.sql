-- 1. Create the user
CREATE USER gitlab WITH PASSWORD 'gitlab';

-- 2. Grant all privileges on the database
GRANT ALL PRIVILEGES ON DATABASE gitlab TO gitlab;

-- 3. Connect to the database to grant further permissions on objects

-- 4. Give full privileges on all existing tables, sequences, and functions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gitlab;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO gitlab;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO gitlab;

-- 5. Set default privileges for future objects created in the schema
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON TABLES TO gitlab;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON SEQUENCES TO gitlab;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON FUNCTIONS TO gitlab;

-- Allow creating new tables/functions/sequences in public
GRANT CREATE ON SCHEMA public TO gitlab;

-- If needed, transfer schema ownership
ALTER SCHEMA public OWNER TO gitlab;
