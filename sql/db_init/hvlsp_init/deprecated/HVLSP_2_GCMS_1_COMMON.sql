--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------------------------- FONCTIONS UTILITAIRES -------------------------------
--------------------------   (PostgreSQL 9.5+)   -------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- DROP ALL FUNCTIONS STARTING WITH ign_gcms_ 
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_drop_all_ign_gcms_function (drop_cascade boolean) 
	RETURNS void AS $$
DECLARE
	r RECORD;
BEGIN
	FOR r IN SELECT n.nspname as schema,
				p.proname as name,
				pg_catalog.pg_get_function_result(p.oid) as result_type,
				pg_catalog.pg_get_function_arguments(p.oid) as argument_types,
				CASE
					WHEN p.proisagg THEN 'agg'
					WHEN p.proiswindow THEN 'window'
					WHEN p.prorettype = 'pg_catalog.trigger'::pg_catalog.regtype THEN 'trigger'
					ELSE 'normal'
				END as "type"
			FROM pg_catalog.pg_proc p
			LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
			WHERE pg_catalog.pg_function_is_visible(p.oid)
				AND n.nspname <> 'pg_catalog'
				AND n.nspname <> 'information_schema'
				AND p.proname LIKE 'ign_gcms_%'
				AND p.proname NOT LIKE 'ign_gcms_drop_all_ign_gcms_function%'
			ORDER BY 1, 2, 4
    LOOP
        -- can do some processing here
		IF (drop_cascade) THEN
			EXECUTE format('DROP FUNCTION IF EXISTS %s(%s) CASCADE', r.name, r.argument_types);
		ELSE
			EXECUTE format('DROP FUNCTION IF EXISTS %s(%s)', r.name, r.argument_types);
		END IF;
    END LOOP;
    RETURN;
END
$$ LANGUAGE plpgsql ;

--SELECT ign_gcms_drop_all_ign_gcms_function(true);


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------------- FONCTIONS RELATIVES A LA STRUCTURE DE LA BASE -------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Test si une table existe
--------------------------------------------------------------------------------
-- La fonction to_regclass (postgres 9.4 et plus) permet
-- 1/ de se prémunir de l'injection SQL
-- 2/ de gérer les noms de table qualifiés par un schema
-- 3/ de toujours renvoyer un boolean et non une erreur
-- Pour un nom de table mixed case, mettre le nom de table entre guillemets :
-- ign_gcms_test_table_exists ('"MaTable"').
-- On peut appeler en préfixant par le nom du schéma :
-- SELECT ign_gcms_test_table_exists('nom_schema.nom_table').
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_test_table_exists (_table text) 
	RETURNS boolean AS $$
BEGIN
    IF current_setting('server_version_num')::integer < 90600 THEN
        RETURN to_regclass(_table::cstring) IS NOT NULL;
    ELSE
        RETURN to_regclass(_table) IS NOT NULL;
    END IF;
END
$$ LANGUAGE plpgsql ;


--------------------------------------------------------------------------------
-- Test si une colonne existe
--------------------------------------------------------------------------------
-- La fonction to_regclass (postgres 9.4 et plus) permet
-- 1/ de se prémunir de l'injection SQL
-- 2/ de gérer les noms de table qualifiés par un schema
-- 3/ de toujours renvoyer un boolean et non une erreur
-- Pour un nom de table mixed case, mettre le nom de table entre guillemets
-- Par contre, le nom de colonne reste entre simples quote (il est traité
-- comme un littéral)
-- ign_gcms_test_column_exists ('"MaTable"', 'MaColonne').
-- On peut appeler en préfixant par le nom du schéma :
-- SELECT ign_gcms_test_column_exists('nom_schema.nom_table','truc').
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_test_column_exists (_table text, _column text) 
	RETURNS boolean AS $$
DECLARE
    rg regclass; 
BEGIN
    IF current_setting('server_version_num')::integer < 90600 THEN
        rg := to_regclass(_table::cstring);
    ELSE
        rg := to_regclass(_table);
    END IF;

	IF EXISTS (
		SELECT 1 FROM pg_attribute
		WHERE  attrelid = rg
		AND    attname = _column
		AND    NOT attisdropped
	) THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
END
$$ LANGUAGE plpgsql ;

-- idem with regclass argument
CREATE OR REPLACE FUNCTION  ign_gcms_test_column_exists (_table regclass, _column text) 
	RETURNS boolean AS $$
BEGIN	
	IF EXISTS (
		SELECT 1 FROM pg_attribute
		WHERE  attrelid = _table
		AND    attname = _column
		AND    NOT attisdropped
	) THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
