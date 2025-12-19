--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------------------------- FONCTIONS NECESSITANT -------------------------------
------------------------ DES DROITS D'ADMINISTRATION ---------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- CREATE DATABASE MyGeoDatabase OWNER bduni ENCODING 'UTF8' LC_COLLATE 'french_FRANCE.UTF8' LC_CTYPE 'french_FRANCE.UTF8';
-- CREATE DATABASE MyGeoDatabase OWNER bduni ENCODING 'WIN1252' LC_COLLATE 'french_FRANCE.WIN1252' LC_CTYPE 'french_FRANCE.WIN1252';

-- Une fois la base créée, il faut se connecter dessus pour créer les extensions
-- suivantes (qui nécessitent les droits administrateur)

-- Add necessary extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create schemas
CREATE SCHEMA au;
CREATE SCHEMA hy;
CREATE SCHEMA tn;
CREATE SCHEMA ib;
CREATE SCHEMA release;
CREATE SCHEMA validation;

-- Grant permissions
GRANT ALL ON SCHEMA au TO ome2;
GRANT ALL ON SCHEMA hy TO ome2;
GRANT ALL ON SCHEMA tn TO ome2;
GRANT ALL ON SCHEMA ib TO ome2;
GRANT ALL ON SCHEMA release TO ome2;
GRANT ALL ON SCHEMA public TO ome2;
GRANT ALL ON SCHEMA validation TO ome2;

ALTER DEFAULT PRIVILEGES IN SCHEMA au GRANT ALL ON tables TO ome2;
ALTER DEFAULT PRIVILEGES IN SCHEMA hy GRANT ALL ON tables TO ome2;
ALTER DEFAULT PRIVILEGES IN SCHEMA tn GRANT ALL ON tables TO ome2;
ALTER DEFAULT PRIVILEGES IN SCHEMA ib GRANT ALL ON tables TO ome2;
ALTER DEFAULT PRIVILEGES IN SCHEMA release GRANT ALL ON tables TO ome2;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON tables TO ome2;
ALTER DEFAULT PRIVILEGES IN SCHEMA validation GRANT ALL ON tables TO ome2;

GRANT ALL ON ALL TABLES IN SCHEMA au TO ome2;
GRANT ALL ON ALL TABLES IN SCHEMA hy TO ome2;
GRANT ALL ON ALL TABLES IN SCHEMA tn TO ome2;
GRANT ALL ON ALL TABLES IN SCHEMA ib TO ome2;
GRANT ALL ON ALL TABLES IN SCHEMA release TO ome2;
GRANT ALL ON ALL TABLES IN SCHEMA public TO ome2;
GRANT ALL ON ALL TABLES IN SCHEMA validation TO ome2;

-- TO-DO: user ome2_validation on schema validation