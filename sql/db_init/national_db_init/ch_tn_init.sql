-- Report des numéros de route et noms contenus dans la table tlm_strassen_strassenroute sur la table tlm_strassen_strasse
ALTER TABLE tlm_strassen_strasse ADD COLUMN ome2_national_routennummer character varying(80);
ALTER TABLE tlm_strassen_strasse ADD COLUMN ome2_european_routennummer character varying(80);
ALTER TABLE tlm_strassen_strasse ADD COLUMN ome2_road_name character varying(500);

ALTER TABLE tlm_strassen_strassenroute_strasse ADD COLUMN ome2_national_routennummer character varying(10);
ALTER TABLE tlm_strassen_strassenroute_strasse ADD COLUMN ome2_european_routennummer character varying(10);
ALTER TABLE tlm_strassen_strassenroute_strasse ADD COLUMN ome2_road_name character varying(255);

UPDATE tlm_strassen_strassenroute_strasse
SET ome2_national_routennummer = tlm_strassen_strassenroute.routennummer
FROM tlm_strassen_strassenroute
WHERE tlm_strassen_strassenroute_strasse.tlm_strassenroute_uuid = tlm_strassen_strassenroute.uuid AND tlm_strassen_strassenroute.routennummer NOT LIKE 'E%';

UPDATE tlm_strassen_strassenroute_strasse
SET ome2_european_routennummer = tlm_strassen_strassenroute.routennummer
FROM tlm_strassen_strassenroute
WHERE tlm_strassen_strassenroute_strasse.tlm_strassenroute_uuid = tlm_strassen_strassenroute.uuid AND tlm_strassen_strassenroute.routennummer LIKE 'E%';

UPDATE tlm_strassen_strassenroute_strasse
SET ome2_road_name = tlm_strassen_strassenroute.name
FROM tlm_strassen_strassenroute
WHERE tlm_strassen_strassenroute_strasse.tlm_strassenroute_uuid = tlm_strassen_strassenroute.uuid;

WITH tlm_tmp AS(SELECT tlm_strasse_uuid, 
string_agg(ome2_national_routennummer, '/' order by ome2_national_routennummer ASC) as ome2_national_routennummer, 
string_agg(ome2_european_routennummer, '/' order by ome2_european_routennummer ASC) as ome2_european_routennummer, 
array_agg(ome2_road_name order by ome2_road_name ASC) as ome2_road_name
FROM tlm_strassen_strassenroute_strasse
GROUP BY tlm_strasse_uuid)
UPDATE tlm_strassen_strasse
SET ome2_national_routennummer = tlm_tmp.ome2_national_routennummer, ome2_european_routennummer = tlm_tmp.ome2_european_routennummer,  ome2_road_name = tlm_tmp.ome2_road_name 
FROM tlm_tmp
WHERE tlm_strassen_strasse.uuid = tlm_tmp.tlm_strasse_uuid;


-- Calcul des géométries des objets complexes (table tlm_strassen_strassenroute_geom)
DROP TABLE IF EXISTS tlm_strassen_strassenroute_strasse_geom;
CREATE TABLE tlm_strassen_strassenroute_strasse_geom AS SELECT * FROM tlm_strassen_strassenroute_strasse;

SELECT AddGeometryColumn('tlm_strassen_strassenroute_strasse_geom', 'geom', 2056, 'LineStringZ', 3); 

UPDATE tlm_strassen_strassenroute_strasse_geom
SET geom = tlm_strassen_strasse.geom
FROM tlm_strassen_strasse
WHERE tlm_strassen_strassenroute_strasse_geom.tlm_strasse_uuid = tlm_strassen_strasse.uuid;