END
$$ LANGUAGE plpgsql ;


-- ----------------------------------------------------------------------------
-- Renvoie le nom du schema et de la table à partir du nom composite
-- Renvoie null si la table n'existe pas
-- ----------------------------------------------------------------------------
-- Cette fonction facilite la dérivation de nom de table (ex. route -> route_h)
-- dans le cas où la table se trouve dans un autre schema ou si elle utilise
-- une graphie riche.
-- Quand on recompose le nom de la table dérivée, ne pas oublier d'utiliser
-- quote_ident ou quote literal selon le contexte
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION  ign_gcms_decompose_table_name (rel regclass)
	RETURNS TEXT[] AS $$
DECLARE
    schema_name TEXT;
    table_name TEXT;
    st TEXT[];
BEGIN
    IF (rel IS NOT NULL) THEN
    	SELECT nspname INTO schema_name FROM pg_class, pg_namespace WHERE pg_class.relnamespace = pg_namespace.oid AND pg_class.oid = rel ;
    	SELECT relname INTO table_name FROM pg_class WHERE  pg_class.oid = rel ;
    	st[0] := schema_name;
    	st[1] := table_name;
    END IF;
    RETURN st;
END
$$ LANGUAGE plpgsql ;

-- idem with text argument
CREATE OR REPLACE FUNCTION  ign_gcms_decompose_table_name (table_name TEXT)
	RETURNS TEXT[] AS $$
DECLARE
    rc regclass;
BEGIN
    IF current_setting('server_version_num')::integer < 90600 THEN
        rc := to_regclass(table_name::cstring);
    ELSE
        rc := to_regclass(table_name);
    END IF;
    IF (rc IS NULL) THEN
    	RETURN NULL;
    ELSE
    	RETURN ign_gcms_decompose_table_name(rc);
    END IF;
END
$$ LANGUAGE plpgsql ;


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------- FONCTIONS RELATIVES A LA GEOMETRIE -------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Calcul initial de l'empreinte géométrique (celle pour GCVS)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_empreinte(geom GEOMETRY) 
	RETURNS geometry AS $$
DECLARE
	xmin float;
	xmax float;
	ymin float;
	ymax float;
	empreinte GEOMETRY;

BEGIN
	IF ST_IsEmpty(geom) THEN
		empreinte := ST_GeomFromText('LINESTRING EMPTY');
		empreinte := ST_SetSRID(empreinte, ST_SRID(geom));
		RETURN empreinte;
	ELSE
		SELECT ST_XMin(geom), ST_YMin(geom), ST_XMax(geom), ST_YMax(geom) INTO xmin, ymin, xmax, ymax;
		empreinte := ST_MakeLine( ST_MakePoint(xmin,ymin), ST_MakePoint(xmax,ymax) );
		empreinte := ST_SetSRID(empreinte, ST_SRID(geom));
		RETURN empreinte;
	END IF;
END
$$
LANGUAGE plpgsql
SET search_path TO public;


--------------------------------------------------------------------------------
-- Mise à jour de l'empreinte géométrique (pour GCVS)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_empreinte(geom1 geometry, geom2 geometry) 
	RETURNS geometry AS
$$
DECLARE
	xmin1 float;
	xmin2 float;
	xmax1 float;
	xmax2 float;
	ymin1 float;
	ymin2 float;
	ymax1 float;
	ymax2 float;
	empreinte GEOMETRY;

BEGIN
	IF ST_IsEmpty(geom2) THEN
		RETURN ign_gcms_get_empreinte(geom1);
	ELSEIF ST_IsEmpty(geom1) THEN
		RETURN ign_gcms_get_empreinte(geom2);
	ELSE
		SELECT St_Xmin(geom1), St_Xmax(geom1), St_Ymin(geom1), St_Ymax(geom1) INTO xmin1, xmax1, ymin1, ymax1;
		SELECT St_Xmin(geom2), St_Xmax(geom2), St_Ymin(geom2), St_Ymax(geom2) INTO xmin2, xmax2, ymin2, ymax2;
		empreinte := ST_MakeLine(
			ST_MakePoint(least(xmin1,xmin2), least(ymin1,ymin2)), 
			ST_MakePoint(greatest(xmax1,xmax2), greatest(ymax1,ymax2)));
		empreinte := ST_SetSRID(empreinte, ST_SRID(geom1));
		RETURN empreinte;
	END IF;
