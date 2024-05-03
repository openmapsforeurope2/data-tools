--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
----------------------- GCMS : GESTION DES CONFLITS ----------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 
-- Premier trigger qui détecte un conflit en regardant si le champ gcms_fingerprint
-- envoyé par l'UPDATE est bien égal à celui présent sur le serveur.
-- S'ils sont égaux : alors l'objet n'a pas bougé, c'est bon.
-- S'ils sont différents : alors l'objet a bougé, renvoie une exception de code 77777.
--
-- A intaller avec : 
-- CREATE TRIGGER ign_gcms_conflict_trigger BEFORE UPDATE OF gcms_fingerprint
-- 
-- Pour différencier le cas GCVS du cas GCMS, on s'appuie sur la présence ou non
-- du champ gcms_fingerprint.
-- Dans le cas d'un update, le trigger n'est déclenché que si ce champ est 
-- présent dans l'update.
--
-- 1er cas (GCVS) : le champ gcms_fingerprint ne sera pas présent dans l'update 
-- effectué par le client GeoConcept (-> pas de conflit déclenché par le trigger)
-- Note : ca marche aussi pour le delete qui est géré comme un update. L'insert
-- quand à lui ne génère jamais de conflit.
--
-- 2ème cas (GCMS) : présence obligatoire du champ gcms_fingerprint (vérifié dans 
-- le code php pour simplier les triggers)
--
-- Le fonctionnenemt global suppose qu'un second trigger soit installé.
-- Ce second trigger met à jour gcms_fingerprint à chaque update.
-- Code dans : ign_gcms_fingerprint_trigger_function
-- 
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_conflict_trigger_function() RETURNS TRIGGER AS $$
BEGIN

	-- UPDATE
	IF (TG_OP = 'UPDATE') THEN

		-- Le champ gcms_fingerprint doit non nul, non vide
		IF (NEW.gcms_fingerprint IS NULL) OR (NEW.gcms_fingerprint = '') THEN 
			RAISE EXCEPTION SQLSTATE '77777' USING MESSAGE = 'GCMS ECHEC UPDATE : Le champ permettant d''identifier les conflits n''est pas fourni ou alors il est vide';
		END IF;

		-- Le champ gcms_fingerprint doit être en base, non nul, non vide
		IF (OLD.gcms_fingerprint IS NULL) OR (OLD.gcms_fingerprint = '') THEN 
			RAISE EXCEPTION SQLSTATE '77777' USING MESSAGE = 'GCMS ECHEC UPDATE : Le champ permettant d''identifier les conflits a une valeur nulle ou vide sur le serveur';
		END IF;

		-- L'empreinte ne doit pas avoir changée
		IF (OLD.gcms_fingerprint <> NEW.gcms_fingerprint) THEN
			RAISE EXCEPTION SQLSTATE '77777' USING MESSAGE = 'GCMS ECHEC UPDATE : Tentative de mise à jour d''un objet qui a été mis à jour plus récemment';
		END IF;

		RETURN NEW;
	END IF;

	-- DELETE on ne devrait jamais passer par là si le trigger est bien installé avec
	-- CREATE TRIGGER ign_gcms_conflict_trigger BEFORE UPDATE
	IF (TG_OP = 'DELETE') THEN
		-- Pas moyen de détecter les conflits avec l'empreinte dans le cas d'un Delete car pas de NEW
		-- Le seul moyen est de simuler un Update côté client
		RETURN OLD;
	END IF;

	-- INSERT on ne devrait jamais passer par là si le trigger est bien installé avec
	-- CREATE TRIGGER ign_gcms_conflict_trigger BEFORE UPDATE
	IF (TG_OP = 'INSERT') THEN
		RETURN NEW;
	END IF;

END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
--
-- Ce deuxième trigger est utilisé quand le premier n'a pas déclenché de
-- conflit pour mettre à jour le champ gcms_fingerprint
--
-- ATTENTION : il est important que le nom de cette fonction vienne après
-- ign_gcms_conflict_trigger_function dans l'ordre alphabétique
--
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_fingerprint_trigger_function() RETURNS TRIGGER AS $$
BEGIN

	-- INSERT / UPDATE
	IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
		-- Mise à jour de l'empreinte
		NEW.gcms_fingerprint := ign_gcms_compute_fingerprint(NEW.*, array['gcms_fingerprint','gcms_territoire']) ;
		RETURN NEW;
	END IF;

END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- Calcul la cle md5 d'un enregistrement en se servant de toutes les colonnes
-- sauf celles indiquées dans le tableau omitted_columns.
-- Cette fonction est notamment utilisée par ign_gcms_conflict_trigger
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_compute_fingerprint(_record anyelement, omitted_columns TEXT[]) RETURNS TEXT AS
$BODY$

DECLARE
    table_ident REGCLASS;
    table_ident_esc TEXT;
 	omitted_columns_list TEXT;
	requete TEXT;
	column_list TEXT;
	_fingerprint TEXT;
