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

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