END
$$
LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Identifie les colonnes de cette table contenant de la géométrie
-- -----------------------------------------------------------------------------
-- Utilisé par ign_gcms_reconcilier.
-- PostGIS pourrait convertir automatiquement le WKT en geometry, mais si un
-- SRID particulier est associé à une colonne geometry, il nous faut pouvoir
-- l'identifier pour récupérer ce SRID et insérer la géométrie en précisant
-- le SRID qui convient.
-- On peut appeler en préfixant par le nom du schéma :
-- SELECT ign_gcms_get_geometry_columns('nom_schema.nom_table').
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_geometry_columns(_table TEXT) RETURNS TEXT[] AS $$
DECLARE
	names TEXT[] := array[]::TEXT[];
	name TEXT;
    st TEXT[];
BEGIN
    -- Decomposition de _table en schema et nom de table
	st := ign_gcms_decompose_table_name( _table );
	FOR name IN SELECT column_name
			FROM information_schema.columns
			WHERE table_schema = st[0] AND table_name = st[1] AND udt_name = 'geometry' LOOP
		names := array_append(names, name);
	END LOOP;
	RETURN names;
END
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
-- Retourne une chaîne de caractères représentant le type géométrique
-- avec sa dimension et son srid (ex. geometry(PolygonZ,2154)).
-- On peut appeler en préfixant par le nom du schéma :
-- SELECT ign_gcms_get_geometry_type('nom_schema.nom_table').
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_geometry_type(_table TEXT, _column TEXT) RETURNS TEXT AS $$
DECLARE
    geomtype_def TEXT;
	st TEXT[];
BEGIN
	-- Decomposition de _table en schema et nom de table
	st := ign_gcms_decompose_table_name( _table );
	IF (ign_gcms_test_column_exists(_table, _column)) THEN
			SELECT 'geometry(' || t.type ||
		    	CASE
		        	WHEN t.coord_dimension = 3 THEN 'Z'
		        	WHEN t.coord_dimension = 4 THEN 'M'
		        	ELSE ''
		    	END || ',' || t.srid || ')'
		    	FROM geometry_columns t
		    	WHERE f_table_schema = st[0] AND f_table_name = st[1] AND f_geometry_column = _column
		    	INTO geomtype_def;
		    RETURN geomtype_def;
		ELSE
			RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = 'On ne peut pas transformer un type non géométrique en géométrie';
	END IF;
END
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
-- Passe d'une colonne géométrique définie par contrainte
-- à une colonne géométrique utilisant les types paramétriques (typmod)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_use_typmod_for_geometry_definition(_table TEXT, _column TEXT) RETURNS VOID AS $$
DECLARE
    geomtype_def TEXT;
BEGIN
	SELECT ign_gcms_get_geometry_type(_table, _column) INTO geomtype_def;
	EXECUTE 'ALTER TABLE ' || _table || ' ALTER COLUMN ' || _column || ' TYPE ' || geomtype_def;
	EXECUTE 'ALTER TABLE ' || _table || ' DROP CONSTRAINT IF EXISTS enforce_dims_' ||  _column ;
	EXECUTE 'ALTER TABLE ' || _table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_' ||  _column ;
	EXECUTE 'ALTER TABLE ' || _table || ' DROP CONSTRAINT IF EXISTS enforce_srid_' ||  _column ;
	-- le champ empreinte a été renommé en gcvs_empreinte, mais le nom des contraintes n'a pas suivi
	IF (_column = 'gcvs_empreinte') THEN
		EXECUTE 'ALTER TABLE ' || _table || ' DROP CONSTRAINT IF EXISTS enforce_dims_empreinte';
    	EXECUTE 'ALTER TABLE ' || _table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_empreinte';
    	EXECUTE 'ALTER TABLE ' || _table || ' DROP CONSTRAINT IF EXISTS enforce_srid_empreinte';
	END IF;
END
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------------ FONCTIONS RELATIVES AUX ID ----------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
-- Gestion centralisée du nom de la colonne portant l'identifiant serveur de 
-- l'objet (utilisé par ign_gcms_reconcilier).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_feature_id_name () RETURNS TEXT AS $$
BEGIN
	RETURN 'objectid';
END
$$ LANGUAGE plpgsql ;