BEGIN
	-- liste des colonnes à omettre
	omitted_columns_list := '(''' || ARRAY_TO_STRING(omitted_columns, ''', ''') || ''')';

	-- type de l'enregistrement
	table_ident := pg_typeof(_record);
	-- nom complet de la table avec les apostrophes échappées en vue de l'insertion
	-- dans la chaîne de caractères '(CAST ($1 AS %s)).'
	table_ident_esc := replace(table_ident::text,'''','''''');

	-- liste des champs de l'enregistrement omettant les champs du tableau omitted_columns
	-- premiere ligne : l'enregistrement $1 est explicitement casté dans le type de la table
	-- afin de pouvoir en extraire les valeurs à prendre en compte pour l'empreinte
	requete := 'SELECT ''(CAST ($1 AS %s))."'' || attname::VARCHAR || ''"''
               	FROM pg_catalog.pg_attribute
               	WHERE attrelid=%s AND attnum > 0 AND atttypid > 0 AND attname NOT IN %s
               	ORDER BY attnum';
	-- le nom de la table (qualifiée) sert une première fois à typer l'enregistrement. Il est
	-- insérer dans une chaîne de caractères, ce qui nous oblige à échapper les ' de manière
	-- très inélégante (pas trouvé mieux)
	-- l'id de la table (oid) est quand à lui utilisé dans le test attrelid=%s
	requete := format(requete, table_ident_esc, table_ident::oid, omitted_columns_list);

	-- concatener la liste des champs sous la forme suivante 
	-- ($1::nom_table).champ1, ($1::nom_table).champ2...
	EXECUTE 'SELECT ARRAY_TO_STRING(ARRAY(' || requete || '), '','')' INTO column_list;
	-- RAISE NOTICE '%', column_list;
	-- Executer la fonction md5 sur la concaténation des champs retenus
	EXECUTE 'SELECT md5(ROW('||column_list||')::TEXT)' INTO _fingerprint USING _record;
	RETURN _fingerprint;
	
END
$BODY$
LANGUAGE plpgsql ;


--------------------------------------------------------------------------------
-- Ajoute et calcule la colone gcms_fingerprint
-- y compris dans la table _h si elle existe
-- Cette fonction est plus générique mais moins rapide que la suivante :
-- * plus générique : pas de nom de champ ou de role spécifique bduni
-- * moins rapide : fait un update pour mettre à jour gcms_fingerprint (plus de
--   de jours pour la seule table troncon_de_route).
-- TODO : ne gère pas les noms de table mixed-case ou avec caractères spéciaux.
-- On peut appeler en préfixant par le nom du schéma :
-- SELECT ign_gcms_add_column_fingerprint('nom_schema.nom_table').
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_add_column_fingerprint ( _table regclass ) RETURNS void AS $$
DECLARE
	flag_trigger boolean DEFAULT false;
	nom_table text;
	nom_schema text;
	nom_table_h text;
	id_name text;
	index_name text;
	
BEGIN	
	SELECT ign_gcms_get_feature_id_name() INTO id_name;
	-- Test existence colonne gcms_fingerprint
	IF (ign_gcms_test_column_exists(_table::text, 'gcms_fingerprint')) THEN 
		RETURN;
	END IF;
	
	-- On désactive le trigger de gestion de l'historique sinon cela va créer du bruit dans l'historique
	IF EXISTS (
		SELECT 1 FROM pg_trigger
		WHERE tgrelid = _table
		AND tgname LIKE 'ign_gcms_history_trigger'
	) THEN
		EXECUTE $x$
			ALTER TABLE $x$ || _table || $x$ DISABLE TRIGGER ign_gcms_history_trigger;
		$x$;			
		flag_trigger := true;
	END IF;
	
	-- Ajout et calcul de gcms_fingerpint dans la table principale
	RAISE NOTICE 'Should update gcms_fingerprint on main table';
	EXECUTE $x$
		ALTER TABLE $x$ || _table || $x$ ADD COLUMN gcms_fingerprint text ;
		--UPDATE $x$ || _table || $x$ SET gcms_fingerprint = md5(CAST($x$ || _table || $x$.* AS text)) ;
		UPDATE $x$ || _table || $x$ SET gcms_fingerprint = ign_gcms_compute_fingerprint($x$ || _table || $x$.*, array['gcms_fingerprint']) ;
	$x$;
	
	-- On réactive le triggers de gestion de l'historique s'il existait
	IF (flag_trigger) THEN
		EXECUTE $x$
			ALTER TABLE $x$ || _table || $x$ ENABLE TRIGGER ign_gcms_history_trigger;
		$x$;
	END IF;	
	
	-- Ajout et calcul de gcms_fingerprint dans la table _h si elle existe
	-- Test existence table _h
	SELECT relname INTO nom_table FROM pg_class WHERE  pg_class.oid = _table ;
	SELECT nspname INTO nom_schema FROM pg_class, pg_namespace WHERE pg_class.relnamespace = pg_namespace.oid AND pg_class.oid = _table ;
	nom_table_h := quote_ident(nom_schema) || '.' || quote_ident(nom_table || '_h') ;
	IF NOT EXISTS (
		SELECT 1 FROM pg_class
		WHERE  relname = (nom_table || '_h')
	) THEN
		RAISE NOTICE 'La table % n''existe pas', nom_table_h;
		RETURN;
	END IF;		
	
	RAISE NOTICE 'Should update gcms_fingerprint on _h table';
	-- On suppose que si gcms_fingerprint n'existait pas dans la table principale, alors il n'existe pas dans la table _h
	-- ATTENTION : dans la table _h il faut que numrecmodif soit en dernier !!
	-- Successions de requêtes pour ne pas perdre le contenu de numrecmodif
	index_name := 'index_numrecmodif_' || nom_table_h;
	EXECUTE $x$
		ALTER TABLE $x$ || nom_table_h || $x$ ADD COLUMN gcms_fingerprint text ;
		ALTER TABLE $x$ || nom_table_h || $x$ ADD COLUMN gcms_numrecmodiftmp integer ;
		UPDATE $x$ || nom_table_h || $x$ SET gcms_numrecmodiftmp = gcms_numrecmodif ;
		DROP INDEX IF EXISTS $x$ || quote_ident(index_name) || $x$;
		ALTER TABLE $x$ || nom_table_h || $x$ DROP COLUMN gcms_numrecmodif;
		ALTER TABLE $x$ || nom_table_h || $x$ RENAME COLUMN gcms_numrecmodiftmp TO gcms_numrecmodif ;
		CREATE INDEX $x$ || quote_ident(index_name) || $x$ ON $x$ || nom_table_h || $x$(gcms_numrecmodif);
		-- On s'abstient de remplir le champ ign_gcms_compute_fingerprint de la table historique
		-- lors de l'initialisation (cette opération peut être très chronophage)
		--UPDATE $x$ || nom_table_h || $x$ SET gcms_fingerprint = ign_gcms_compute_fingerprint($x$ || nom_table_h || $x$.*, array['gcms_fingerprint']) ;
 	$x$;
END
$$ LANGUAGE plpgsql;



--------------------------------------------------------------------------------
-- Installe les  triggers de gestion des conflits sur une base partenaire
-- (utilisation de ign_gcms_add_column_fingerprint(regclass) qui est générique
-- mais peut être assez long sur de grosses tables).
-- On peut appeler en préfixant par le nom du schéma :
-- SELECT ign_gcms_create_conflict_triggers('nom_schema.nom_table').
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_create_conflict_triggers ( _table regclass ) RETURNS void AS $$
BEGIN

	EXECUTE $x$
	
		-- Ajoute la colonne gcms_fingerprint si elle n'existe pas
		SELECT ign_gcms_add_column_fingerprint (to_regclass( $x$ || quote_literal(_table::text) || $x$)) ;

		-- Ce trigger n'est activé que si le champ gcms_fingerprint est inclus dans la requête de mise à  jour
		DROP TRIGGER IF EXISTS ign_gcms_conflict_trigger ON $x$ || _table || $x$ ;
		CREATE TRIGGER ign_gcms_conflict_trigger
			BEFORE UPDATE OF gcms_fingerprint ON $x$ || _table || $x$
				FOR EACH ROW EXECUTE PROCEDURE ign_gcms_conflict_trigger_function() ;

		-- Dans le cas de GCVS, on veut mettre à jour le champ gcms_fingerprint bien que ce champ
		-- ne soit pas inclus dans l'UPDATE. Ce trigger complète donc le précédent
		DROP TRIGGER IF EXISTS ign_gcms_fingerprint_trigger ON $x$ || _table || $x$ ;
        CREATE TRIGGER ign_gcms_fingerprint_trigger
            BEFORE UPDATE OR INSERT ON $x$ || _table || $x$
            	FOR EACH ROW EXECUTE PROCEDURE ign_gcms_fingerprint_trigger_function() ;

				
 	$x$;
END
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Desactive/active les  triggers de gestion des conflits.
-- Si paramètre = TRUE : DISABLE
-- Si paramètre = FALSE : ENABLE
-- On peut appeler en préfixant par le nom du schéma :
-- SELECT ign_gcms_disable_conflict_triggers('nom_schema.nom_table').
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_gcms_disable_conflict_triggers ( _table regclass, disable boolean ) RETURNS void AS $$
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
    IF ign_gcms_trigger_exists(tablename, 'ign_gcms_conflict_trigger') THEN
        EXECUTE FORMAT('ALTER TABLE %s %s TRIGGER %s', tablename, action, 'ign_gcms_conflict_trigger');
    END IF;
    IF ign_gcms_trigger_exists(tablename, 'ign_gcms_fingerprint_trigger') THEN
        EXECUTE FORMAT('ALTER TABLE %s %s TRIGGER %s', tablename, action, 'ign_gcms_fingerprint_trigger');
    END IF;
END
$$ LANGUAGE plpgsql;
