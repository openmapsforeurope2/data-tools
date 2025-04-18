-- Creation de la table des gemeente vlak et transformation de la geom en multipolygon
CREATE TABLE au.nl_gemeente_vlak AS SELECT * FROM au.top10nl_registratief_gebied_vlak WHERE typeregistratiefgebied = 'gemeente';
UPDATE au.nl_gemeente_vlak SET geom = ST_Multi(geom);

-- Creation de la table des provincie vlak et transformation de la geom en multipolygon
CREATE TABLE au.nl_provincie_multivlak AS SELECT * FROM au.top10nl_registratief_gebied_multivlak WHERE typeregistratiefgebied = 'provincie';
UPDATE au.nl_provincie_vlak SET geom = ST_Multi(geom);

-- Rassemblement de toutes les provincie (issues de vlak et multivlak) en une table unique
CREATE TABLE au.nl_provincie_all AS SELECT * FROM au.top10nl_registratief_gebied_multivlak WHERE typeregistratiefgebied = 'provincie';
INSERT INTO au.nl_provincie_all SELECT * FROM  au.nl_provincie_vlak;

-- Rassemblement de toutes les gemeente (issues de vlak et multivlak) en une table unique
CREATE TABLE au.nl_gemeente_all AS SELECT * FROM au.nl_gemeente_multivlak WHERE typeregistratiefgebied = 'gemeente';
INSERT INTO au.nl_gemeente_all SELECT * FROM au.nl_gemeente_vlak;

-- Ajout de la colonne provincie_nummer aux gemeente
ALTER TABLE au.nl_gemeente_all ADD COLUMN provincie_nummer text;

-- Remplissage de la colonne provincie_nummer par jointure spatiale
UPDATE au.nl_gemeente_all
SET provincie_nummer = au.nl_provincie_all.nummer
FROM au.nl_provincie_all
WHERE ST_Intersects(ST_Centroid(au.nl_gemeente_all.geom),au.nl_provincie_all.geom);