--------------------------------------------------------------------------------
-- Renvoie un UUID ou une cleabs suivant la structure de la base
--
-- -----------------------------------------------------------------------------
-- CAS 1 : la base ne possède ni table dictionnaire, ni table acronymes
-- La fonction renvoie un uuid de type 4
-- -----------------------------------------------------------------------------
-- CAS 2 : la base ne possède qu'une des deux tables dictionnaire et acronymes
-- La fonction renvoie une erreur
-- -----------------------------------------------------------------------------
-- CAS 3 : la base possède les deux tables dictionnaire et acronymes
-- La fonction renvoie une cleabs composée de l'acronyme de la table _table
-- et de la valeur numérique stockée dans la colonne valeur de l'enregistrement
-- de cle prochainecleabsolue
-- Elle incremente ensuite ce champ de la valeur idNumber.
-- -----------------------------------------------------------------------------
--
-- ATTENTION : la transaction appelant cette fonction doit être SERIALIZABLE ou
-- poser un verrou sur la table dictionnaire (LOCK TABLE dictionnaire)
-- Ceci afin d'éviter que deux transactions utilisent la même plage de cleabs.
--
-- VERROU : le verrou posé par une transaction met les autres transactions en 
-- attente. La méthode est simple et sûre, mais moins "efficace" que le mode
-- serializable. En outre, la mauvaise gestion de nombreux verrous peut aboutir 
-- à des situations de deadlock difficiles à deboguer.
--
-- SERIALIZABLE : en mode serializable, le système essaye de commiter les deux
-- actions en même temps. Si le système s'aperçoit que la deuxième transaction 
-- va utiliser une info qui risque d'être modifiée par la première, une 
-- exception est levée. Il est alors possible de relancer la deuxième 
-- transaction, une ou plusieurs fois, ou jusqu'à ce qu'elle aboutisse.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_feature_id( _table regclass , id_number int) 
	RETURNS text AS $$
DECLARE
	acro text ;
	requete text ;
	valeur_txt text;
	prochaine_cleabs text;
	LENGTH_NUMERIC_PART_CLEABS int DEFAULT 16; -- C'est une constante
	st text[];

