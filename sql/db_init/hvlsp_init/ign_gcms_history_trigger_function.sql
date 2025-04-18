-- FUNCTION: public.ign_gcms_history_trigger_function()

-- DROP FUNCTION IF EXISTS public.ign_gcms_history_trigger_function();

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
				NEW.end_lifespan_version := now();
			    RETURN NEW;
		    ELSE
			    NEW.gcms_date_destruction := NULL;
				NEW.end_lifespan_version := NULL;
		    END IF;

		    -- Cas d'un vrai UPDATE
			-- 2022-06-19 : les updates déclenchés par un trigger ne doivent pas mettre à jour 
			-- gcms_date_modification car l'opération qui les a déclenché peut être un INSERT
		    NEW.gcms_date_modification := now();
			NEW.begin_lifespan_version := now();
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
		NEW.begin_lifespan_version := now();
		NEW.gcms_numrec := currval('seqnumrec');
		-- Empreinte pour compatiblité GCVS ; dans ce cas la colonne géométrique s'appele "geometrie"
		IF (ign_gcms_test_column_exists(TG_RELID, 'gcvs_empreinte')) THEN
			SELECT ign_gcms_get_empreinte (NEW.geometrie) INTO NEW.gcvs_empreinte ;
		END IF;

		RETURN NEW;
	END IF;

END;
$BODY$;

ALTER FUNCTION public.ign_gcms_history_trigger_function()
    OWNER TO postgres;

