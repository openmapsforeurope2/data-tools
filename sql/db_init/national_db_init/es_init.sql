--------------------------------------------------------------------------------------------------
-- ADMINISTRATIVE UNITS theme                                                                    -
--------------------------------------------------------------------------------------------------

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


--------------------------------------------------------------------------------------------------
-- TRANSPORT NETWORK theme                                                                       -
--------------------------------------------------------------------------------------------------

-- Source table for road_link
DROP TABLE IF EXISTS ome2_igr_rt_rt_tramo_l;
CREATE TABLE ome2_igr_rt_rt_tramo_l AS
SELECT a.id_tramo, a.tipo_tramo, a.clase, a.calzada, a.acceso, a.firme, a.ncarriles, a.sentido, a.situacion,
    a.estadofis, a.tipovehic, a.titular, a.orden, a.fuente, a.fecha_alta, a.alta_db, a.version, a.sent_tramo, a.geom,
    json_agg(json_build_object('id_vial', c.id_vial, 'codigo', c.codigo, 'dgc_via', c.dgc_via, 'tipo_vial', c.tipo_vial, 'nombre', c.nombre, 'nombre_alt', c.nombre_alt, 'fuente', c.fuente)) AS ome2_vial
FROM igr_rt_rt_tramo_l a
INNER JOIN igr_rt_rrt_tramo_vial b ON a.id_tramo = b.id_tramo
INNER JOIN igr_rt_rt_vial_a c ON b.id_vial = c.id_vial
GROUP BY a.id_tramo, a.tipo_tramo, a.clase, a.calzada, a.acceso, a.firme, a.ncarriles, a.sentido, a.situacion,
    a.estadofis, a.tipovehic, a.titular, a.orden, a.fuente, a.fecha_alta, a.alta_db, a.version, a.sent_tramo, a.geom;

-- Source table for road_service_area
DROP TABLE IF EXISTS ome2_igr_rt_rt_areactra_s ;
CREATE TABLE ome2_igr_rt_rt_areactra_s 
AS SELECT a.id_ptoctra, a.id_areactr, a.geom,
    b.nombre, b.tipo_infra
FROM igr_rt_rt_areactra_s a
INNER JOIN igr_rt_rt_puntoctra_p b
ON a.id_ptoctra = b.id_ptoctra;

-- Source table for road /!\ TO-DO
DROP TABLE IF EXISTS ome2_igr_rt_rt_vial_a;



-- Source table for railway_link
DROP TABLE IF EXISTS ome2_igr_rt_rt_tramoffcc_l;
CREATE TABLE ome2_igr_rt_rt_tramoffcc_l AS
SELECT a.id_tramo, a.tipo_tramo, a.ancho_via, a.electrific, a.n_vias, a.situacion, a.estadofis, a.titular, a.fuente, a.fecha_alta, a.alta_db, a.version,
    a.red_tent, a.uso_ppal, a.tipo_linea, a.geom,
    json_agg(json_build_object('id_lineafc', c.id_lineafc, 'nombre', c.nombre, 'fuente', c.fuente, 'tipo_linea', c.tipo_linea)) AS ome2_lineaffc
FROM igr_rt_rt_tramoffcc_l a
INNER JOIN igr_rt_rrt_tramoffcc_lineaffcc b ON a.id_tramo = b.id_tramo
INNER JOIN igr_rt_rt_lineaffcc_a c ON b.id_lineafc = c.id_lineafc
GROUP BY a.id_tramo, a.tipo_tramo, a.ancho_via, a.electrific, a.n_vias, a.situacion, a.estadofis, a.titular, a.fuente, a.fecha_alta, a.alta_db, a.version,
    a.red_tent, a.uso_ppal, a.tipo_linea, a.geom;

-- Source table for railway_station_area
DROP TABLE IF EXISTS ome2_igr_rt_rt_nodoffcc_p;
CREATE TABLE ome2_igr_rt_rt_nodoffcc_p AS SELECT * FROM igr_rt_rt_nodoffcc_p;
ALTER TABLE ome2_igr_rt_rt_nodoffcc_p ADD COLUMN intermodal INTEGER DEFAULT 0;
UPDATE ome2_igr_rt_rt_nodoffcc_p a SET intermodal = 1
FROM igr_rt_rt_conexion_a b
WHERE a.id_nodofc = b.id_nodo1 OR a.id_nodofc = b.id_nodo2;

DROP TABLE IF EXISTS ome2_igr_rt_rt_estacionffcc_p;
CREATE TABLE ome2_igr_rt_rt_estacionffcc_p AS
SELECT a.id_estfc, a.nombre, a.tipo_estfc, a.cod_est, a.tipo_uso, a.tipo_linea_est, a.geom,
    json_agg(json_build_object('id_nodofc', c.id_nodofc, 'tip_nodofc', c.tip_nodofc, 'intermodal', c.intermodal)) AS ome2_nodoffcc
FROM igr_rt_rt_estacionffcc_p a
INNER JOIN igr_rt_rrt_nodoffcc_estacionffcc b ON a.id_estfc = b.id_estfc
INNER JOIN ome2_igr_rt_rt_nodoffcc_p c ON b.id_nodofc = c.id_nodofc
GROUP BY a.id_estfc, a.nombre, a.tipo_estfc, a.cod_est, a.tipo_uso, a.tipo_linea_est, a.geom;

DROP TABLE IF EXISTS ome2_igr_rt_rt_areaffcc_s;
CREATE TABLE ome2_igr_rt_rt_areaffcc_s
AS SELECT a.id_estfc, a.id_areafc, a.fecha_alta, a.alta_db, a.version, a.tip_areafc, a.geom, b.nombre, b.tipo_estfc, b.cod_est, b.tipo_uso, b.ome2_nodoffcc 
FROM igr_rt_rt_areaffcc_s a
INNER JOIN ome2_igr_rt_rt_estacionffcc_p b
ON a.id_estfc = b.id_estfc;

-- Source table for aerodrome_area
DROP TABLE IF EXISTS ome2_igr_rt_rt_areaaereo_s ;
CREATE TABLE ome2_igr_rt_rt_areaaereo_s 
AS SELECT a.id_aerodro, a.id_area, a.tip_area, a.designador, a.longitud, a.anchura, a.comp_sup, a.tip_pista, a.geom,
    b.nombre, b.cod_iata, b.cod_icao, b.categoria, b.t_aerodro, b.uso,  b.estadofis
FROM igr_rt_rt_areaaereo_s a
INNER JOIN igr_rt_rt_aerodromo_p b
ON a.id_aerodro = b.id_aerodro;

-- Source table for port_area
DROP TABLE IF EXISTS ome2_igr_rt_rt_areamar_s ;
CREATE TABLE ome2_igr_rt_rt_areamar_s 
AS SELECT a.id_puerto, a.id_areamar, a.geom,
    b.nombre, b.cod_puerto, b.red_tent
FROM igr_rt_rt_areamar_s a
INNER JOIN igr_rt_rt_puerto_p b
ON a.id_puerto = b.id_puerto;