BEGIN
	
	-- Vérifie la présence du dictionnaire et des acronymes
	IF NOT EXISTS ( SELECT 1 FROM pg_class WHERE  pg_class.relname = 'dictionnaire' ) AND
		NOT EXISTS ( SELECT 1 FROM pg_class WHERE  pg_class.relname = 'acronymes' ) THEN
		-- Si les deux tables dictionnaire et acronymes sont absentes, on renvoie un UUID 
		RETURN ign_gcms_generate_uuid()::text;
	ELSEIF NOT EXISTS ( SELECT 1 FROM pg_class WHERE  pg_class.relname = 'dictionnaire' ) OR
		NOT EXISTS ( SELECT 1 FROM pg_class WHERE  pg_class.relname = 'acronymes' ) THEN
		RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = 'Une des tables ''dictionnaire'' ou ''acronymes'' est absente';
	END IF;
	
	IF id_number < 1 THEN
		RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = 'Il faut incrémenter le dictionnaire de 1 minimum';
	END IF;


	SELECT valeur FROM dictionnaire WHERE cle = 'prochainecleabsolue' INTO valeur_txt;
	IF valeur_txt = '-1' THEN
		RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = 'La clé prochainecleabsolue de la table dictionnaire n''est pas définie';
	END IF;
	
	-- Gestion de la BD Topo : si le nom de la table contient un nom de schéma, on l'enlève
	st := ign_gcms_decompose_table_name( _table );
	
	requete := 'SELECT acronyme FROM acronymes WHERE nom_table = ''' || st[1] || '''';
	EXECUTE requete INTO acro ;
	IF (acro IS NULL) THEN
		acro := '';
	END IF;
	
	SELECT lpad ((valeur_txt::bigint + id_number )::text, LENGTH_NUMERIC_PART_CLEABS, '0') INTO prochaine_cleabs;
	UPDATE dictionnaire SET valeur = prochaine_cleabs WHERE cle = 'prochainecleabsolue';
	RETURN acro || valeur_txt;
END
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
-- Renvoie un UUID ou une cleabs suivant la structure de la base.
--
-- On peut appeler en préfixant par le nom du schéma :
-- (SELECT ign_gcms_get_feature_id('nom_schema.nom_table').
--
-- -----------------------------------------------------------------------------
-- CAS 1 : la base ne possède ni table dictionnaire, ni table acronymes
-- La fonction renvoie un uuid de type 4
-- -----------------------------------------------------------------------------
-- CAS 2 : la base ne possède qu'une des deux tables dictionnaire et acronymes
-- La fonction renvoie une erreur
-- -----------------------------------------------------------------------------
-- CAS 3 : la base possède les deux tables dictionnaire et acronymes
-- La fonction renvoie une cleabs composée de l'acronyme de la table _table
-- et de la valeur numérique stockée dans la colonne valeur de l'enregistrement
-- de cle prochainecleabsolue
-- Elle incremente ensuite ce champ de 1
-- -----------------------------------------------------------------------------
--
-- ATTENTION : la transaction appelant cette fonction doit être SERIALIZABLE ou
-- poser un verrou sur la table dictionnaire (LOCK TABLE dictionnaire)
-- Ceci afin d'éviter que deux transactions utilisent la même plage de cleabs.
--
-- VERROU : le verrou posé par une transaction met les autres transactions en 
-- attente. La méthode est simple et sûre, mais moins "efficace" que le mode
-- serializable. En outre, la mauvaise gestion de nombreux verrous peut aboutir 
-- à des situations de deadlock difficiles à deboguer.
--
-- SERIALIZABLE : en mode serializable, le système essaye de commiter les deux
-- actions en même temps. Si le système s'aperçoit que la deuxième transaction 
-- va utiliser une info qui risque d'être modifiée par la première, une 
-- exception est levée. Il est alors possible de relancer la deuxième 
-- transaction, une ou plusieurs fois, ou jusqu'à ce qu'elle aboutisse.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_feature_id( _table regclass ) 
	RETURNS text AS $$
BEGIN
	RETURN ign_gcms_get_feature_id(_table, 1);
END
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
-- Renvoie un uuid de type 4
--------------------------------------------------------------------------------
-- Nécessite d'installer l'extension  uuid-ossp
-- (utiliser des doubles-quotes et non des simples cotes)
-- CREATE EXTENSION "uuid-ossp";
--------------------------------------------------------------------------------
-- L'installation de l'extension uuid-ossp est un pré-requis mais elle
-- necessite les droits administrateur (cf. GCMS_ADMIN.SQL)
--CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE OR REPLACE FUNCTION ign_gcms_generate_uuid() RETURNS uuid AS $$
        SELECT uuid_generate_v4() AS uuid ;
$$ LANGUAGE sql ;


-- -----------------------------------------------------------------------------
-- Renvoie la prochaine valeur d'une séquence ou -1 si nextval() = 0
-- -----------------------------------------------------------------------------
-- (comme la fonction nextval, mais renvoie -1 au lieu de 0)
-- QUESTION : dans quel cas nextval renvoie 0 ? Cette fonction ne semble servir
-- qu'à gérer ce cas en renvoyant -1 à la place de 0.
-- Utilisé par ign_gcms_finalize_transaction et ign_gcms_reconcilier
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_next_val(nom_sequence text) 
	RETURNS integer AS $BODY$

DECLARE
 	new_valeur integer;

BEGIN

	new_valeur := -1;
	new_valeur := nextval(nom_sequence);
	IF new_valeur = 0 THEN
		new_valeur := -1 ;
	END IF ;
	
	RETURN new_valeur;

END
$BODY$
LANGUAGE plpgsql ;


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------------------- FONCTIONS DE MANIPULATION DE JSON -------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Utilitaire pour ajouter une paire clé/valeur à un JSON
-- -----------------------------------------------------------------------------
-- @Deprecated
-- Fonction créée pour ajouter une cleabs à l'action dans le cas d'un INSERT
-- C'est finalement le client qui se charge d'ajouter la cleabs à l'action.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_add_key_value_to_json(_json JSON, key_to_set TEXT, value_to_set ANYELEMENT)
  RETURNS JSON LANGUAGE sql IMMUTABLE STRICT AS $function$
SELECT concat('{', string_agg(to_json("key") || ':' || "value", ','), '}')::json
  FROM (SELECT *
	FROM json_each(_json)
	WHERE key <> key_to_set
	UNION ALL
	SELECT key_to_set, to_json(value_to_set)) AS "fields"
$function$;


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------------------------- FONCTIONS SUR LES TRIGGERS --------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Verifie qu'un trigger sur une table existe.
-- On peut appeler en préfixant par le nom du schéma :
-- SELECT ign_gcms_trigger_exists('nom_schema.nom_table','triggername').
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_trigger_exists (_table text, _triggername text)
    RETURNS boolean AS $$
DECLARE
    table_oid INTEGER;
    rg regclass; 
BEGIN
    IF current_setting('server_version_num')::integer < 90600 THEN
        rg := to_regclass(_table::cstring);
    ELSE
        rg := to_regclass(_table);
    END IF;

    IF NOT ign_gcms_test_table_exists(_table) THEN
        RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = FORMAT('Table %s does not exist', _table);
    END IF;
    
    SELECT oid FROM pg_class WHERE oid = rg INTO table_oid;
    RETURN (SELECT EXISTS(SELECT * FROM pg_trigger WHERE NOT tgisinternal AND tgname = _triggername AND tgrelid = table_oid));
END
$$ LANGUAGE plpgsql;



-- -----------------------------------------------------------------------------
-- Verifie qu'un trigger sur une table existe ET est actif
-- On peut appeler en préfixant par le nom du schéma :
-- SELECT ign_gcms_trigger_exists_enable('nom_schema.nom_table','triggername').
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_trigger_exists_enable (_table text, _triggername text)
    RETURNS boolean AS $$
DECLARE
	_tgenabled TEXT DEFAULT NULL;
	st TEXT[];
	
BEGIN

	-- Decomposition de _table en schema et nom de table
	st := ign_gcms_decompose_table_name( _table );
	
	EXECUTE format ('
		SELECT tgenabled FROM pg_trigger 
		JOIN pg_class ON (pg_class.oid=pg_trigger.tgrelid) 
		JOIN pg_namespace ON pg_namespace.oid=pg_class.relnamespace
		WHERE pg_class.relname = ''%s''
		AND pg_namespace.nspname = ''%s''
		AND pg_trigger.tgname = ''%s''', st[1], st[0], _triggername)
	INTO _tgenabled ;
	
	IF _tgenabled IS NULL OR _tgenabled <> 'O' THEN
		RETURN false ;
	END IF;

	RETURN true;

