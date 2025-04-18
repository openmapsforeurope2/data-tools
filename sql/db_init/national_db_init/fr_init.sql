--------------------------------------------------------------------------------------------------
-- ADMINISTRATIVE UNITS theme                                                                    -
--------------------------------------------------------------------------------------------------

-- Création de la table locale au.commune (copie de la table BDUni avec sélection d'attributs)
DROP TABLE IF EXISTS au.commune;
CREATE TABLE IF NOT EXISTS au.commune
(
    cleabs character varying(24) COLLATE pg_catalog."default" NOT NULL,
    code_insee character varying(5) COLLATE pg_catalog."default",
    code_insee_de_l_arrondissement character varying(5) COLLATE pg_catalog."default",
    code_insee_du_departement character varying(5) COLLATE pg_catalog."default",
    code_insee_de_la_region character varying(5) COLLATE pg_catalog."default",  
    nom_officiel character varying COLLATE pg_catalog."default",
    gcms_territoire character varying COLLATE pg_catalog."default" NOT NULL,
    codes_siren_des_epci character varying(32) COLLATE pg_catalog."default",
    geometrie_ge geometry(MultiPolygon),
    CONSTRAINT commune_pkey PRIMARY KEY (cleabs)
)
TABLESPACE pg_default;

-- Création de la table locale au.etat (copie de la table BDUni avec sélection d'attributs)
DROP TABLE IF EXISTS au.etat;
CREATE TABLE IF NOT EXISTS au.etat
(
    cleabs character varying(24) COLLATE pg_catalog."default" NOT NULL,
    code_insee character varying(5) COLLATE pg_catalog."default",
    nom_officiel character varying COLLATE pg_catalog."default",
    gcms_territoire character varying COLLATE pg_catalog."default",
    geometrie_ge geometry(MultiPolygon),
    CONSTRAINT etat_pkey PRIMARY KEY (cleabs)
)
TABLESPACE pg_default;

-- Création de la table locale au.region (copie de la table BDUni avec sélection d'attributs)
DROP TABLE IF EXISTS au.region;
CREATE TABLE IF NOT EXISTS au.region
(
    cleabs character varying(24) COLLATE pg_catalog."default" NOT NULL,
    code_insee character varying(5) COLLATE pg_catalog."default",
    nom_officiel character varying COLLATE pg_catalog."default",
    gcms_territoire character varying COLLATE pg_catalog."default" NOT NULL,
    geometrie_ge geometry(MultiPolygon),
    CONSTRAINT region_pkey PRIMARY KEY (cleabs)
)
TABLESPACE pg_default;

-- Création de la table locale au.departement (copie de la table BDUni avec sélection d'attributs)
DROP TABLE IF EXISTS au.departement;
CREATE TABLE IF NOT EXISTS au.departement
(
    cleabs character varying(24) COLLATE pg_catalog."default" NOT NULL,
    code_insee character varying(5) COLLATE pg_catalog."default",
    code_insee_de_la_region character varying(5) COLLATE pg_catalog."default",  
    nom_officiel character varying COLLATE pg_catalog."default",
    gcms_territoire character varying COLLATE pg_catalog."default" NOT NULL,
    geometrie_ge geometry(MultiPolygon),
    CONSTRAINT departement_pkey PRIMARY KEY (cleabs)
)
TABLESPACE pg_default;

-- Création de la table locale au.arrondissement (copie de la table BDUni avec sélection d'attributs)
DROP TABLE IF EXISTS au.arrondissement;
CREATE TABLE IF NOT EXISTS au.arrondissement
(
    cleabs character varying(24) COLLATE pg_catalog."default" NOT NULL,
    code_insee_de_l_arrondissement character varying(5) COLLATE pg_catalog."default",
    code_insee_du_departement character varying(5) COLLATE pg_catalog."default",
    code_insee_de_la_region character varying(5) COLLATE pg_catalog."default",  
    nom_officiel character varying COLLATE pg_catalog."default",
    gcms_territoire character varying COLLATE pg_catalog."default" NOT NULL,
    geometrie_ge geometry(MultiPolygon),
    CONSTRAINT arrondissement_pkey PRIMARY KEY (cleabs)
)
TABLESPACE pg_default;

-- Création de la table locale au.epci (copie de la table BDUni avec sélection d'attributs)
DROP TABLE IF EXISTS au.epci;
CREATE TABLE IF NOT EXISTS au.epci
(
    cleabs character varying(24) COLLATE pg_catalog."default" NOT NULL,
    code_siren character varying(9) COLLATE pg_catalog."default",
    nature character varying(50) COLLATE pg_catalog."default",
    nom_officiel character varying COLLATE pg_catalog."default",
    gcms_territoire character varying COLLATE pg_catalog."default" NOT NULL,
    geometrie_ge geometry(MultiPolygon),
    CONSTRAINT epci_pkey PRIMARY KEY (cleabs)
)
TABLESPACE pg_default;


-- A LANCER EN SUIVANT LA DOC

ALTER TABLE au.commune ADD COLUMN codes_siren_des_epci_trunc character varying(32);
UPDATE au.commune SET codes_siren_des_epci_trunc = SUBSTRING(codes_siren_des_epci, 0, 10);

ALTER TABLE au.commune ADD COLUMN code_epci_ebm character varying(32);
UPDATE au.commune
SET code_epci_ebm = au.ebm_nam_2024_fr.code_epci
FROM au.ebm_nam_2024_fr
WHERE SUBSTRING(au.commune.codes_siren_des_epci_trunc,0,10) = SUBSTRING(au.ebm_nam_2024_fr.siren_epci,0,10);

UPDATE au.commune SET code_epci_ebm = '0Z1' WHERE codes_siren_des_epci_trunc = '249730052';
UPDATE au.commune SET code_epci_ebm = '410' WHERE codes_siren_des_epci_trunc = '200054781';


ALTER TABLE au.epci ADD COLUMN code_epci_ebm character varying(32);
UPDATE au.epci
SET code_epci_ebm = au.ebm_nam_2024_fr.code_epci
FROM au.ebm_nam_2024_fr
WHERE au.epci.code_siren = au.ebm_nam_2024_fr.siren_epci;



--------------------------------------------------------------------------------------------------
-- HYDROGRAPHY theme                                                                             -
--------------------------------------------------------------------------------------------------

-- troncon_hydrographique : recuperation des champs cpx_influence_de_la_maree et cpx_code_hydrographique issus de cours_d_eau
ALTER TABLE troncon_hydrographique ADD COLUMN lien_vers_cours_d_eau_principal varchar(80);

ALTER TABLE troncon_hydrographique ADD COLUMN lien1 varchar(25); 
UPDATE troncon_hydrographique SET lien1 = substring(liens_vers_cours_d_eau,1,24);
ALTER TABLE troncon_hydrographique ADD COLUMN lien2 varchar(25); 
UPDATE troncon_hydrographique SET lien2 = substring(liens_vers_cours_d_eau,26,24);
ALTER TABLE troncon_hydrographique ADD COLUMN lien3 varchar(25); 
UPDATE troncon_hydrographique SET lien3 = substring(liens_vers_cours_d_eau,51,24);

ALTER TABLE troncon_hydrographique ADD COLUMN length1 real; 
UPDATE troncon_hydrographique 
SET length1 = ST_length(cours_d_eau.geometrie_ge)
FROM cours_d_eau
WHERE troncon_hydrographique.lien1 = cours_d_eau.cleabs ;

ALTER TABLE troncon_hydrographique ADD COLUMN length2 real; 
UPDATE troncon_hydrographique 
SET length2 = ST_length(cours_d_eau.geometrie_ge)
FROM cours_d_eau
WHERE troncon_hydrographique.lien2 = cours_d_eau.cleabs ;

ALTER TABLE troncon_hydrographique ADD COLUMN length3 real; 
UPDATE troncon_hydrographique 
SET length3 = ST_length(cours_d_eau.geometrie_ge)
FROM cours_d_eau
WHERE troncon_hydrographique.lien3 = cours_d_eau.cleabs ;

UPDATE troncon_hydrographique
SET lien_vers_cours_d_eau_principal =
CASE
  WHEN length1 is not null AND (length1 >= length2 OR length2 is null ) and (length1 >= length3 OR length3 is null) THEN lien1
  WHEN length2 is not null AND length2 >= length1 AND (length2 >= length3 OR length3 is null) THEN lien2
  WHEN length3 is not null AND length3 >= length1 AND length3 >= length2 THEN lien3
  ELSE 'void'
END;

ALTER TABLE troncon_hydrographique ADD COLUMN cpx_influence_de_la_maree boolean;
ALTER TABLE troncon_hydrographique ADD COLUMN cpx_code_hydrographique character varying(80);
UPDATE troncon_hydrographique
SET cpx_influence_de_la_maree = cours_d_eau.influence_de_la_maree, cpx_code_hydrographique = cours_d_eau.code_hydrographique
FROM cours_d_eau
WHERE troncon_hydrographique.lien_vers_cours_d_eau_principal = cours_d_eau.cleabs ;

ALTER TABLE troncon_hydrographique DROP COLUMN lien1;
ALTER TABLE troncon_hydrographique DROP COLUMN lien2;
ALTER TABLE troncon_hydrographique DROP COLUMN lien3;
ALTER TABLE troncon_hydrographique DROP COLUMN length1;
ALTER TABLE troncon_hydrographique DROP COLUMN length2;
ALTER TABLE troncon_hydrographique DROP COLUMN length3;


-- surface_hydrographique : recuperation des champs cpx_influence_de_la_maree et cpx_code_hydrographique issus de cours_d_eau
ALTER TABLE surface_hydrographique ADD COLUMN lien_vers_cours_d_eau_principal varchar(80);

ALTER TABLE surface_hydrographique ADD COLUMN lien1 varchar(25); 
UPDATE surface_hydrographique SET lien1 = substring(liens_vers_cours_d_eau,1,24);
ALTER TABLE surface_hydrographique ADD COLUMN lien2 varchar(25); 
UPDATE surface_hydrographique SET lien2 = substring(liens_vers_cours_d_eau,26,24);
ALTER TABLE surface_hydrographique ADD COLUMN lien3 varchar(25); 
UPDATE surface_hydrographique SET lien3 = substring(liens_vers_cours_d_eau,51,24);

ALTER TABLE surface_hydrographique ADD COLUMN length1 real; 
UPDATE surface_hydrographique 
SET length1 = ST_length(cours_d_eau.geometrie_ge)
FROM cours_d_eau
WHERE surface_hydrographique.lien1 = cours_d_eau.cleabs ;

ALTER TABLE surface_hydrographique ADD COLUMN length2 real; 
UPDATE surface_hydrographique 
SET length2 = ST_length(cours_d_eau.geometrie_ge)
FROM cours_d_eau
WHERE surface_hydrographique.lien2 = cours_d_eau.cleabs ;

ALTER TABLE surface_hydrographique ADD COLUMN length3 real; 
UPDATE surface_hydrographique 
SET length3 = ST_length(cours_d_eau.geometrie_ge)
FROM cours_d_eau
WHERE surface_hydrographique.lien3 = cours_d_eau.cleabs ;

UPDATE surface_hydrographique
SET lien_vers_cours_d_eau_principal =
CASE
  WHEN length1 is not null AND (length1 >= length2 OR length2 is null ) and (length1 >= length3 OR length3 is null) THEN lien1
  WHEN length2 is not null AND length2 >= length1 AND (length2 >= length3 OR length3 is null) THEN lien2
  WHEN length3 is not null AND length3 >= length1 AND length3 >= length2 THEN lien3
  ELSE 'void'
END;

ALTER TABLE surface_hydrographique ADD COLUMN cpx_influence_de_la_maree boolean;
ALTER TABLE surface_hydrographique ADD COLUMN cpx_code_hydrographique character varying(80);
UPDATE surface_hydrographique
SET cpx_influence_de_la_maree = cours_d_eau.influence_de_la_maree, cpx_code_hydrographique = cours_d_eau.code_hydrographique
FROM cours_d_eau
WHERE surface_hydrographique.lien_vers_cours_d_eau_principal = cours_d_eau.cleabs ;

ALTER TABLE surface_hydrographique DROP COLUMN lien1;
ALTER TABLE surface_hydrographique DROP COLUMN lien2;
ALTER TABLE surface_hydrographique DROP COLUMN lien3;
ALTER TABLE surface_hydrographique DROP COLUMN length1;
ALTER TABLE surface_hydrographique DROP COLUMN length2;
ALTER TABLE surface_hydrographique DROP COLUMN length3;


-- surface_hydrographique : recuperation des champs cpx_influence_de_la_maree et cpx_code_hydrographique issus de cours_d_eau
ALTER TABLE surface_hydrographique ADD COLUMN lien_vers_pde_principal varchar(80);

ALTER TABLE surface_hydrographique ADD COLUMN lien1 varchar(25); 
UPDATE surface_hydrographique SET lien1 = substring(liens_vers_plan_d_eau,1,24);
ALTER TABLE surface_hydrographique ADD COLUMN lien2 varchar(25); 
UPDATE surface_hydrographique SET lien2 = substring(liens_vers_plan_d_eau,26,24);
ALTER TABLE surface_hydrographique ADD COLUMN lien3 varchar(25); 
UPDATE surface_hydrographique SET lien3 = substring(liens_vers_plan_d_eau,51,24);

ALTER TABLE surface_hydrographique ADD COLUMN area1 real; 
UPDATE surface_hydrographique 
SET area1 = ST_area(plan_d_eau.geometrie_ge)
FROM plan_d_eau
WHERE surface_hydrographique.lien1 = plan_d_eau.cleabs ;

ALTER TABLE surface_hydrographique ADD COLUMN area2 real; 
UPDATE surface_hydrographique 
SET area2 = ST_area(plan_d_eau.geometrie_ge)
FROM plan_d_eau
WHERE surface_hydrographique.lien2 = plan_d_eau.cleabs ;

ALTER TABLE surface_hydrographique ADD COLUMN area3 real; 
UPDATE surface_hydrographique 
SET area3 = ST_area(plan_d_eau.geometrie_ge)
FROM plan_d_eau
WHERE surface_hydrographique.lien3 = plan_d_eau.cleabs ;

UPDATE surface_hydrographique
SET lien_vers_pde_principal =
CASE
  WHEN area1 is not null AND (area1 >= area2 OR area2 is null ) and (area1 >= area3 OR area3 is null) THEN lien1
  WHEN area2 is not null AND area2 >= area1 AND (area2 >= area3 OR area3 is null) THEN lien2
  WHEN area3 is not null AND area3 >= area1 AND area3 >= area2 THEN lien3
  ELSE 'void'
END;

ALTER TABLE surface_hydrographique ADD COLUMN cpx_pde_influence_de_la_maree boolean;
ALTER TABLE surface_hydrographique ADD COLUMN cpx_pde_code_hydrographique character varying(80);
UPDATE surface_hydrographique
SET cpx_pde_influence_de_la_maree = plan_d_eau.influence_de_la_maree, cpx_pde_code_hydrographique = plan_d_eau.code_hydrographique
FROM plan_d_eau
WHERE surface_hydrographique.lien_vers_pde_principal = plan_d_eau.cleabs ;

ALTER TABLE surface_hydrographique DROP COLUMN lien1;
ALTER TABLE surface_hydrographique DROP COLUMN lien2;
ALTER TABLE surface_hydrographique DROP COLUMN lien3;
ALTER TABLE surface_hydrographique DROP COLUMN area1;
ALTER TABLE surface_hydrographique DROP COLUMN area2;
ALTER TABLE surface_hydrographique DROP COLUMN area3;

-- Toponyms for watercourse areas (surface_hydrographique table) need to be retrieved from the watercourse links (troncon_hydrographique table)
-- Step 1: create link table between watercourse areas and watercourse links
-- In troncon_hydrogrphique, the "liens_vers_surface_hydrographique" column indicates if the watercourse link is linked to a 
-- watercourse area. The column contains the cleabs (identifier) values of the linked hydro areas. It can contain up to two cleabs
-- values (assumption made by studying the table). Each cleabs has 24 characters, and, if there are 2 values, they are separated by
-- a slash "/".
-- The first query aims at filling the link table with watercourse areas cleabs values stored in first position in the liens_vers_surface_hydrographique
-- column.
DROP TABLE IF EXISTS lien_troncon_surface_hydrographique;
CREATE TABLE lien_troncon_surface_hydrographique AS 
SELECT cleabs, substring(liens_vers_surface_hydrographique,1,24) FROM troncon_hydrographique
WHERE liens_vers_surface_hydrographique IS NOT NULL AND NOT gcms_detruit;

-- The first query aims at filling the link table with watercourse areas cleabs values stored in second position in the liens_vers_surface_hydrographique
-- column.
DROP TABLE IF EXISTS lien_troncon_surface_hydrographique_tmp;
CREATE TABLE lien_troncon_surface_hydrographique_tmp AS 
SELECT cleabs, substring(liens_vers_surface_hydrographique,26,24) FROM troncon_hydrographique
WHERE liens_vers_surface_hydrographique IS NOT NULL AND liens_vers_surface_hydrographique LIKE '%/%' AND NOT gcms_detruit;

-- Import results of the 2nd query into the first table (lien_troncon_surface_hydrographique)
INSERT INTO lien_troncon_surface_hydrographique (cleabs, substring)
SELECT cleabs, substring
FROM lien_troncon_surface_hydrographique_tmp;

-- Rename/add necessary columns
ALTER TABLE lien_troncon_surface_hydrographique RENAME COLUMN cleabs TO cleabs_troncon;
ALTER TABLE lien_troncon_surface_hydrographique RENAME COLUMN substring TO cleabs_surface;
ALTER TABLE lien_troncon_surface_hydrographique ADD COLUMN toponyme character varying(255);
ALTER TABLE lien_troncon_surface_hydrographique ADD COLUMN length real;

ALTER TABLE surface_hydrographique DROP COLUMN IF EXISTS ome2_toponyme_troncon_hydrographique;
ALTER TABLE surface_hydrographique ADD COLUMN ome2_toponyme_troncon_hydrographique character varying(255);

-- Fill toponym column and length columns
UPDATE lien_troncon_surface_hydrographique 
SET toponyme = troncon_hydrographique.cpx_toponyme_de_cours_d_eau
FROM troncon_hydrographique
WHERE troncon_hydrographique.cleabs = lien_troncon_surface_hydrographique.cleabs_troncon ;

DELETE FROM lien_troncon_surface_hydrographique WHERE toponyme is null;

UPDATE lien_troncon_surface_hydrographique 
SET length = ST_Length(troncon_hydrographique.geometrie)
FROM troncon_hydrographique
WHERE troncon_hydrographique.cleabs = lien_troncon_surface_hydrographique.cleabs_troncon ;

-- At this stage, in the lien_troncon_surface_hydrographique table, there can be several rows with the same toponym for a given
-- watercourse area. In the next step, these lines are combined into a single row and a sum of the lengths indicated in each row
-- is calculated.
DROP TABLE IF EXISTS lien_troncon_surface_hydrographique_sum_length;
CREATE TABLE lien_troncon_surface_hydrographique_sum_length
AS SELECT cleabs_surface, toponyme, sum(length)
FROM lien_troncon_surface_hydrographique
GROUP BY cleabs_surface, toponyme;

-- Finally, we want to keep as toponym the one corresponding to the maximum length in the table above.
-- The query below updates the surface_hydrographique table consequently.
WITH lien_tron_surf_tmp AS
    (
        SELECT t1.cleabs_surface, t1.toponyme, t1.sum FROM lien_troncon_surface_hydrographique_sum_length t1, 
        (
            SELECT cleabs_surface, MAX(sum) AS max_val2
            FROM lien_troncon_surface_hydrographique_sum_length t2
            GROUP BY cleabs_surface
        ) t2
        WHERE t1.cleabs_surface = t2.cleabs_surface AND t1.sum = t2.max_val2
    )
UPDATE surface_hydrographique
SET ome2_toponyme_troncon_hydrographique = lien_tron_surf_tmp.toponyme
FROM lien_tron_surf_tmp
WHERE surface_hydrographique.cleabs = lien_tron_surf_tmp.cleabs_surface AND lien_tron_surf_tmp.toponyme IS NOT NULL;

