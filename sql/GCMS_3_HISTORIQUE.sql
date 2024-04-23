--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------------- GESTION DE L'HISTORIQUE ------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------- STRUCTURE ------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Ajoute la table_h pour l'historique
-- Cette fonction suppose que les attributs ajoutés par la fonction
-- ign_gcms_history_table_modifier ont déjà été ajoutés (notamment la cleabs)
-- (appelée par ign_gcms_create_history_triggers).
-- A appeler avec le nom du schéma :
-- SELECT ign_gcms_create_history_table('nom_schema.nom_table') - nom schéma optionnel si schéma public
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_create_history_table( _table regclass ) RETURNS void AS $$
DECLARE
    schema_table text[];
    nom_table text;
    nom_schema text;
    nom_table_h text;
    nom_schema_table_h text;
    old_primary_key record;
    geometry_name text;
BEGIN

    schema_table := ign_gcms_decompose_table_name(_table);
    nom_schema := schema_table[0];
    nom_table := schema_table[1];
    nom_table_h := quote_ident(nom_table || '_h');
    nom_schema_table_h := quote_ident(nom_schema) || '.' || nom_table_h;

    -- Test existence table _h
    IF EXISTS (
        SELECT 1 FROM pg_class, pg_namespace
        WHERE  pg_class.relname = nom_table_h
        AND pg_class.relnamespace = pg_namespace.oid
        AND pg_namespace.nspname = quote_ident(nom_schema)
    ) THEN
        RETURN;
    END IF;

    SELECT tc.constraint_name AS name, cu.column_name AS column FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE cu
    ON cu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
    WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
    AND tc.TABLE_SCHEMA = quote_ident(nom_schema)
    AND tc.TABLE_NAME = quote_ident(nom_table)
    INTO old_primary_key;

    SELECT column_name FROM information_schema.columns
    WHERE table_schema = quote_ident(nom_schema)
    AND table_name = nom_table
    AND udt_name LIKE '%geom%'
    LIMIT 1 INTO geometry_name;

    EXECUTE $x$
        -- Creation table historique sur le modèle de la table principale avec un champ supplémentaire numrecmodif
        CREATE TABLE $x$ || nom_schema_table_h || $x$ AS TABLE $x$ || _table || $x$  WITH NO DATA;
        ALTER TABLE $x$ || nom_schema_table_h || $x$ ADD COLUMN gcms_numrecmodif integer;
        ALTER TABLE $x$ || nom_schema_table_h || $x$ DROP CONSTRAINT IF EXISTS $x$ || old_primary_key.name || $x$;
        ALTER TABLE $x$ || nom_schema_table_h || $x$ ALTER COLUMN $x$ || old_primary_key.column || $x$ DROP NOT NULL;
        ALTER TABLE $x$ || nom_schema_table_h || $x$ ADD CONSTRAINT $x$ || nom_table || $x$_h_pkey PRIMARY KEY (objectid, gcms_numrec);
        CREATE INDEX $x$ || quote_ident('index_gcms_numrec_' || lower(nom_table_h)) || $x$ ON $x$ || nom_schema_table_h || $x$ USING btree(gcms_numrec);
        CREATE INDEX $x$ || quote_ident('index_gcms_numrecmodif_' || lower(nom_table_h)) || $x$ ON $x$ || nom_schema_table_h || $x$ USING btree(gcms_numrecmodif);
        CREATE INDEX $x$ || quote_ident('index_geometry_' || lower(nom_table_h)) || $x$ ON $x$ || nom_schema_table_h || $x$ USING Gist( $x$ || geometry_name || $x$ );
    $x$ ;

END
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
-- Supprime la table_h pour l'historique
-- ign_gcms_history_table_modifier ont déjà été ajoutés (notamment la cleabs)
-- (appelée par ign_gcms_create_history_triggers).
-- A appeler avec le nom du schéma :
-- SELECT ign_gcms_drop_history_table('nom_schema.nom_table') - nom schéma optionnel si schéma public
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_drop_history_table( _table TEXT ) RETURNS void AS $$
DECLARE
    schema_table text[];
    nom_table text;
    nom_schema text;
    nom_table_h text;
    nom_schema_table_h text;
BEGIN

    schema_table := ign_gcms_decompose_table_name(_table);
    nom_schema := schema_table[0];
    nom_table := schema_table[1];
    nom_table_h := quote_ident(nom_table || '_h');
    nom_schema_table_h := quote_ident(nom_schema) || '.' || nom_table_h ;

    -- Test existence table _h
    IF NOT EXISTS (
    	SELECT 1 FROM pg_class, pg_namespace
    	WHERE  pg_class.relname = nom_table_h
    	AND pg_class.relnamespace = pg_namespace.oid
    	AND pg_namespace.nspname = quote_ident(nom_schema)
    ) THEN
    	RAISE NOTICE 'La table % du schéma % n''existe pas', nom_table_h, nom_schema;
    	RETURN;
    END IF;


    EXECUTE $x$
    	-- Suprresion table historique
    	DROP TABLE $x$ || nom_schema_table_h || $x$;
    $x$ ;

END
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
-- Ajoute les colonnes nécessaires pour gérer l'historique
-- (appelée par ign_gcms_create_history_triggers)
-- La table reconciliations et les séquences associées doivent exister (fonction ign_gcms_create_reconciliations_table)
-- Une insertion est faite dans la table dans la reconciliation, et les gcms_numrec portent le numrec de cette réconciliation (avec numclient= -1).
-- A appeler avec le nom du schéma :
-- SELECT ign_gcms_history_table_modifier('nom_schema.nom_table') - nom schéma optionnel si schéma public
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_history_table_modifier( _table regclass ) RETURNS void AS $$
DECLARE
	flag_trigger boolean DEFAULT false;
	table_name text;
    pkey_constraint text;
	next_numrec integer;
	next_ofe integer;
	nb_objets integer;
	requete_nom text;