END
$$ LANGUAGE plpgsql;



-- ----------------------------------------------------------------------------
-- FONCTIONS PERMETTANT DE PASSER UNE GÉOMÉTRIE EN 3D (XYZ).
-- Si la géométrie en entrée est en 2D, la valeur z passée en paramètre est ajoutée à tous les points.
-- Si la géométrie en entrée est en 3D, la fonction la renvoie à l'identique.
-- 
-- Doit faire la même chose que la fonction ST_Force3D qui depuis PostGIS 3.1 permet de passer une valeur en paramètre.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.ign_ST_Force3D(src geometry, z float)
    RETURNS geometry
AS $$
    DECLARE
    BEGIN
	    IF (ST_CoordDim(src) = 3)
            THEN RETURN src;
        END IF;
        IF (ST_GeometryType(src) = 'ST_Point')
            THEN RETURN ign_ST_Force3D_on_point(src, z);
        END IF;
        IF (ST_GeometryType(src) = 'ST_LineString')
            THEN RETURN ign_ST_Force3D_on_linestring(src, z);
        END IF;
        IF (ST_GeometryType(src) = 'ST_Polygon')
            THEN RETURN ign_ST_Force3D_on_polygon(src, z);
        END IF;
        IF (ST_GeometryType(src) = 'ST_MultiPoint')
            THEN RETURN ign_ST_Force3D_on_multipoint(src, z);
        END IF;
        IF (ST_GeometryType(src) = 'ST_MultiLineString')
            THEN RETURN ign_ST_Force3D_on_multilinestring(src, z);
        END IF;
        IF (ST_GeometryType(src) = 'ST_MultiPolygon')
            THEN RETURN ign_ST_Force3D_on_multipolygon(src, z);
        END IF;
        IF (ST_GeometryType(src) = 'ST_GeometryCollection')
            THEN RETURN ign_ST_Force3D_on_geometrycollection(src, z);
        END IF;
		RAISE EXCEPTION 'Fonction ign_ST_Force3D : type géométrique non reconnu : %', ST_GeometryType(src);
    END;
$$ LANGUAGE plpgsql;

-- test
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromEWKT('TIN (((0 0 0, 0 0 1, 0 1 0, 0 0 0)), ((0 0 0, 0 1 0, 1 1 0, 0 0 0)))'), -1000.)); 	--> Exception


CREATE OR REPLACE FUNCTION public.ign_ST_Force3D_on_point(src geometry, z float)
    RETURNS geometry
AS $$
    DECLARE
    BEGIN
        IF (ST_GeometryType(src) <> 'ST_Point')
            THEN RAISE EXCEPTION 'La géométrie source n''est pas un point : %', ST_AsText(src);
        END IF;
        IF (ST_CoordDim(src) = 3)
            THEN RETURN src;
        END IF;
        RETURN ST_MakePoint(ST_X(src),ST_Y(src),z);
    END;
$$ LANGUAGE plpgsql;

-- test
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('POINT(0 0 12)'), -1000.)); 	--> POINT Z (0 0 12)
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('POINT(1 1)'), -1000.));		--> POINT Z (1 1 -1000)


CREATE OR REPLACE FUNCTION public.ign_ST_Force3D_on_linestring(src geometry, z float)
    RETURNS geometry
