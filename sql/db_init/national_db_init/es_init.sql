-- ADMINISTRATIVE UNITS theme

-- Add a column to all source tables to differentiate between the peninsula/Baleares (es) and Canary islands (ic = ISO code for "Islas Canarias")
ALTER TABLE au.recintos_autonomicas_inspire_peninbal_etrs89 ADD COLUMN ome2_country character varying DEFAULT 'es';
ALTER TABLE au.recintos_provinciales_inspire_peninbal_etrs89 ADD COLUMN ome2_country character varying DEFAULT 'es';
ALTER TABLE au.recintos_municipales_inspire_peninbal_etrs89 ADD COLUMN ome2_country character varying DEFAULT 'es';

ALTER TABLE au.recintos_autonomicas_inspire_canarias_regcan95 ADD COLUMN ome2_country character varying DEFAULT 'ic';
ALTER TABLE au.recintos_provinciales_inspire_canarias_regcan95 ADD COLUMN ome2_country character varying DEFAULT 'ic';
ALTER TABLE au.recintos_municipales_inspire_canarias_regcan95 ADD COLUMN ome2_country character varying DEFAULT 'ic';

-- Retrieve names from NGBE for AU level 2 in the Iberic peninsula (not needed for Canary islands)
ALTER TABLE au.recintos_autonomicas_inspire_peninbal_etrs89 ADD COLUMN ome2_nombre_extendido character varying;
ALTER TABLE au.recintos_autonomicas_inspire_peninbal_etrs89 ADD COLUMN ome2_identificador_geografico character varying;
ALTER TABLE au.recintos_autonomicas_inspire_peninbal_etrs89 ADD COLUMN ome2_nombre_alternativo_2 character varying;
ALTER TABLE au.recintos_autonomicas_inspire_peninbal_etrs89 ADD COLUMN ome2_idioma_idg character varying;
ALTER TABLE au.recintos_autonomicas_inspire_peninbal_etrs89 ADD COLUMN ome2_idioma_alternativo_2 character varying;

UPDATE au.recintos_autonomicas_inspire_peninbal_etrs89 a
SET ome2_nombre_extendido = b.nombre_extendido,
    ome2_identificador_geografico = b.identificador_geografico,
    ome2_nombre_alternativo_2 = b.nombre_alternativo_2,
    ome2_idioma_idg = b.idioma_idg,
    ome2_idioma_alternativo_2 = b.idioma_alternativo_2
FROM au.ngbe b
WHERE b.codigo_ngbe = '1.1.1' AND (a.nameunit = b.nombre_extendido OR a.nameunit = b.identificador_geografico);

-- Retrieve names from NGBE for AU level 3 in the Iberic peninsula (not needed for Canary islands)
ALTER TABLE au.recintos_provinciales_inspire_peninbal_etrs89 ADD COLUMN ome2_nombre_extendido character varying;
ALTER TABLE au.recintos_provinciales_inspire_peninbal_etrs89 ADD COLUMN ome2_identificador_geografico character varying;
ALTER TABLE au.recintos_provinciales_inspire_peninbal_etrs89 ADD COLUMN ome2_nombre_alternativo_2 character varying;
ALTER TABLE au.recintos_provinciales_inspire_peninbal_etrs89 ADD COLUMN ome2_idioma_idg character varying;
ALTER TABLE au.recintos_provinciales_inspire_peninbal_etrs89 ADD COLUMN ome2_idioma_alternativo_2 character varying;

UPDATE au.recintos_provinciales_inspire_peninbal_etrs89 a
SET ome2_nombre_extendido = b.nombre_extendido,
    ome2_identificador_geografico = b.identificador_geografico,
    ome2_nombre_alternativo_2 = b.nombre_alternativo_2,
    ome2_idioma_idg = b.idioma_idg,
    ome2_idioma_alternativo_2 = b.idioma_alternativo_2
FROM au.ngbe b
WHERE b.codigo_ngbe = '1.2' AND SUBSTRING(a.natcode, 5, 2) = b.provincias_id;


-- Retrieve names from NGBE for AU level 4 in the Iberic peninsula (not needed for Canary islands)
ALTER TABLE au.recintos_municipales_inspire_peninbal_etrs89 ADD COLUMN ome2_nombre_extendido character varying;
ALTER TABLE au.recintos_municipales_inspire_peninbal_etrs89 ADD COLUMN ome2_identificador_geografico character varying;
ALTER TABLE au.recintos_municipales_inspire_peninbal_etrs89 ADD COLUMN ome2_nombre_alternativo_2 character varying;
ALTER TABLE au.recintos_municipales_inspire_peninbal_etrs89 ADD COLUMN ome2_idioma_idg character varying;
ALTER TABLE au.recintos_municipales_inspire_peninbal_etrs89 ADD COLUMN ome2_idioma_alternativo_2 character varying;

UPDATE au.recintos_municipales_inspire_peninbal_etrs89 a
SET ome2_nombre_extendido = b.nombre_extendido,
    ome2_identificador_geografico = b.identificador_geografico,
    ome2_nombre_alternativo_2 = b.nombre_alternativo_2,
    ome2_idioma_idg = b.idioma_idg,
    ome2_idioma_alternativo_2 = b.idioma_alternativo_2
FROM au.ngbe b
WHERE b.codigo_ngbe = '1.3' AND SUBSTRING(a.natcode, LENGTH(a.natcode) - 4, 5) = SUBSTRING(b.codigo_ine, 1, 5);


-- Fill au.administrative_unit_area_1 table (no data provided from producer)

-- Step 1: Use au.administrative_unit_area_4 to create a multipolygon covering the whole country (other levels do not contain Ceuta,
-- Melilla and other small territories not linked to autonomias or provincias)
DROP TABLE IF EXISTS ome2_au_area_1_es;
CREATE TABLE ome2_au_area_1_es AS SELECT country,
       ST_Union(geom) as geom
FROM au.administrative_unit_area_4
WHERE country = 'es'
GROUP BY country;

-- Step 2: Insert geometry into au.administrative_unit_area_1
INSERT INTO au.administrative_unit_area_1 (country, geom)
SELECT country, geom
FROM ome2_au_area_1_es;

-- Step 3: fill missing attributes
UPDATE au.administrative_unit_area_1
SET national_code = 'void_unk',
    shn = 'ES0000000',
    name = '[
  {
    "script": "latn",
    "display": 1,
    "language": "spa",
    "spelling": "España",
    "nativeness": "endonym",
    "name_status": "official",
    "spelling_latn": "España"
  }
]' ,
    label = 'España',
    national_level_code = '2901',
    land_cover_type = 'land_area',
    xy_source = 'ome2',
    w_scale = '10000',
    w_release = 1
WHERE country = 'es';