BEGIN
	-- Test existence colonne gcms_numrec : si elle existe on considère que les colonnes de
	-- l'historique existent déjà toutes, on sort
	IF (ign_gcms_test_column_exists(_table::text, 'gcms_numrec')) THEN RETURN;
	END IF;

	SELECT relname INTO table_name FROM pg_class
		WHERE pg_class.oid = _table ;

	-- On désactive les trigger de gestion des conflits sinon cela va créer des conflits
	IF EXISTS (
		SELECT 1 FROM pg_trigger
		WHERE tgrelid = _table
		AND tgname = 'ign_gcms_conflict_trigger'
	) THEN

		EXECUTE $x$
			ALTER TABLE $x$ || _table || $x$ DISABLE TRIGGER ign_gcms_conflict_trigger;
		$x$;
		flag_trigger := true;
	END IF;

    pkey_constraint := FORMAT('%s_pkey',table_name);
	requete_nom := FORMAT ('Initialisation de l''''historique de la table : %s',table_name);

	SELECT INTO next_numrec nextval('seqnumrec');
	SELECT INTO next_ofe nextval('seqnumordrefinevol');
	EXECUTE $x$
		SELECT COUNT(*)  FROM $x$ || _table || $x$;
	$x$ INTO nb_objets;

	EXECUTE $x$
        -- drop primary key constraint
        --ALTER TABLE $x$ || _table || $x$ DROP CONSTRAINT IF EXISTS $x$ || pkey_constraint || $x$;
		-- add cleabs column to table
		--ALTER TABLE $x$ || _table || $x$ ADD COLUMN objectid text;
		--UPDATE $x$ || _table || $x$ SET objectid = ign_gcms_generate_uuid();
		--ALTER TABLE $x$ || _table || $x$ ADD PRIMARY KEY (objectid);
		-- reconciliation table must have been created (function ign_gcms_create_reconciliations_table)
		INSERT INTO reconciliations (ordrefinevol, numrec, numclient, classesimpactees, daterec,
									nom, changement, nature_operation, date_du_dernier_controle,
									incoherences_detectees, commentaire, est_une_montee_en_base,
									geometrie, dureerec, nbobjrec,
									operateur, version_gcvs, profil) 
		VALUES ($x$ || next_ofe || $x$, $x$ || next_numrec || $x$,
							-1, null, now(), '$x$ || requete_nom || $x$',
							null, 'MAJ_GE', null, null, null, null,
							ST_GeomFromText('MultiPolygon(((9 9, 9 9, 9 9, 9 9)))'),
							null, $x$ || nb_objets || $x$, null, null,
							'Opération automatique lors de l''installation de la structure historique');
		-- add column gcms_numrec to table, with numrec
		ALTER TABLE $x$ || _table || $x$ ADD COLUMN gcms_numrec integer DEFAULT $x$ || next_numrec || $x$;
		ALTER TABLE $x$ || _table || $x$ ALTER COLUMN gcms_numrec DROP DEFAULT;
		CREATE INDEX $x$ || quote_ident('index_gcms_numrec_' || lower(table_name)) || $x$ ON $x$ || _table || $x$ USING btree(gcms_numrec);
		--add column gcms_detruit to table
		ALTER TABLE $x$ || _table || $x$ ADD COLUMN gcms_detruit boolean DEFAULT false;
		--ALTER TABLE $x$ || _table || $x$ ALTER COLUMN gcms_detruit SET DEFAULT false;
		ALTER TABLE $x$ || _table || $x$ ALTER COLUMN gcms_detruit SET NOT NULL;
		-- add column date_creation to table
		ALTER TABLE $x$ || _table || $x$ ADD COLUMN gcms_date_creation timestamp without time zone ;
		-- add column date_modification to table
		ALTER TABLE $x$ || _table || $x$ ADD COLUMN gcms_date_modification timestamp without time zone ;
		-- add column date_destruction to table
		ALTER TABLE $x$ || _table || $x$ ADD COLUMN gcms_date_destruction timestamp without time zone ;
    $x$;

	-- On réactive les triggers de gestion des conflits s'ils existaient
	IF (flag_trigger) THEN
		EXECUTE $x$
			ALTER TABLE $x$ || _table || $x$ ENABLE TRIGGER ign_gcms_conflict_trigger;
		$x$;
	END IF;

END
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
-- Crée les tables et séquences utiles aux réconciliations si elles n'existent pas
-- ATTENTION : an BDUniV2, la séquence ne devra pas commencer à 0 mais à
-- 20 000 000 (après avoir vérifié que ça suffisait)
-- Tout est crée dans le schéma public.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_create_reconciliations_table() RETURNS void AS $$

BEGIN

	IF NOT EXISTS (
		SELECT 1 FROM pg_class
		WHERE  relname = 'reconciliations'
	) THEN

		CREATE TABLE reconciliations
		(
			numrec integer NOT NULL,
			ordrefinevol integer NOT NULL,
			numclient integer,
			daterec timestamp without time zone,
			operateur character varying COLLATE pg_catalog."default",
			nature_operation character varying COLLATE pg_catalog."default",
			est_une_montee_en_base boolean,
			dureerec double precision,
			nbobjrec integer,
			classesimpactees character varying COLLATE pg_catalog."default",
			date_du_dernier_controle date,
			incoherences_detectees integer,
			profil character varying COLLATE pg_catalog."default",
			version_gcvs character varying COLLATE pg_catalog."default",
			nom character varying COLLATE pg_catalog."default",
			changement character varying COLLATE pg_catalog."default",
			commentaire character varying COLLATE pg_catalog."default",
			geometrie geometry(MultiPolygon) NOT NULL,
			source character varying COLLATE pg_catalog."default",
			CONSTRAINT index_reconciliations_ordrefinevol PRIMARY KEY (ordrefinevol),
			CONSTRAINT numrec_unique UNIQUE (numrec),
			CONSTRAINT enforce_dims_geometrie CHECK (st_ndims(geometrie) = 2),
			CONSTRAINT enforce_geotype_geometrie CHECK (geometrytype(geometrie) = 'MULTIPOLYGON'::text OR geometrie IS NULL)
		);

		CREATE INDEX index_numclient_reconciliations ON reconciliations USING btree (numclient);
		CREATE INDEX index_numrec_reconciliations ON reconciliations USING btree (numrec);

	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM pg_class
		WHERE  relname = 'seqnumrec'
	) THEN
		CREATE SEQUENCE seqnumrec
		  INCREMENT 1
		  MINVALUE 1
		  MAXVALUE 9223372036854775807
		  START 1
		  CACHE 1;
	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM pg_class
		WHERE  relname = 'seqnumordrefinevol'
	) THEN
		CREATE SEQUENCE seqnumordrefinevol
		  INCREMENT 1
		  MINVALUE 1
		  MAXVALUE 9223372036854775807
		  START 1
		  CACHE 1;
	END IF;


	IF NOT EXISTS (
		SELECT 1 FROM pg_class
		WHERE  relname = 'gcvs_lockfinevol'
	) THEN
		CREATE TABLE gcvs_lockfinevol (a integer);
	END IF;
	IF NOT EXISTS (
		SELECT 1 FROM gcvs_lockfinevol WHERE a=1
	) THEN
		INSERT INTO gcvs_lockfinevol(a) VALUES (1);
	END IF;

END
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------------------------- TRIGGER DE MIS A JOUR -------------------------------
-------------------------- ET FONCTIONS ANNEXES --------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- FONCTION TRIGGER POUR GERER l'HISTORIQUE ------------------------------------
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ign_gcms_history_trigger_function()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$

DECLARE
	max_numrec integer;
    tablename TEXT;
	curr_numrec integer;
BEGIN

	curr_numrec := nextval('seqnumrec');
	
	-- UPDATE
	IF (TG_OP = 'UPDATE') THEN

		-- Le champ gcms_detruit booleen est obligatoire (contrainte dans la base de données).
		-- Si le client propose une mise à jour dans laquelle ce champ est vide, on
		-- remplace le NULL par FALSE
		IF (NEW.gcms_detruit IS NULL) THEN
		    NEW.gcms_detruit = FALSE;
		END IF;

		-- BIFURCATION ENTRE LE FONCTIONNEMENT "A L'ANCIENNE" ET LE NOUVEAU CODE
		-- Si le numrec est fourni dans la requête ET qu'il est supérieur au numrec en base
		-- alors la requête vient d'un client GCVS classique, pas besoin du trigger
		IF (NEW.gcms_numrec > OLD.gcms_numrec) THEN
			RETURN NEW;
		END IF;

		-- A contrario si le gcms_numrec a baissé, il y a un problème
		IF (NEW.gcms_numrec < OLD.gcms_numrec) THEN
			RAISE EXCEPTION
			    'GCMS ECHEC MISE A JOUR : Le numéro de réconciliation fourni est incohérent : % < %',
			    NEW.gcms_numrec, OLD.gcms_numrec
			    USING ERRCODE = '77778';
			RETURN NULL;
		END IF;

		-- Le cas général (non-gcvs) que gcms doit gérer est le cas où gcms_numrec n'est pas fourni
		-- Mise à jour de gcms_numrec
		NEW.gcms_numrec := currval('seqnumrec');

		-- Si le gcms_numrec de la séquence est < numrec de l'objet courant, il y a problème !
		IF (NEW.gcms_numrec < OLD.gcms_numrec) THEN
			RAISE EXCEPTION
			    'GCMS ECHEC MISE A JOUR : Le numéro fourni par la séquence seqnumrec est trop petit : % < %',
			    NEW.gcms_numrec, OLD.gcms_numrec
			    USING ERRCODE = '77778';
			RETURN NULL;
		END IF;

		-- 2017-03-09 : on autorise la modification du champ gcms_detruit par le trigger,
		-- car c'est le seul moyen de récupérer un objet accidentellement detruit.
		-- IF (OLD.gcms_detruit) THEN
		-- 	RAISE EXCEPTION SQLSTATE '77778' USING MESSAGE = 'GCMS ECHEC UPDATE ou DELETE : Tentative de mise à jour d''un objet détruit';
		-- END IF;

		-- Ajout dans la table historique
        tablename := quote_ident(TG_TABLE_SCHEMA::text) || '.' || quote_ident(TG_TABLE_NAME::text) ;
		-- 2022-06-19 : on distingue 
		--     - le premier update de la réconciliation (changement de numrec) qui déclenche la recopie
		--       de la version d'origine dans l'historique. Le numrec aura été initialisé par la ligne
		--        NEW.gcms_numrec := currval('seqnumrec') ; donc le test IF NEW.gcms_numrec > OLD.gcms_numrec est TRUE
		--     - les updates suivants (conservation du numrec) qui n'ont plus d'action dans l'historique
		--        car dans ce cas on NEW.gcms_numrec = OLD.gcms_numrec ( = currval('seqnumrec') )
		IF NEW.gcms_numrec > OLD.gcms_numrec THEN

		    PERFORM ign_gcms_add_to_history_table (tablename, OLD.objectid::text, currval('seqnumrec')::integer);

		    -- Cas d'un UPDATE qui est en réalité un DELETE (gcms_detruit est vrai)
			-- 2022-06-19 : Seul l'update d'origine peut effectuer une suppression. 
			-- Un trigger ne peut supprimer (passer gcms_detruit à vrai) un objet mis à jour par l'utilisateur
		    IF (NEW.gcms_detruit) THEN
			    NEW.gcms_date_destruction := now();
			    RETURN NEW;
		    ELSE
			    NEW.gcms_date_destruction := NULL;
		    END IF;

		    -- Cas d'un vrai UPDATE
			-- 2022-06-19 : les updates déclenchés par un trigger ne doivent pas mettre à jour 
			-- gcms_date_modification car l'opération qui les a déclenché peut être un INSERT
		    NEW.gcms_date_modification := now();
			-- Empreinte pour compatibilité GCVS ; dans ce cas la colonne géométrique s'appele "geometrie"
			IF (ign_gcms_test_column_exists(TG_RELID, 'gcvs_empreinte')) THEN
				SELECT ign_gcms_get_empreinte (OLD.gcvs_empreinte, NEW.geometrie) INTO NEW.gcvs_empreinte ;
			END IF;
		END IF; -- IF NEW.gcms_numrec > OLD.gcms_numrec

		RETURN NEW;

	END IF;

	-- DELETE
	IF (TG_OP = 'DELETE') THEN

		-- Sur une base historisée, ne rentre jamais dans le delete
		RAISE EXCEPTION SQLSTATE '77778' USING MESSAGE = 'GCMS ECHEC DELETE : delete impossible sur une base historisée' ;
		RETURN NULL;

	END IF;

	-- INSERT
	IF (TG_OP = 'INSERT') THEN

		-- Le champ gcms_detruit booleen est obligatoire (contrainte dans la base de données).
		-- Si le client propose une mise à jour dans laquelle ce champ est vide, on
		-- le remplace le NULL par FALSE
		IF (NEW.gcms_detruit IS NULL) THEN
		    NEW.gcms_detruit = FALSE;
		END IF;

		-- Si le gcms_numrec est fourni dans la requête (non null)
		-- alors la requête vient du GCVS classique, pas besoin du trigger
		IF (NEW.gcms_numrec IS NOT NULL) THEN
			RETURN NEW;
		END IF;

		-- Puisqu'on est dans le cas d'un 'client GCMS' et non d'un client classique,
		-- on peut se permettre d'utiliser directement un UUID sans plus d'une cleabs classique
		-- (ca nous arrange bien, car on ne peut fournir les cleabs classiques provenant du
		-- dictionnaire alors que l'on est à l'intérieur de la transaction de mise à jour)
		--NEW.cleabs := ign_gcms_get_feature_id (TG_RELID);
		--NEW.cleabs := ign_gcms_generate_uuid()::text;
		NEW.gcms_date_creation := now();
		NEW.gcms_numrec := currval('seqnumrec');
		-- Empreinte pour compatiblité GCVS ; dans ce cas la colonne géométrique s'appele "geometrie"
		IF (ign_gcms_test_column_exists(TG_RELID, 'gcvs_empreinte')) THEN
			SELECT ign_gcms_get_empreinte (NEW.geometrie) INTO NEW.gcvs_empreinte ;
		END IF;

		RETURN NEW;
	END IF;

END;
$BODY$;


--------------------------------------------------------------------------------
-- Ajoute un objet dans l'historique (utilisé par ign_gcms_history_trigger_function)
--
-- [mmichaud 2016-07-29] la fonction ne nécessite plus que gcms_numrecmodif soit
-- la dernière colonne
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_add_to_history_table(nomTable text, objectid text, numderrec integer)
    RETURNS void AS $BODY$

DECLARE
    schema_table text[];
    table_h text ;
    requete text ;
    colonnes text ;

BEGIN
    schema_table := ign_gcms_decompose_table_name(nomTable);
    table_h := schema_table[1] || '_h' ;

    requete := 'SELECT string_agg(quote_ident(attname), '','') FROM pg_attribute WHERE  attrelid = ''' || nomTable ||
               '''::regclass AND attnum > 0 AND NOT attisdropped GROUP BY attrelid';
    --RAISE NOTICE '%', requete;
    EXECUTE requete INTO colonnes;

    requete := 'INSERT INTO ' || quote_ident(schema_table[0]) || '.' || quote_ident(table_h) || '(' || colonnes || ', gcms_numrecmodif)' ||
               ' (SELECT ' || colonnes || ', ' || numderrec ||
               ' FROM ' || quote_ident(schema_table[0]) || '.' || quote_ident(schema_table[1]) ||
               ' WHERE objectid=''' || objectid || ''')' ;
    --RAISE NOTICE '%', requete;
    EXECUTE requete ;

    RETURN ;

END
$BODY$
LANGUAGE plpgsql ;


--------------------------------------------------------------------------------
-- Installe le trigger de gestion de l'historique.
-- A appeler avec le nom du schéma :
-- SELECT ign_gcms_create_history_triggers('nom_schema.nom_table') - nom schéma optionnel si schéma public
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_create_history_triggers ( _table regclass ) RETURNS void AS $$
BEGIN

	EXECUTE $x$

		-- Ajoute la structure historique si elle n'existe pas
		SELECT ign_gcms_history_table_modifier ($x$ || quote_literal( _table ) || $x$) ;
		SELECT ign_gcms_create_history_table ($x$ || quote_literal( _table ) || $x$) ;

		-- Ajoute les triggers de gestion de l'historique à la table
		-- Les noms sont important car ils sont déclenchés dans l'odre alphabétique
		DROP TRIGGER IF EXISTS ign_gcms_history_trigger ON $x$ || _table || $x$ ;
		CREATE TRIGGER ign_gcms_history_trigger
			BEFORE UPDATE OR INSERT OR DELETE ON $x$ || _table || $x$
				FOR EACH ROW EXECUTE PROCEDURE ign_gcms_history_trigger_function() ;
 	$x$;
END
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Desactive/active les  triggers de gestion de l'historique
-- Si paramètre = TRUE : DISABLE
-- Si paramètre = FALSE : ENABLE
-- A appeler avec le nom du schéma :
-- SELECT ign_gcms_disable_history_triggers('nom_schema.nom_table', true) - nom schéma optionnel si schéma public
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_disable_history_triggers ( _table regclass, disable boolean ) RETURNS void AS $$
DECLARE
    action TEXT;
    st TEXT[];
    tablename TEXT;
BEGIN
    IF (disable IS TRUE) THEN
        action = 'DISABLE';
    ELSE
        action = 'ENABLE';
    END IF;

    st := ign_gcms_decompose_table_name( _table );
    tablename := FORMAT('%s.%s', st[0], st[1]);
    IF ign_gcms_trigger_exists(tablename, 'ign_gcms_history_trigger') THEN
        EXECUTE FORMAT('ALTER TABLE %s %s TRIGGER %s', tablename, action, 'ign_gcms_history_trigger');
    END IF;
END
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Installe les  triggers de gestion des conflits ET de l'historique.
-- A appeler avec le nom du schéma :
-- SELECT ign_gcms_create_conflict_and_history_triggers('nom_schema.nom_table') - nom schéma optionnel si schéma public
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_create_conflict_and_history_triggers ( _table regclass ) RETURNS void AS $$
BEGIN
	-- C'est mieux de faire l'historique d'abord, ainsi on crée la table _h et on peut créer gcms_fingerprint sur la table _h
	EXECUTE ign_gcms_create_history_triggers ( _table );
    EXECUTE ign_gcms_create_conflict_triggers ( _table );
END
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------- FONCTIONS SUR LES RECONCILIATIONS ------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
--
-- Fonction qui exécute toutes les actions d'une transaction.
-- La transaction est passée en paramètre sous la forme d'un objet JSON qui
-- doit avoir la structure suivante :
-- { "user_name":"nom de l'utilisateur"
--   "group_names":"nom des groupes GCMS auxuels appartient l'utilisateur"
--   "comment":"commentaire décrivant la transaction"
--   "actions":[
--     {required: state, feature_type, client_feature_id, server_feature_id},
--     ...
--   ]
-- }
-- Les actions décrites dans la transaction doivent avoir la structure suivante
-- {
--   "state":"Insert|Update|Delete"
--   "feature_type":"nom de la table"
--   "server_feature_id":"valeur cleabs"
--   "client_feature_id":"identifiant temporaire client (utile pour les insert)"
--   autres attributs (dépendant du featureType)
-- }
-- La fonction prépare l'ensemble des requêtes de la transaction, mais
-- le 'COMMIT' reste à la charge de la méthode appelante.
--
-- La réconciliation est remplie avec les valeurs suivantes :
-- operateur : nom de l'utilisateur GCMS (clé user_name du JSON)
-- profil : nom des groupes auxquels appartient l'utilisateur (clé group_names du JSON). Les groupes sont séparés par @@
-- nom : un commentaire utilisateur (clé comment du JSON)
-- commentaire : Réconciliation API GCMS   (en dur)
-- nature_operation : MAJ_GE  (en dur)
-- numclient : -3 (en dur)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_reconcilier(_transaction JSON) RETURNS INT AS $$
DECLARE

	-- parametres de la transaction
	_user_zr TEXT;
	_groups_zr TEXT;
	_commentaire_zr TEXT;
	_numrec integer;
	_classes_impactees_zr TEXT[] := array[]::TEXT[];
	_geometries_zr GEOMETRY[] := array[]::GEOMETRY[];
	_nb_objets_zr INTEGER := 0;
	_buffer INTEGER := 1;
	_tmp TEXT;

	-- parametres des actions
	_action JSON;
	_server_feature_id TEXT;
	_state text;
	_table TEXT;
	_acronyme TEXT;
	--_client_feature_id TEXT;
	_geometry_columns TEXT[];
	_data JSON;

	_insert_count INT := 0;
	_mess_fin TEXT;
	_table_type TEXT;
	st TEXT[];
	_tgenabled TEXT;

BEGIN
	--_transaction := ('{"user_name":"moi", "comment":"ma transaction", "actions":[ ' ||
	--	'{"server_feature_id":"TAB_HIST0000000000000010", "state":"Insert", "feature_type":"table_historisee", "client_feature_id":"13f292753519412f8663ef9ba53e4f8a", "data":{"cleabs":"PAIHABIT0000000002439060","geom":"POINT (321660.426452497 7685278.39440074)","nom":"Paris","type":"A"}}'||
	--	',{"server_feature_id":"TAB_HIST0000000000000001", "state":"Update", "feature_type":"table_historisee", "client_feature_id":"9b429a5a79c54d1da930c8262015a4b7", "data":{"cleabs":"PAIHABIT0000000002439080","geom":"POINT (321779.302345535 7685410.47872634)","nom":"Lyon","type":"B", "gcms_fingerprint":"758c42ebb789612635945fe15c13cb33"}}'||
	--	',{"server_feature_id":"TAB_HIST0000000000000003", "state":"Delete", "feature_type":"table_historisee", "client_feature_id":"9b429a5a79c54d1da930c8262015a4b7", "data":{"cleabs":"PAIHABIT0000000002439080","geom":"POINT (321779.302345535 7685410.47872634)", "gcms_fingerprint":"758c42ebb789612635945fe15c13cb33"}}]}')::JSON;

	-- Vérifier le niveau d'isolation de la transaction
	IF (current_setting('transaction_isolation') <> 'repeatable read') THEN
		RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = 'Pour réconcilier, le niveau d''isolation de la transaction doit être ''repeatable read''';
	END IF;

	--IF NOT ign_gcms_test_table_exists('acronymes') THEN
    --	RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = 'Pour réconcilier, la table acronymes doit être présente et accessible';
    --END IF;

	-- Récupération de seqnumrec en début de transaction, les différentes requêtes de mise à jour
	-- se servent de currval('seqnumrec') pour insérer le numrec dans les objets
	SELECT nextval('seqnumrec') INTO _numrec;

	_user_zr := _transaction->>'user_name';
	_groups_zr := _transaction->>'group_names';
	_commentaire_zr := _transaction->>'comment';
	IF (_user_zr IS NULL) THEN
		RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = 'La transaction n''a pas d''attribut ''user_name''';
	END IF;

	FOR _action IN SELECT json_array_elements(_transaction->'actions') LOOP

		-- le nom de la table doit être présent pour chaque objet
		_table := _action->>'feature_type';
		IF (NOT ign_gcms_test_table_exists(_table)) THEN
			RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = format('Un objet de la transaction porte sur la table inconnue ''%s''', _table);
		END IF;

		-- le champ _state doit être défini et l'objet à modifier doit être identifiable
		_state := _action->>'state';
		IF (_state IS NULL) OR (_state <> 'Insert' AND _state <> 'Update' AND _state <> 'Delete') THEN
			RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = format('Un objet de la transaction n''a pas d''état (state) ou un état différent de Insert, Update ou Delete');
		END IF;

		-- le champ data doit être defini
		_data := _action->>'data';
		IF (_data IS NULL) THEN
			RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = format('Une Action doit comporter un champ data');
		END IF;

		-- Les actions Delete ou Update nécessitent un identifiant serveur
		_server_feature_id := _action->>'server_feature_id';
		IF (_server_feature_id IS NULL AND _state <> 'Insert') THEN
			RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = format('Un objet de la transaction à updater ou à supprimer n''a pas d''identifiant serveur (table ''%s'')', _table);
		END IF;

		-- Les action Insert nécessitent un identifiant client
		--_client_feature_id := _action->>'client_feature_id';
		--IF (_client_feature_id IS NULL AND _state = 'Insert') THEN
		--	RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = format('Un objet de la transaction à insérer n''a pas d''identifiant client (table ''%s'')', _table);
		--END IF;

		-- Decomposition de _table en schema et nom de table
		st := ign_gcms_decompose_table_name( _table );

		-- cas de la BD Topo : si le schema n'est pas public, on passe sur les tables publiques sous-jacentes
		IF ign_gcms_test_table_exists('acronymes') THEN
			_table = st[1] ;
		END IF ;

		-- Vérifie que les triggers historique sont activés
		IF NOT ign_gcms_trigger_exists_enable (_table, 'ign_gcms_history_trigger') THEN
			RAISE EXCEPTION SQLSTATE '77770'
			USING MESSAGE = format('Le trigger ign_gcms_history_trigger doit être installé et activé sur la table appelée par la transaction');
		END IF;

		-- Cas de la BD Uni : vérifie que les triggers conflit sont aussi activés
		-- (pour les bases métier on peut avoir l'historique sans conflit)
		IF ign_gcms_test_table_exists('acronymes') THEN
			IF NOT ign_gcms_trigger_exists_enable (_table, 'ign_gcms_fingerprint_trigger') THEN
				RAISE EXCEPTION SQLSTATE '77770'
				USING MESSAGE = format('Le trigger ign_gcms_fingerprint_trigger doit être installé et activé sur la table appelée par la transaction');
			END IF;
			IF NOT ign_gcms_trigger_exists_enable (_table, 'ign_gcms_conflict_trigger') THEN
				RAISE EXCEPTION SQLSTATE '77770'
				USING MESSAGE = format('Le trigger ign_gcms_conflict_trigger doit être installé et activé sur la table appelée par la transaction');
			END IF;
		END IF;

		-- On cherche à remplir les classes impactées, pour la BD Uni
		IF ign_gcms_test_table_exists('acronymes') THEN
			SELECT acronyme FROM acronymes WHERE nom_table = _table INTO _acronyme;
			_classes_impactees_zr := array_append(_classes_impactees_zr, _acronyme);
		END IF;

		_geometry_columns := ign_gcms_get_geometry_columns(_table);
		RAISE NOTICE '% %', _table, _geometry_columns;

		_state := (_action->>'state');
		RAISE NOTICE '    %', _state;
		IF (_state = 'Insert') THEN
			RAISE NOTICE '    %', ign_gcms_create_insert(_table, _action, _geometry_columns);
			-- TODO : faut-il mettre un uuid si on est pas dans le cas de la BDUni ET que le
			-- client n'a pas fourni cet uuid ?
			-- _action := ign_gcms_add_key_value_to_json(_action,'cleabs', ign_gcms_generate_uuid()::text);
			EXECUTE ign_gcms_create_insert(_table, _action, _geometry_columns);
		ELSEIF (_state = 'Update') THEN
			RAISE NOTICE '    %', ign_gcms_create_update(_table, _action, _geometry_columns);
			EXECUTE ign_gcms_create_update(_table, _action, _geometry_columns);
		ELSEIF (_state = 'Delete') THEN
			RAISE NOTICE '    %', ign_gcms_create_delete(_table, _action);
			EXECUTE ign_gcms_create_delete(_table, _action);
		END IF;
		_nb_objets_zr := _nb_objets_zr +1;
		_geometries_zr := array_append(_geometries_zr, ST_Force2D(ign_gcms_get_geometry_from_action(_table, _data, _server_feature_id)));

	END LOOP;

	SELECT ARRAY(SELECT DISTINCT UNNEST(_classes_impactees_zr::TEXT[]) ORDER BY 1) INTO _classes_impactees_zr;

	IF array_length(_geometries_zr,1) = 1 THEN
		_buffer := 10;
	END IF;
	SELECT ign_gcms_finalize_transaction(
		_numrec,
		-3,
		array_to_string(_classes_impactees_zr, ','),
		_commentaire_zr,
		'',
		'MAJ_GE',
		'Réconciliation API GCMS',
		 St_Multi(St_Buffer(St_ConvexHull(St_Force2D(St_Collect(_geometries_zr))),_buffer,1)),
		_nb_objets_zr,
		_user_zr,
		_groups_zr) INTO _mess_fin;
	--SELECT ST_AsText(St_Multi(St_Buffer(St_ConvexHull(St_Force2D(St_Collect(_geometries_zr))),_buffer,1))) INTO _tmp;
	RETURN _numrec;
END
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------
-- Fonction à appeler en fin de transaction
--------------------------------------------------------------------------------
-- Cette fonction peut être appelée directement par le client ou par la
-- fonction ign_gcms_reconcilier.
--------------------------------------------------------------------------------
-- penser à supprimer la fonction précédente, car le dernier argument de la nouvelle fonction
-- est optionnelle, et si les deux fonctions sont présentes, postgresql ne peut pas choisir
DROP FUNCTION IF EXISTS ign_gcms_finalize_transaction(integer,integer,text,text,text,text,text,geometry,integer,text,text);
CREATE OR REPLACE FUNCTION ign_gcms_finalize_transaction(
    integer,
    integer,
    text,
    text,
    text,
    text,
    text,
    geometry,
    integer,
    text,
	text,
	text default NULL)
  RETURNS text AS
$BODY$

DECLARE

	numrec_zr ALIAS FOR $1;
	numclient_zr ALIAS FOR $2 ;
	classesimpactees_zr ALIAS FOR $3 ;
	nom_zr ALIAS FOR $4 ;
	changement_zr ALIAS FOR $5 ;
	natureoperation_zr ALIAS FOR $6 ;
	commentaire_zr ALIAS FOR $7 ;
	geometrie_zr ALIAS FOR $8 ;
	nbobjrec_zr ALIAS FOR $9 ;
	operateur_zr ALIAS FOR $10 ;
	profil_zr ALIAS FOR $11 ;
	source_zr ALIAS FOR $12 ;

	geometrie_multi_zr geometry ;
	num_fin_rec integer;
	res integer ;
	messFin text ;

BEGIN
	res := 0 ;

	IF NOT (ign_gcms_test_table_exists('gcvs_lockfinevol')) THEN
		RAISE EXCEPTION SQLSTATE '77770' USING MESSAGE = 'La réconciliation ne peut être finalisée, la table gcvs_lockfinevol n''est pas présente.';
	END IF;

	EXECUTE 'SELECT * FROM gcvs_lockfinevol WHERE a=1 FOR UPDATE';
	GET DIAGNOSTICS res = ROW_COUNT ;
	IF res = 1 THEN
		-- on transforme la geometrie de la zone de reconciliation en MULTIPOLYGONE car c est une contrainte de la table reconciliations.
		geometrie_multi_zr := ST_Multi (geometrie_zr) ;

		num_fin_rec := ign_gcms_get_next_val('seqnumordrefinevol');
		RAISE NOTICE 'NUM FIN EVOL DEB : [%]',num_fin_rec;

		-- Si ign_gcms_get_next_val retourne -1 c est qu il y a eu un probleme, alors la reconciliation s arrete
		IF num_fin_rec = -1 THEN
			RAISE EXCEPTION SQLSTATE '77770'
				USING MESSAGE = 'La reconciliation qui porte le nom de ''' || nom_zr ||
								''' ne s''est pas terminee. Impossible de recuperer le numero ordre fin evol.';
		ELSE
			INSERT INTO reconciliations (
			    ordrefinevol, numrec, numclient, classesimpactees, daterec, nom, changement,
			    nature_operation, commentaire, geometrie, nbobjrec, operateur, profil, source
			) VALUES (
			    num_fin_rec, numrec_zr, numclient_zr, classesimpactees_zr, now(), nom_zr, changement_zr,
			    natureoperation_zr, commentaire_zr, geometrie_multi_zr, nbobjrec_zr, operateur_zr, profil_zr, source_zr
			);
			GET DIAGNOSTICS res = ROW_COUNT ;
			IF res = 1 THEN
				messFin := 'La reconciliation [' || numrec_zr || '] s est terminee avec succes.' ;
			ELSE
				RAISE EXCEPTION SQLSTATE '77770'
					USING MESSAGE = 'La reconciliation qui porte le nom ''' || nom_zr ||
									''' ne s''est pas terminée.' ;
			END IF ;
		END IF ;
	ELSE
		RAISE EXCEPTION SQLSTATE '77770'
			USING MESSAGE = 'La table gcvs_lockfinevol ne contient pas la valeur a=1, le systeme n est pas transactionnel, impossible de reconcilier.';
	END IF ;
	RAISE NOTICE 'REMARQUE : Nombre total d objets reconcilies [%]', nbobjrec_zr ;
	RAISE NOTICE 'REMARQUE : %', messFin ;
	RETURN messFin ;

END
$BODY$
LANGUAGE plpgsql ;


-- -----------------------------------------------------------------------------
-- Retourne la liste des attributs JSON qui ne font pas partie des colonnes
-- à mettre à jour dans la base de données.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_excluded_action_attributes (keep_id BOOLEAN) RETURNS TEXT[] AS $$
DECLARE
	_server_feature_id TEXT;
BEGIN
	SELECT ign_gcms_get_feature_id_name() INTO _server_feature_id;
	IF keep_id THEN
		RETURN array['state','feature_type','client_feature_id','server_feature_id'];
	ELSE
		RETURN array['state','feature_type','client_feature_id',_server_feature_id,'server_feature_id'];
	END IF;
END
$$ LANGUAGE plpgsql ;

-- -----------------------------------------------------------------------------
-- Compte le nombre d'actions INSERT de la transaction
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_insert_count(_transaction JSON) RETURNS INT AS $$
DECLARE
	nb INT := 0;
	_action JSON;
BEGIN
	FOR _action IN SELECT json_array_elements(_transaction->'actions') LOOP
		IF ('Insert' = _action->>'state') THEN
			nb := nb + 1;
		END IF;
	END LOOP;
	RETURN nb;
END
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Compte le nombre d'objets "pertinents" concernés par une action,
-- c'et-à-dire ceux qui seront vraiment mis à jour en dehors des attributs systèmes
-- * attribute_map est une action json (ensemble de paires clés/valeurs)
-- * excludes contient les attributs 'système' qui ne rentrent pas dans la
-- liste des colonnes à mettre à jour.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_json_action_count(attribute_map JSON, excludes TEXT[]) RETURNS text AS $$
DECLARE
	name TEXT;
	nb INT := 0;
BEGIN
	FOR name IN SELECT json_object_keys(attribute_map) LOOP
		IF NOT excludes @> array[name] THEN
			nb := nb + 1;
		END IF;
	END LOOP;
	RETURN nb ;
END
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Crée une requete de type INSERT à partir d'une action
-- -----------------------------------------------------------------------------
--DROP FUNCTION ign_gcms_create_insert(_table text, attribute_map JSON, geometry_columns TEXT[]);
CREATE OR REPLACE FUNCTION ign_gcms_create_insert(_table text, action JSON, geometry_columns text[]) RETURNS text AS $$
DECLARE
	_id_name TEXT;
	_excluded TEXT[];
	_sql TEXT;
	_server_feature_id TEXT;
BEGIN
	SELECT ign_gcms_get_feature_id_name() INTO _id_name;
	SELECT ign_gcms_get_excluded_action_attributes(true) INTO _excluded;
	-- La méthode appelante a déjà vérifié l'existence de la table
	-- La méthode appelante a déjà vérifié que l'id était non null
	_sql := 'INSERT INTO ';
	_sql := _sql || _table || '(' || ign_gcms_json_action_to_attribute_names(action->'data', _excluded) || ')' ||
		' VALUES (' || ign_gcms_json_action_to_attribute_values(action->'data', _table, geometry_columns, _excluded) || ')';
	RETURN _sql;
END
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Crée une requete de type UPDATE à partir d'une action
-- -----------------------------------------------------------------------------
--DROP FUNCTION ign_gcms_create_update(_table text, attribute_map JSON);
CREATE OR REPLACE FUNCTION ign_gcms_create_update(_table text, action JSON, geometry_columns TEXT[]) RETURNS text AS $$
DECLARE
	_id_name TEXT;
	_server_feature_id TEXT;
	_excluded TEXT[];
	_sql TEXT;
	_nb INT;
BEGIN
	SELECT ign_gcms_get_feature_id_name() INTO _id_name;
	SELECT ign_gcms_get_excluded_action_attributes(false) INTO _excluded;
	SELECT ign_gcms_json_action_count(action->'data', _excluded) INTO _nb;
	-- La méthode appelante a déjà vérifié l'existence de la table
	-- La méthode appelante a déjà vérifié que l'id était non null
	_server_feature_id := action->>'server_feature_id';
	_sql := 'UPDATE ';
	_sql := _sql || _table || ' SET ' ;
	IF _nb > 1 THEN
		_sql := _sql || '(';
	END IF;
	_sql := _sql || 	ign_gcms_json_action_to_attribute_names(action->'data', _excluded);
	IF _nb > 1 THEN
		_sql := _sql || ') = (';
	ELSE
		_sql := _sql || ' = ';
	END IF;
	_sql := _sql || ign_gcms_json_action_to_attribute_values(action->'data', _table, geometry_columns, _excluded);
	IF _nb > 1 THEN
		_sql := _sql || ')';
	END IF;
	_sql := _sql || ' WHERE ' || _id_name || ' = ''' || _server_feature_id || '''';
	RETURN _sql;
END
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Crée une requete de type DELETE à partir d'une action
-- -----------------------------------------------------------------------------
-- Si la colonne gcms_fingerprint n'existe pas, on ne s'en occupe pas
-- afin de rendre la gestion de l'historique indépendante de la gestion des
-- conflits
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_create_delete(_table TEXT, action JSON) RETURNS TEXT AS $$
DECLARE
	_id_name TEXT;
	_sql TEXT;
	_server_feature_id TEXT;
	_fingerprint TEXT;
BEGIN
	SELECT ign_gcms_get_feature_id_name() INTO _id_name;
	-- La méthode appelante a déjà vérifié l'existence de la table
	-- La méthode appelante a déjà vérifié que l'id était non null
	_server_feature_id := action->>'server_feature_id';
	_fingerprint := (action->'data')->>'gcms_fingerprint';
	-- Le champ gcms_detruit est géré comme un booleen (necessite un nouvel addon GCVS)
	IF ign_gcms_test_column_exists(_table,'gcms_fingerprint') THEN
		_sql := 'UPDATE ' || _table ||
				' SET (gcms_detruit,gcms_fingerprint) = (true,''' || _fingerprint || ''')' ||
				' WHERE ' || _id_name || ' = ''' || _server_feature_id || '''';
	ELSE
		_sql := 'UPDATE ' || _table ||
				' SET gcms_detruit = true' ||
				' WHERE ' || _id_name || ' = ''' || _server_feature_id || '''';
	END IF;
	RETURN _sql;
END
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Convertit une map json en liste de noms d'attributs
-- * attribute_map est une action json (ensemble de paires clés/valeurs)
-- * excludes contient les attributs 'système' qui ne rentrent pas dans la
-- liste des colonnes à mettre à jour.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_json_action_to_attribute_names(attribute_map JSON, excludes TEXT[]) RETURNS text AS $$
DECLARE
	column_list text[] := array[]::TEXT[];
	name TEXT;
BEGIN
	FOR name IN SELECT json_object_keys(attribute_map) LOOP
		IF NOT excludes @> array[name] THEN
			column_list := array_append(column_list, quote_ident(name));
		END IF;
	END LOOP;
	RETURN array_to_string(column_list, ',') ;
END
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Convertit une map json en liste de valeurs d'attributs
-- Cas des géométries : si on fournit de la 2D alors que la 3D est attendue, alors met un Z = -1000 sur chaque coordonnée
-- -----------------------------------------------------------------------------
--DROP FUNCTION ign_gcms_json_action_to_attribute_values(JSON,TEXT[]);
CREATE OR REPLACE FUNCTION ign_gcms_json_action_to_attribute_values(attribute_map JSON, _table TEXT, geometry_columns TEXT[], excludes TEXT[]) RETURNS TEXT AS $$
DECLARE
	values text[] := array[]::TEXT[];
	name TEXT;
	value JSON;
	srid TEXT;
    st TEXT[];
	dim integer;
BEGIN
    -- Decomposition de _table en schema et nom de table
	st := ign_gcms_decompose_table_name( _table );

	FOR name IN SELECT json_object_keys(attribute_map) LOOP
		IF NOT excludes @> array[name] THEN
			value := attribute_map->name;
			IF (geometry_columns @> array[name]) THEN
				SELECT Find_SRID(st[0], st[1], name) INTO srid;
				SELECT coord_dimension FROM geometry_columns WHERE f_table_schema=st[0] AND f_table_name=st[1] AND f_geometry_column=name INTO dim;
				IF dim=3 THEN
					values := array_append(values, 'ign_ST_Force3D(ST_GeomFromText(''' || (attribute_map->>name) || ''',' || srid || '), -1000.)');
				ELSE
					values := array_append(values, 'ST_GeomFromText(''' || (attribute_map->>name) || ''',' || srid || ')');
				END IF;
			ELSEIF (json_typeof(value) = 'string') THEN
				values := array_append(values, quote_literal(attribute_map->>name));
			ELSEIF (json_typeof(value) = 'number') THEN
				values := array_append(values, attribute_map->>name);
			ELSEIF (json_typeof(value) = 'boolean') THEN
				values := array_append(values, attribute_map->>name);
			ELSEIF (json_typeof(value) = 'null') THEN
				values := array_append(values, 'NULL');
			ELSEIF (json_typeof(value) = 'object' OR json_typeof(value) = 'array') THEN
				values := array_append(values, quote_literal(value) || '::JSON');
			ELSE
				RAISE EXCEPTION 'Unknown type of JSON object';
			END IF;
		END IF;
	END LOOP;
	RETURN array_to_string(values, ',') ;
END
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Retourne la geometrie décrite par cet action comme une geometry postgis
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_geometry_from_action(_table TEXT, _action JSON, _server_feature_id TEXT) RETURNS geometry AS $$
DECLARE
	geometry_columns TEXT[] := array[]::TEXT[];
	attribute TEXT;
	srid TEXT;
	geom GEOMETRY;
    st TEXT[];
BEGIN
    -- Decomposition de _table en schema et nom de table
	st := ign_gcms_decompose_table_name( _table );

	SELECT ign_gcms_get_geometry_columns(_table) INTO geometry_columns;

	-- Si la géométrie est dans les actions : on la récupère
	-- C'est obligatoire dans le cas d'un Insert
	-- Cela peut être le cas pour un Update avec modification géométrique
	FOR attribute IN SELECT json_object_keys(_action) LOOP
		IF (geometry_columns @> array[attribute]) THEN
			SELECT Find_SRID(st[0], st[1], attribute) INTO srid;
			SELECT ST_GeomFromText(_action->>attribute, srid::INT) INTO geom;
			RETURN geom;
		END IF;
	END LOOP;

	-- Si la géométrie n'est pas fournie dans les actions :
	-- on récupère la géométrie de l'objet (dont la clé est _server_feature_id)
	-- Ce sera le cas pour un Delete
	-- Cela peut être le cas pour un Update sans modification géométrique
	-- On prend arbitrairmement la première géométrie si la table en porte plusieurs
	EXECUTE 'SELECT ' || geometry_columns[1] || ' FROM ' || _table || ' WHERE ' || ign_gcms_get_feature_id_name() || ' = ''' || _server_feature_id || '''' INTO geom;
	RETURN geom;
END
$$ LANGUAGE plpgsql;




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------- FONCTIONS SUR DE RECUPERATION D'INFORMATIONS SUR L'HISTORIQUE-----------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------
-- Fonction qui renvoie, pour un objet, différentes informations traçant son historique, avec la vie des champs passés en paramètre.
-- Le résultat est issu d'une jointure de la table, sa table historique avec la table réconciliations :
-- date de réconciliation, numrec, ordrefinevol, numclient, opérateur, profil, nature de l'opération.
-- On indique aussi si l'objet est detruit (gcms_detruit).
-- Le numéro de version est calculé dynamiquement.
-- On renvoie 3 champs JSON, chacun constitué de clés/valeur : nom de l'attribut / valeur de l'attribut
-- -> valeur_courante : la valeur courante du champ sur la version de l'enregistrement
-- -> valeur_ancienne : la valeur de la version précédente
-- -> ce_qui_change : indique pour chaque champ s'il a bougé entre la version n et la version précédente
--
-- Seules sont renvoyées les versions avec un changement sur les champs fournis en paramètres (et non toutes les versions de l'objet).
--
-- Les champs gcms_numrec et gcms_detruit ne devraient pas être appelés dans le tableau des attributs.
-- Leurs valeurs sont systématiquement renvoyées en dehors du JSON.
--
-- Intérêt du num_client :
-- S'il vaut -2 : réconciliation issue du Guichet adresse mairie (opérateur = login du Guichet)
-- S'il vaut -3 : réconciliation issue de l'API GCMS (opérateur = login, profil = groupe)
--
-- Remarques:
-- -> Nécessite la presence d'un index sur la cleabs des tables historiques pour être performant.
-- -> Les valeurs nulles ne sont pas discriminées des valeurs '', c'est à dire que si le champ d'un objet passe de null à vide ou inversement, le changement n'
--    n'est pas detecté ( ce comportement peut être modifié).

-- Fonction à appeler ainsi : SELECT * FROM ign_gcms_get_historique_attributs ('public.pai_culture_et_loisirs', 'public.pai_culture_et_loisirs_h', 'PAICULOI0000000105662080', '{nature, graphie_principale}')
-- Bien mettre le nom du schéma (même si public)
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ign_gcms_get_historique_attributs(
	tablename text,
	tablename_h text,
	cleabs text,
	attributes text[])
    RETURNS TABLE(daterec timestamp without time zone,
				version bigint,
				gcms_numrec integer,
				ordrefinevol integer,
				gcms_detruit boolean,
				numclient integer,
				operateur character varying,
				profil character varying,
				nature_operation character varying,
				valeur_courante jsonb,
				valeur_ancienne jsonb,
				ce_qui_change jsonb)
AS $BODY$

DECLARE
	requete text;
	attr text;
    detruit_field TEXT;
	geom_fields TEXT;
BEGIN

	-- On enlève gcms_detruit et gcmc_numrec et tous les champs système
	attributes := array_remove(attributes, 'gcms_detruit');
	attributes := array_remove(attributes, 'detruit');
	attributes := array_remove(attributes, 'gcms_numrec');
	attributes := array_remove(attributes, 'objectid');
	attributes := array_remove(attributes, 'numrec');
	attributes := array_remove(attributes, 'ordrefinevol');
	attributes := array_remove(attributes, 'daterec');
	attributes := array_remove(attributes, 'gcms_date_creation');
	attributes := array_remove(attributes, 'gcms_date_modification');
	attributes := array_remove(attributes, 'gcms_date_destruction');
	attributes := array_remove(attributes, 'date_creation');
	attributes := array_remove(attributes, 'date_modification');
	attributes := array_remove(attributes, 'date_destruction');
	attributes := array_remove(attributes, 'gcvs_empreinte');
	attributes := array_remove(attributes, 'empreinte');
	attributes := array_remove(attributes, 'gcms_fingerprint');

	-- Construction de la requête
	-- Elle va ressembler à ça
	-- Appel : SELECT * FROM ign_gcms_get_historique_attributs ('pai_culture_et_loisirs', 'PAICULOI0000000105662080', '{nature, graphie_principale}' );
	-- Résultat :
	-- SELECT r.daterec,
	--		t2.version,
	--		r.numrec,
	--		r.ordrefinevol,
	--		t2.gcms_detruit,
	--		r.numclient,
	--		r.operateur,
	--		r.profil,
	--		r.nature_operation,
	--		json_build_object ('nature', t2.nature)::jsonb ||
	--			json_build_object('graphie_principale', t2.graphie_principale)::jsonb
	--				AS valeur_courante,
	--		json_build_object ('nature', t2.previous_nature)::jsonb ||
	--			json_build_object('graphie_principale', t2.previous_graphie_principale)::jsonb
	--				AS valeur_ancienne,
	--		json_build_object ('nature', t2.nature IS DISTINCT FROM previous_nature)::jsonb ||
	--			json_build_object('graphie_principale', t2.graphie_principale IS DISTINCT FROM previous_graphie_principale)
	--				AS ce_qui_change
	--		 FROM
	--		 ( SELECT RANK() OVER (order by gcms_numrec) AS version,
	--		 gcms_numrec,
	--		 gcms_detruit,
	--		 nature, LAG(nature) OVER (ORDER BY gcms_numrec) AS previous_nature,
	--		 graphie_principale, LAG(graphie_principale) OVER (ORDER BY gcms_numrec) AS previous_graphie_principale
	--		 FROM (
	--		 SELECT gcms_numrec, gcms_detruit,
	--				COALESCE(nature::text, '') AS nature,
	--				COALESCE(graphie_principale::text, '') AS graphie_principale
	--		 FROM pai_culture_et_loisirs WHERE cleabs = 'PAICULOI0000000105662080'
	--		 UNION ALL
	--		 SELECT gcms_numrec,gcms_detruit,
	--				COALESCE(nature::text, '') AS nature,
	--				COALESCE(graphie_principale::text, '') AS graphie_principale
	--		 FROM pai_culture_et_loisirs_h WHERE cleabs = 'PAICULOI0000000105662080'
	--		 ORDER BY gcms_numrec
	--		 ) t
	--		 ) t2
	--		 JOIN reconciliations r ON (r.numrec=t2.gcms_numrec )
	--		 WHERE
	--			t2.gcms_detruit IS TRUE  OR
	--			t2.nature IS DISTINCT FROM previous_nature OR
	--			t2.graphie_principale IS DISTINCT FROM previous_graphie_principale
	--		ORDER BY gcms_numrec

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = btrim(split_part(tablename, '.', 1), '"') and table_name = btrim(split_part(tablename ,'.', 2), '"') AND column_name LIKE 'gcms_detruit')
    THEN
	   detruit_field := 'gcms_detruit';
    ELSE
	   detruit_field := 'detruit';
	END IF;
	
	geom_fields := (SELECT * FROM ign_gcms_get_geometry_columns(tablename));
	
	requete := 'SELECT r.daterec,
					t2.version,
					r.numrec,
					r.ordrefinevol,
					t2.'||detruit_field||',
					r.numclient,
					r.operateur,
					r.profil,
					r.nature_operation,';
	FOREACH attr IN ARRAY attributes LOOP
		requete := requete || 'json_build_object(''' || attr || ''', t2.' || attr || ')::jsonb || ' ;
	END LOOP ;
	requete := left (requete, length(requete)-4);
	requete := requete || ' AS valeur_courante,';
	FOREACH attr IN ARRAY attributes LOOP
		requete := requete || 'json_build_object(''' || attr || ''', t2.previous_' || attr || ')::jsonb || ' ;
	END LOOP ;
	requete := left (requete, length(requete)-4);
	requete := requete || ' AS valeur_ancienne,';
	FOREACH attr IN ARRAY attributes LOOP
		requete := requete || 'json_build_object(''' || attr || ''', t2.' || attr || ' IS DISTINCT FROM previous_' || attr || ')::jsonb || ' ;
	END LOOP ;
	requete := left (requete, length(requete)-4);
	requete := requete || ' AS ce_qui_change';

	requete := requete || '
			 FROM
			 ( SELECT RANK() OVER (order by gcms_numrec) AS version,
			 gcms_numrec,
			 '||detruit_field||',';
	FOREACH attr IN ARRAY attributes LOOP
		requete := requete || attr || ', LAG(' || attr || ') OVER (ORDER BY gcms_numrec) AS previous_' || attr || ', ' ;
	END LOOP ;
	requete := left (requete, length(requete)-2);
	requete := requete || '
			 FROM (
			 SELECT gcms_numrec, '||detruit_field||',';
	FOREACH attr IN ARRAY attributes LOOP
	    IF attr = ANY (geom_fields::text[]) THEN
		    requete := requete || 'COALESCE(St_AsText(' || attr || ')::text, '''') AS ' || attr || ', ' ;
		ELSE
		    requete := requete || 'COALESCE(' || attr || '::text, '''') AS ' || attr || ', ' ;
	    END IF ;
	END LOOP ;
	requete := left (requete, length(requete)-2);

	requete := requete || ' FROM ' || tablename || ' WHERE objectid = ''' || objectid || '''';
	requete := requete || '
			 UNION ALL
			 SELECT gcms_numrec,'||detruit_field||',';
	FOREACH attr IN ARRAY attributes LOOP
	    IF attr = ANY (geom_fields::text[]) THEN
		    requete := requete || 'COALESCE(St_AsText(' || attr || ')::text, '''') AS ' || attr || ', ' ;
		ELSE
		    requete := requete || 'COALESCE(' || attr || '::text, '''') AS ' || attr || ', ' ;
		END IF ;
	END LOOP ;
	requete := left (requete, length(requete)-2);

	requete := requete || ' FROM ' || tablename_h || ' WHERE objectid = ''' || objectid || '''';
	requete := requete || '
			 ORDER BY gcms_numrec
			 ) t
			 ) t2
			 JOIN reconciliations r ON (r.numrec=t2.gcms_numrec )
			 WHERE
				t2.'||detruit_field||' IS TRUE  OR ';
	FOREACH attr IN ARRAY attributes LOOP
		requete := requete || 't2.' || attr || ' IS DISTINCT FROM previous_' || attr || ' OR ' ;
	END LOOP ;
	requete := left (requete, length(requete)-3);
	requete := requete || ' ORDER BY gcms_numrec';

	-- RAISE NOTICE '%', requete ;

    RETURN QUERY
	EXECUTE requete ;

 END;
$BODY$ LANGUAGE 'plpgsql';


---------------------------------------------------------------------------------------------------------------
-- Fonction qui renvoie, pour un objet, différentes informations traçant son historique.
-- Le résultat est issu d'une jointure de la table, sa table historique avec la table réconciliations :
-- date de réconciliation, numrec, ordrefinevol, numclient, opérateur, profil, nature de l'opération.
-- On indique aussi si l'objet est detruit (gcms_detruit).
-- Le numéro de version est calculé dynamiquement.
--
-- Intérêt du num_client :
-- S'il vaut -2 : réconciliation issue du Guichet adresse mairie (opérateur = login du Guichet)
-- S'il vaut -3 : réconciliation issue de l'API GCMS (opérateur = login, profil = groupe)
--
-- Fonction à appeler ainsi : SELECT * FROM ign_gcms_get_historique (tablename, tablename_h, cleabs)
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_get_historique(tablename text, tablename_h text, objectid text)
RETURNS TABLE (daterec timestamp without time zone,
				version bigint,
				gcms_numrec integer,
				ordrefinevol integer,
				gcms_detruit boolean,
				numclient integer,
				operateur varchar,
				profil varchar,
				nature_operation varchar)  AS $$
DECLARE
	detruit_field TEXT;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = btrim(split_part(tablename, '.', 1), '"') and table_name = btrim(split_part(tablename ,'.', 2), '"') AND column_name LIKE 'gcms_detruit')
    THEN
	   detruit_field := 'gcms_detruit';
    ELSE
	   detruit_field := 'detruit';
    END IF;
    RETURN QUERY
	EXECUTE format (
	'SELECT r.daterec,
		RANK() OVER (ORDER BY r.numrec) AS version,
		r.numrec,
		r.ordrefinevol,
		t.%s,
		r.numclient,
		r.operateur,
		r.profil,
		r.nature_operation FROM
		(SELECT gcms_numrec,objectid, %s  FROM %s
		    UNION ALL
		SELECT gcms_numrec,objectid,%s  FROM %s) t
	JOIN reconciliations r ON (r.numrec=t.gcms_numrec)
	WHERE objectid=''%s''
	ORDER BY r.daterec ASC', detruit_field, detruit_field,
	tablename, detruit_field, tablename_h, objectid);
END;
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------------------------------
-- Fonction qui renvoie pour une zone donnéee, tous les objets d'une table à la date correspondante.
-- Les objets détruits avant la date T ne sont pas renvoyés si detruit false (valeur par défaut)
-- Si detruit true renvoie tous les objets d'une table à la date correspondante (detruits ou non)
--
-- Fonction à appeler ainsi :
-- SELECT * FROM ign_gcms_get_table_daterec_zone (null::pai_zone_d_habitation, 'pai_zone_d_habitation', 'pai_zone_d_habitation_h',
-- '2009-07-22', 400000,6416000,430000,6430000)
-- Bien mettre null::le_nom_de_la_table comme premier paramètre
-- On peut aussi appeler avec le nom de schéma :
-- SELECT * FROM ign_gcms_get_table_daterec_zone (null::public.pai_zone_d_habitation, 'public.pai_zone_d_habitation', 'public.pai_zone_d_habitation_h',
-- '2009-07-22', 400000,6416000,430000,6430000)
-- pour renvoyer également les objets détruits :
-- SELECT * FROM ign_gcms_get_table_daterec_zone (null::pai_zone_d_habitation, 'pai_zone_d_habitation', 'pai_zone_d_habitation_h',
-- '2009-07-22', 400000,6416000,430000,6430000, true)
---------------------------------------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS ign_gcms_get_table_daterec_zone(base anyelement, tablename text, tablename_h text, daterec text,
								x_min real, y_min real, x_max real, y_max real);
CREATE OR REPLACE FUNCTION ign_gcms_get_table_daterec_zone(base anyelement, tablename text, tablename_h text, daterec text,
								x_min real, y_min real, x_max real, y_max real, detruit boolean default false)
RETURNS SETOF anyelement
AS $$
DECLARE
	schema_table text[];    -- Pour décomposer en nom_schema.nom_table
	schema_only text;		-- Nom du schéma sans la table
	table_only text;		-- Nom de la table sans le schéma
	table_h_only text;		-- Nom de la table historique sans le schéma
	req_liste_champs text; 	-- Requête pour retrouver la liste des champs
	liste_champs text;		-- Liste des champs dans les sous-requêtes
	liste_champs2 text;		-- Liste des champs renvoyés au final
	users_rec RECORD;
	geomname text;
	requete text;
	date_detruit_field TEXT;
BEGIN
	schema_table := ign_gcms_decompose_table_name(tablename);
	schema_only := schema_table[0];
	table_only := schema_table[1];
	schema_table := ign_gcms_decompose_table_name(tablename_h);
	table_h_only := schema_table[1];

	IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = btrim(split_part(tablename, '.', 1), '"')
		AND table_name = btrim(split_part(tablename ,'.', 2), '"') AND column_name LIKE 'gcms_date_destruction')
    THEN
	   date_detruit_field := 'gcms_date_destruction';
    ELSE
	   date_detruit_field := 'date_destruction';
	END IF;

	--RAISE NOTICE '%  %',schema_only,table_only;

	req_liste_champs := 'SELECT column_name,data_type, character_maximum_length
							FROM information_schema.columns
							WHERE table_name=''' || table_only || '''
							AND table_schema = ''' || schema_only || '''
							ORDER BY ordinal_position';
	liste_champs := '';
	liste_champs2 := '';
	FOR users_rec IN EXECUTE req_liste_champs
	LOOP
		liste_champs := liste_champs || users_rec.column_name ;
		liste_champs2 := liste_champs2 || 'T.' || users_rec.column_name ;
		IF (users_rec.data_type <> 'USER-DEFINED') THEN
			liste_champs := liste_champs || '::' || users_rec.data_type ;
			liste_champs2 := liste_champs2 || '::' || users_rec.data_type ;
		END IF;
		IF ((users_rec.data_type = 'character varying' OR users_rec.data_type = 'character') AND users_rec.character_maximum_length IS NOT NULL) THEN
			liste_champs := liste_champs || '(' || users_rec.character_maximum_length || ')' ;
			liste_champs2 := liste_champs2 || '(' || users_rec.character_maximum_length || ')' ;
		END IF;
		liste_champs := liste_champs	|| ', '; -- nécessaire de caster par le type en cas d'incohérence entre vue et table sous-jacente
		liste_champs2 := liste_champs2 || ', ';
	END LOOP;
	liste_champs := left (liste_champs, length(liste_champs)-2);	-- on enleve la dernière virgule
	liste_champs2 := left (liste_champs2, length(liste_champs2)-2);	-- on enleve la dernière virgule

	EXECUTE 'SELECT f_geometry_column FROM geometry_columns WHERE f_table_name = ''' || table_only || ''' AND f_table_schema = ''' || schema_only || '''' INTO geomname;

	requete := format ('
		SELECT %9$s FROM (
			-- table principale
			SELECT %8$s, 0 as gcms_numrecmodif FROM %1$s WHERE %10$s && ST_MakeEnvelope(%3$s,%4$s,%5$s,%6$s)
			-- et y ajoute
			UNION
			-- les données de la table historique de mêmes cleabs que les données de la table actuelle situés sur la même zone
			SELECT %8$s, gcms_numrecmodif FROM %2$s  WHERE %10$s && ST_MakeEnvelope(%3$s,%4$s,%5$s,%6$s)
			) AS T
			-- La somme des donnees actuelles et historiques sur la zone s appelle T

			-- Par jointure avec la table des reconciliation,
			-- on supprime toutes les versions des objets reconciliees apres T
			JOIN (SELECT * FROM reconciliations WHERE daterec < ''%7$s'') AS R1 ON T.gcms_numrec = R1.numrec

			-- Une nouvelle jointure avec la table des reconciliations
			-- permet d obtenir pour chaque version de l objet 2 dates :
			-- * la date numrec ayant reconcilie cette version de l objet
			-- * la date numrecmodif ayant reconcilie la version suivante de l objet
			-- (le deuxieme attribut est vide pour les objets de la table actuelle)
			LEFT JOIN (SELECT * FROM reconciliations WHERE daterec >= ''%7$s'') AS R2 ON T.gcms_numrecmodif = R2.numrec

			-- On ne garde finalement que les objets dont
			-- * la date de reconciliation ayant reconcilie la version suivante est posterieure à T
			-- * ou la date de reconciliation ayant reconcilie la version suivante est nulle
			--      et la date de destruction est nulle ou posterieure à T
			--		ou on veut recuperer les objets detruits
			WHERE R2.daterec >= ''%7$s'' OR (T.gcms_numrecmodif = 0 AND (''%12$s'' IS TRUE OR (T.%11$s IS NULL OR T.%11$s > ''%7$s'')))',  ---- PATCH gcms A REVOIR

			-- pour le passage des paramètres dans la fonction format : on utilise la notation %N$s qui indique qu'on prend le paramètre en Nième position
			-- (voir la doc de cette fonction dans la doc de postgres)
			tablename, tablename_h,
			x_min::text, y_min::text, x_max::text, y_max::text,
			daterec,
			liste_champs, liste_champs2, geomname,
			date_detruit_field, detruit);

	--RAISE NOTICE '%', requete;

	RETURN QUERY EXECUTE requete ;

END;
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------------------------------
-- Fonction qui ajoute une colonne a la table historique
-- On verifie d'abord que la table existe et que la colonne n'existe pas.
-- On peut appeler en préfixant par le nom du schéma :
-- SELECT ign_gcms_add_column_in_history('nom_schema.nom_table').
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_update_index_numrec_in_history( _table TEXT, _column TEXT) RETURNS VOID AS $$
DECLARE
    schema_table text[];
	nom_table text;
	nom_schema text;
	nom_table_h text;
	nom_schema_table_h text;
    index_name text;
    column_exists boolean;

BEGIN
	schema_table := ign_gcms_decompose_table_name(_table);
	nom_schema := schema_table[0];
	nom_table := schema_table[1];
	nom_table_h := quote_ident(nom_table || '_h');
	nom_schema_table_h := quote_ident(nom_schema) || '.' || nom_table_h ;

	-- Test existence table _h
	IF NOT EXISTS (
		SELECT 1 FROM pg_class, pg_namespace
		WHERE  pg_class.relname = nom_table_h
		AND pg_class.relnamespace = pg_namespace.oid
		AND pg_namespace.nspname = quote_ident(nom_schema)
	) THEN
		RAISE NOTICE 'La table % du schéma % n''existe pas', nom_table_h, nom_schema;
		RETURN;
	END IF;

    -- On verifie que la colonne n'existe pas
    SELECT ign_gcms_test_column_exists(nom_schema_table_h, _column) INTO column_exists;
    IF column_exists IS FALSE THEN
        RAISE NOTICE 'La colonne % de la table % n''existe pas', _column, nom_schema_table_h;
        RETURN;
    END IF;

    index_name := 'index_numrecmodif_' || nom_table_h;

    EXECUTE $x$
    -- Ajout d'un champ temporaire (copie du champ gcms_numrecmodif)
	ALTER TABLE $x$ || nom_schema_table_h || $x$ ADD COLUMN gcms_numrecmodiftmp integer ;
	UPDATE $x$ || nom_schema_table_h || $x$ SET gcms_numrecmodiftmp = gcms_numrecmodif ;
	-- Suppression de l'index
    DROP INDEX IF EXISTS $x$ || quote_ident(index_name) || $x$;
	ALTER TABLE $x$ || nom_schema_table_h || $x$ DROP COLUMN gcms_numrecmodif;
	ALTER TABLE $x$ || nom_schema_table_h || $x$ RENAME COLUMN gcms_numrecmodiftmp TO gcms_numrecmodif ;
	CREATE INDEX $x$ || quote_ident(index_name) || $x$ ON $x$ || nom_schema_table_h || $x$(gcms_numrecmodif);
    $x$;
END
$$ LANGUAGE plpgsql;


---------------------------------------------------------------------------------------------------------------
-- Fonction qui supprime une colonne a la table historique
-- On verifie d'abord que la table existe et que la colonne existe.
-- On peut appeler en préfixant par le nom du schéma :
-- SELECT ign_gcms_drop_column_in_history('nom_schema.nom_table').
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_drop_column_in_history( _table TEXT, _column TEXT) RETURNS VOID AS $$
DECLARE
    schema_table text[];
    nom_table text;
    nom_schema text;
    nom_table_h text;
    nom_schema_table_h text;
    column_exists boolean;

BEGIN

	schema_table := ign_gcms_decompose_table_name(_table);
	nom_schema := schema_table[0];
	nom_table := schema_table[1];
	nom_table_h := quote_ident(nom_table || '_h');
	nom_schema_table_h := quote_ident(nom_schema) || '.' || nom_table_h ;

	-- Test existence table _h
	IF NOT EXISTS (
		SELECT 1 FROM pg_class, pg_namespace
		WHERE  pg_class.relname = nom_table_h
		AND pg_class.relnamespace = pg_namespace.oid
		AND pg_namespace.nspname = quote_ident(nom_schema)
	) THEN
		RAISE NOTICE 'La table % du schéma % n''existe pas', nom_table_h, nom_schema;
		RETURN;
	END IF;

    -- On verifie que la colonne n'existe pas
    SELECT ign_gcms_test_column_exists(nom_schema_table_h, _column) INTO column_exists;
    IF column_exists IS FALSE THEN
        RAISE NOTICE 'La colonne % de la table % n''existe pas', _column, nom_schema_table_h;
        RETURN;
    END IF;

    EXECUTE $x$
        -- Suppression de la colonne dans la table historique
	ALTER TABLE $x$ || nom_schema_table_h || $x$ DROP COLUMN $x$ || _column || $x$;
    $x$;
END
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Renvoie tous les champs d'un objet selon sa clé et le gcms_numrec.
-- En priorité va voir dans la table principale.
-- Si ne trouve pas dans la table principale va voir dans la table _h.
-- Si un objet de la table_h est renvoyé, renvoie les mêmes champs que la table principale (c'est-à-dire sans le gcms_numrecmodif)
--
-- Ne fonctionne que dans le schéma public
--
-- A appeler ainsi : SELECT * FROM ign_gcms_select_cleabs_numrec (null::pai_zone_d_habitation, 'PAIHABIT0000001369988945', 23047695);
-- (le null::xx  est important)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_select_cleabs_numrec(base anyelement, objectid text, gcms_numrec integer)
RETURNS SETOF anyelement
AS $$
DECLARE
	table_name text;
    table_name_h text;
    req_liste_champs text;
    query text;
    query_h text;
    liste_champs text;
    attname text;
BEGIN
	table_name = pg_typeof(base)::text;
    table_name_h = table_name || '_h';

    -- Liste des champs
    req_liste_champs := 'SELECT attname FROM pg_class,pg_attribute,pg_namespace
                        WHERE pg_class.relname=''' || table_name || '''
                        AND pg_class.relnamespace = pg_namespace.oid
                        AND pg_namespace.nspname = ''public''
                        AND pg_class.oid=pg_attribute.attrelid
                        AND pg_attribute.attnum>0
                        AND pg_attribute.atttypid<>0';

    liste_champs := '';
	FOR attname IN EXECUTE req_liste_champs
	LOOP
		liste_champs := liste_champs || attname || ', ';
	END LOOP;
	liste_champs := left (liste_champs, length(liste_champs)-2);	-- on enleve la dernière virgule

    -- Requête dans la table principale
    query = format('SELECT %s FROM %s WHERE objectid = $1 AND gcms_numrec = $2', liste_champs, table_name);
    RETURN QUERY EXECUTE query USING objectid, gcms_numrec;

    -- Si pas de résultat : requête dans la table_h
    IF NOT FOUND THEN
		query_h = format('SELECT %s FROM %s WHERE objectid = $1 AND gcms_numrec = $2', liste_champs, table_name_h);
		RETURN QUERY EXECUTE query_h USING objectid, gcms_numrec;
	END IF;

    RETURN;

END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Renvoie tous les champs d'une table selon le gcms_numrec.
-- Cherche dans la table principale et la table _h
-- Si un objet de la table_h est renvoyé, renvoie les mêmes champs que la table principale (c'est-à-dire sans le gcms_numrecmodif)
--
-- Ne fonctionne que dans le schéma public
--
-- A appeler ainsi : SELECT * FROM ign_gcms_select_numrec (null::pai_zone_d_habitation, 23047695);
-- (le null::xx  est important)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ign_gcms_select_numrec(
	base anyelement,
	gcms_numrec integer)
    RETURNS SETOF anyelement
    LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
	table_name text;
    table_name_h text;
    req_liste_champs text;
    query text;
    query_h text;
    liste_champs text;
    attname text;
	users_rec RECORD;
BEGIN

	table_name = pg_typeof(base)::text;

    -- Liste des champs
	req_liste_champs := 'SELECT column_name,data_type, character_maximum_length
							FROM information_schema.columns
							WHERE table_name=''' || table_name || '''
							AND table_schema = ''public''
							ORDER BY ordinal_position';
    liste_champs := '';
	FOR users_rec IN EXECUTE req_liste_champs
	LOOP
		liste_champs := liste_champs || users_rec.column_name ;
		IF (users_rec.data_type <> 'USER-DEFINED') THEN
			liste_champs := liste_champs || '::' || users_rec.data_type ;
		END IF;
		IF ((users_rec.data_type = 'character varying' OR users_rec.data_type = 'character') AND users_rec.character_maximum_length IS NOT NULL) THEN
			liste_champs := liste_champs || '(' || users_rec.character_maximum_length || ')' ;
		END IF;
		liste_champs := liste_champs	|| ', '; -- nécessaire de caster par le type en cas d'incohérence entre vue et table sous-jacente
	END LOOP;
	liste_champs := left (liste_champs, length(liste_champs)-2);	-- on enleve la dernière virgule
	--RAISE NOTICE '%', liste_champs;

	table_name = 'public.' || table_name ;
	table_name_h = table_name || '_h';

    -- Requête dans la table principale
    query = format('SELECT %s FROM %s WHERE gcms_numrec = $1 UNION SELECT %s FROM %s WHERE gcms_numrec = $1',
				   liste_champs, table_name, liste_champs, table_name_h);
	--RAISE NOTICE '%', query;

    RETURN QUERY EXECUTE query USING gcms_numrec;

END;
$BODY$;