AS $$
    DECLARE
        coordinates geometry[];
    BEGIN
        IF (ST_GeometryType(src) <> 'ST_LineString')
            THEN RAISE EXCEPTION 'La géométrie source n''est pas une ligne : %', ST_AsText(src);
        END IF;
        IF (ST_CoordDim(src) = 3)
            THEN RETURN src;
        END IF;
        FOR i IN 1 .. ST_NPoints(src)
        LOOP
            coordinates := array_append(coordinates, ign_ST_Force3D_on_point(ST_PointN(src, i), z));
        END LOOP;
        RETURN ST_MakeLine(coordinates);
    END;
$$ LANGUAGE plpgsql;

-- test
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('LINESTRING(0 0 1, 0 0 2, 0 0 3)'), 500)); 	--> LINESTRING Z (0 0 1,0 0 2,0 0 3)
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('LINESTRING(0 0, 1 1, 2 2)'), -1000.));		--> LINESTRING Z (0 0 -1000,1 1 -1000,2 2 -1000)


CREATE OR REPLACE FUNCTION public.ign_ST_Force3D_on_polygon(src geometry, z float)
    RETURNS geometry
AS $$
    DECLARE
        exterior geometry;
        holes geometry[];
    BEGIN
        IF (ST_GeometryType(src) <> 'ST_Polygon')
            THEN RAISE EXCEPTION 'La géométrie source n''est pas un polygone : %', ST_AsText(src);
        END IF;
        IF (ST_CoordDim(src) = 3)
            THEN RETURN src;
        END IF;
        exterior := ign_ST_Force3D_on_linestring(ST_ExteriorRing(src), z);
        FOR i IN 1 .. ST_NumInteriorRings(src)
        LOOP
            holes := array_append(holes, ign_ST_Force3D_on_linestring(ST_InteriorRingN(src, i), z));
        END LOOP;
        IF (holes IS NULL) THEN
            RETURN ST_MakePolygon(exterior);
        ELSE
            RETURN ST_MakePolygon(exterior, holes);
        END IF;
    END;
$$ LANGUAGE plpgsql;

-- avec trou
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('POLYGON((0 0 1, 0 0 2, 0 0 3, 0 0 1), (0 0 9, 0 0 9, 0 0 9, 0 0 9))'), -500));	--> POLYGON Z ((0 0 1,0 0 2,0 0 3,0 0 1),(0 0 9,0 0 9,0 0 9,0 0 9))
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 1), (1.1 1.1, 1.9 1.01, 1.9 1.9, 1.1 1.1))'), 122.5));--> POLYGON Z ((1 1 122.5,2 1 122.5,2 2 122.5,1 1 122.5),(1.1 1.1 122.5,1.9 1.01 122.5,1.9 1.9 122.5,1.1 1.1 122.5))

-- sans trou
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('POLYGON((0 0 1, 0 0 2, 0 0 3, 0 0 1))'), 200)); --> POLYGON Z ((0 0 1,0 0 2,0 0 3,0 0 1))
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 1))'), 200)); --> POLYGON Z ((1 1 200,2 1 200,2 2 200,1 1 200))


CREATE OR REPLACE FUNCTION public.ign_ST_Force3D_on_multipoint(src geometry, z float)
    RETURNS geometry
AS $$
    DECLARE
        coordinates geometry[];
    BEGIN
        IF (ST_GeometryType(src) <> 'ST_MultiPoint')
            THEN RAISE EXCEPTION 'La géométrie source n''est pas un multipoint : %', ST_AsText(src);
        END IF;
        IF (ST_CoordDim(src) = 3)
            THEN RETURN src;
        END IF;
        FOR i IN 1 .. ST_NumGeometries(src)
        LOOP
            coordinates := array_append(coordinates, ign_ST_Force3D_on_point(ST_GeometryN(src, i), z));
        END LOOP;
        RETURN ST_Points(ST_MakeLine(coordinates));
    END;
$$ LANGUAGE plpgsql;

-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('MultiPoint((0 0 1), (0 0 2), (0 0 3), (0 0 1))'), 5));  --> MULTIPOINT Z (0 0 1,0 0 2,0 0 3,0 0 1)
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('MultiPoint((1 1), (2 1), (2 2), (1 1))'), -500));		--> MULTIPOINT Z (1 1 -500,2 1 -500,2 2 -500,1 1 -500)


CREATE OR REPLACE FUNCTION public.ign_ST_Force3D_on_multilinestring(src geometry, z float)
    RETURNS geometry
AS $$
    DECLARE
        lines geometry[];
    BEGIN
        IF (ST_GeometryType(src) <> 'ST_MultiLineString')
            THEN RAISE EXCEPTION 'La géométrie source n''est pas une multilignes : %', ST_AsText(src);
        END IF;
        IF (ST_CoordDim(src) = 3)
            THEN RETURN src;
        END IF;
        FOR i IN 1 .. ST_NumGeometries(src)
        LOOP
            lines := array_append(lines, ign_ST_Force3D_on_linestring(ST_GeometryN(src, i), z));
        END LOOP;
        RETURN ST_Collect(lines);
    END;
$$ LANGUAGE plpgsql;

-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('MultiLineString((0 0 1, 0 0 2), (0 0 3, 0 0 4))'), 100)); 	--> MULTILINESTRING Z ((0 0 1,0 0 2),(0 0 3,0 0 4))
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('MultiLineString((1 1, 2 1), (2 2, 1 1))'), -1000.));		--> MULTILINESTRING Z ((1 1 -1000,2 1 -1000),(2 2 -1000,1 1 -1000))


CREATE OR REPLACE FUNCTION public.ign_ST_Force3D_on_multipolygon(src geometry, z float)
    RETURNS geometry
AS $$
    DECLARE
        polygones geometry[];
    BEGIN
        IF (ST_GeometryType(src) <> 'ST_MultiPolygon')
            THEN RAISE EXCEPTION 'La géométrie source n''est pas un multipolygone : %', ST_AsText(src);
        END IF;
        IF (ST_CoordDim(src) = 3)
            THEN RETURN src;
        END IF;
        FOR i IN 1 .. ST_NumGeometries(src)
        LOOP
            polygones := array_append(polygones, ign_ST_Force3D_on_polygon(ST_GeometryN(src, i), z));
        END LOOP;
        RETURN ST_Collect(polygones);
    END;
$$ LANGUAGE plpgsql;

-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('MultiPolygon(((0 0 1, 0 0 2, 0 0 3, 0 0 1), (0 0 9, 0 0 9, 0 0 9, 0 0 9)), ((0 0 1, 0 0 2, 0 0 3, 0 0 1), (0 0 9, 0 0 9, 0 0 9, 0 0 9)))'), 1000)); --> MULTIPOLYGON Z (((0 0 1,0 0 2,0 0 3,0 0 1),(0 0 9,0 0 9,0 0 9,0 0 9)),((0 0 1,0 0 2,0 0 3,0 0 1),(0 0 9,0 0 9,0 0 9,0 0 9)))
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('MultiPolygon(((9 9, 9 9, 9 9, 9 9), (9 9, 9 9, 9 9, 9 9)), ((9 9, 9 9, 9 9, 9 9), (9 9, 9 9, 9 9, 9 9)))'), 1000)); --> MULTIPOLYGON Z (((9 9 1000,9 9 1000,9 9 1000,9 9 1000),(9 9 1000,9 9 1000,9 9 1000,9 9 1000)),((9 9 1000,9 9 1000,9 9 1000,9 9 1000),(9 9 1000,9 9 1000,9 9 1000,9 9 1000)))


CREATE OR REPLACE FUNCTION public.ign_ST_Force3D_on_geometrycollection(src geometry, z float)
    RETURNS geometry
AS $$
    DECLARE
        geoms geometry[];
    BEGIN
        IF (ST_GeometryType(src) <> 'ST_GeometryCollection')
            THEN RAISE EXCEPTION 'La géométrie source n''est pas une geometry collection : %', ST_AsText(src);
        END IF;
        IF (ST_CoordDim(src) = 3)
            THEN RETURN src;
        END IF;
        FOR i IN 1 .. ST_NumGeometries(src)
        LOOP
            geoms := array_append(geoms, ign_ST_Force3D(ST_GeometryN(src, i), z));
        END LOOP;
        RETURN ST_Collect(geoms);
    END;
$$ LANGUAGE plpgsql;

-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('GEOMETRYCOLLECTION(POINT(2 0 0),POLYGON((0 0 0, 1 0 0, 1 1 0, 0 1 0, 0 0 0)))'), 500)); --> GEOMETRYCOLLECTION Z (POINT Z (2 0 0),POLYGON Z ((0 0 0,1 0 0,1 1 0,0 1 0,0 0 0)))
-- SELECT ST_AsText(ign_ST_Force3D(ST_GeomFromText('GEOMETRYCOLLECTION(POINT(2 0),POLYGON((0 0, 1 0, 1 1, 0 1, 0 0)))'), 500));  --> GEOMETRYCOLLECTION Z (POINT Z (2 0 500),POLYGON Z ((0 0 500,1 0 500,1 1 500,0 1 500,0 0 500)))

