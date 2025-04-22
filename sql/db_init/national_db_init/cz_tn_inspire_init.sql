---------------------------------------------
-- AIR TRANSPORT
---------------------------------------------
DO $$ DECLARE
    inspireid_name TEXT := 'inspireid_localid';
    networkref_name TEXT := 'networkref';
    cs_name TEXT := 'tn';
    tb_array text[] := '{air_aerodrome_area, air_aerodrome_node, air_runway_area, air_taxiway_area, air_touch_down_lift_off}';
    att_tb_json JSONB := '{"air_access_restriction":"{restriction}",
                            "air_aerodrome_category":"{aerodromecategory}",
                            "air_aerodrome_type":"{aerodrometype}",
                            "air_element_length":"{length,length_uom}",
                            "air_element_width":"{width, width_uom}",
                            "air_field_elevation":"{altitude, altitude_uom}",
                            "air_surface_composition":"{surfacecomposition}",
                            "air_use_restriction":"{restriction}",
                            "air_vertical_position":"{verticalposition}"}' ;
BEGIN
    EXECUTE ome2_get_inspire_attributes (inspireid_name, networkref_name, cs_name, tb_array, att_tb_json);
END $$;

---------------------------------------------
-- RAIL TRANSPORT
---------------------------------------------
DO $$ DECLARE
    inspireid_name TEXT := 'inspireid_localid';
    networkref_name TEXT := 'networkref';
    cs_name TEXT := 'tn';
    tb_array text[] := '{rail_railway_link, rail_railway_node, rail_railway_station_area, rail_railway_station_node, rail_railway_yard_area}';
    att_tb_json JSONB := '{"rail_nominal_track_gauge":"{nominalgaugecategory}",
                            "rail_number_of_tracks":"{minmaxnumberoftracks,numberoftracks}",
                            "rail_owner_authority":"{authority_title, authority_date_date, authority_date_datetype }",
                            "rail_railway_class":"{railwayclass}",
                            "rail_railway_electrification":"{electrified, railwaypowermethod}",
                            "rail_railway_station_code":"{stationcode}",
                            "rail_railway_type":"{type}",
                            "rail_vertical_position":"{verticalposition}"}' ;
BEGIN
    EXECUTE ome2_get_inspire_attributes (inspireid_name, networkref_name, cs_name, tb_array, att_tb_json);
END $$;

---------------------------------------------
-- ROAD TRANSPORT
---------------------------------------------

-- Road_link with proper fields
DO $$ DECLARE
    inspireid_name TEXT := 'inspireid_localid';
    networkref_name TEXT := 'networkref';
    cs_name TEXT := 'tn';
    tb_array text[] := '{road_road_link}';
    att_tb_json JSONB := '{"road_form_of_way":"{formofway}",
                            "road_functional_road_class":"{functionalclass}",
                            "road_number_of_lanes":"{minmaxnumberoflanes, numberoflanes}",
                            "road_road_surface_category":"{surfacecategory}",
                            "road_road_width":"{width, width_uom}",
                            "road_vertical_position":"{verticalposition}"}' ;
BEGIN
    EXECUTE ome2_get_inspire_attributes_equal (inspireid_name, networkref_name, cs_name, tb_array, att_tb_json);
END $$;

-- Other feature classes
DO $$ DECLARE
    inspireid_name TEXT := 'inspireid_localid';
    networkref_name TEXT := 'networkref';
    cs_name TEXT := 'tn';
    tb_array text[] := '{road_road_node, road_road_service_area}';
    att_tb_json JSONB := '{"road_road_service_type":"{availablefacility, type}"}' ;
BEGIN
    EXECUTE ome2_get_inspire_attributes_equal (inspireid_name, networkref_name, cs_name, tb_array, att_tb_json);
END $$;


-- NUMEROS DE ROUTE sur ome2_road_road_link
ALTER TABLE tn.ome2_road_road_link ADD COLUMN ome2_road_road_nationalroadcode character varying(255);
ALTER TABLE tn.ome2_road_road_link ADD COLUMN ome2_road_e_road_europeanroutenumber character varying(255);

CREATE TABLE tn.ome2_road_road_link_sequence AS SELECT * FROM tn.road_road_link_sequence;
ALTER TABLE tn.ome2_road_road_link_sequence ADD COLUMN ome2_road_road_nationalroadcode character varying(255);
ALTER TABLE tn.ome2_road_road_link_sequence ADD COLUMN ome2_road_e_road_europeanroutenumber character varying(255);

UPDATE tn.ome2_road_road_link_sequence a
SET ome2_road_road_nationalroadcode = b.nationalroadcode
FROM tn.road_road b
WHERE a.road = b.inspireid_localid ;

UPDATE tn.ome2_road_road_link_sequence a
SET ome2_road_e_road_europeanroutenumber = b.europeanroutenumber
FROM tn.road_e_road b
WHERE a.eroad = b.inspireid_localid ;

with t as (
  select t1.roadlinksequence_id, t1.link as link, t2.ome2_road_road_nationalroadcode as nationalroadcode, t2.ome2_road_e_road_europeanroutenumber as europeanroutenumber
  from tn.road_road_link_sequence_link  as t1
  join tn.ome2_road_road_link_sequence as t2 on t2.inspireid_localid = t1.roadlinksequence_id
)
update tn.ome2_road_road_link trlink
set ome2_road_road_nationalroadcode = t.nationalroadcode, ome2_road_e_road_europeanroutenumber = t.europeanroutenumber
from t
where trlink.inspireid_localid = t.link;


---------------------------------------------
-- WATER TRANSPORT
---------------------------------------------
DO $$ DECLARE
    inspireid_name TEXT := 'inspireid_localid';
    networkref_name TEXT := 'networkref';
    cs_name TEXT := 'tn';
    cs_name TEXT := 'tn';
    tb_array text[] := '{water_buoy, water_fairway_area, water_port_area, water_waterway_link}';
    att_tb_json JSONB := '{"water_port_type":"{porttype}"}' ;
BEGIN
    EXECUTE ome2_get_inspire_attributes (inspireid_name, networkref_name, cs_name, tb_array, att_tb_json);
END $$;


-------------------------------------------------
-- RENAME GEOMETRY COLUMNS FOR MODEL TRANSFORMER
-------------------------------------------------
ALTER TABLE tn.ome2_rail_railway_node RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE tn.ome2_rail_railway_link RENAME COLUMN "CENTRELINE_GEOMETRY" TO geometry;
ALTER TABLE tn.ome2_rail_railway_station_area RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE tn.ome2_rail_railway_station_node RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE tn.ome2_rail_railway_yard_area RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE tn.ome2_road_road_link RENAME COLUMN "CENTRELINE_GEOMETRY" TO geometry;
ALTER TABLE tn.ome2_road_road_node RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE tn.ome2_road_road_service_area RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE tn.ome2_water_buoy RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE tn.ome2_water_fairway_area RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE tn.ome2_water_port_area RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE tn.ome2_water_waterway_link RENAME COLUMN "CENTRELINE_GEOMETRY" TO geometry;


--*******************************************
---------------------------------------------
-- HYDROGRAPHY THEME
---------------------------------------------
--*******************************************
DROP TABLE IF EXISTS hy.ome2_net_watercourse_link;
CREATE TABLE hy.ome2_net_watercourse_link AS SELECT unnest(string_to_array(relatedhydroobject, ',')) as "relatedhydroobject", fictitious, flowdirection, length, length_uom 
FROM hy.net_watercourse_link;
ALTER TABLE hy.ome2_net_watercourse_link ADD COLUMN relatedhydroobject_localid character varying;
UPDATE hy.ome2_net_watercourse_link SET relatedhydroobject_localid = SUBSTRING(relatedhydroobject, POSITION('.' IN relatedhydroobject)+1);


DO $$ DECLARE
    inspireid_name TEXT := 'inspireid_localid';
    networkref_name TEXT := 'relatedhydroobject';
    cs_name TEXT := 'hy';
    tb_array text[] := '{p_watercourse_linestring}';
    att_tb_json JSONB := '{"ome2_net_watercourse_link":"{flowdirection, fictitious, length, length_uom}"}';
BEGIN
    EXECUTE ome2_get_inspire_attributes_equal (inspireid_name, networkref_name, cs_name, tb_array, att_tb_json);
END $$;


-------------------------------------------------
-- RENAME GEOMETRY COLUMNS FOR MODEL TRANSFORMER
-------------------------------------------------
ALTER TABLE hy.net_hydro_node RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE hy.p_lock RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE hy.p_falls_linestring RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE hy.p_falls_point RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE hy.p_river_basin RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE hy.p_standing_water RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE hy.p_watercourse_polygon RENAME COLUMN "GEOMETRY" TO geometry;
ALTER TABLE hy.p_wetland RENAME COLUMN "GEOMETRY" TO geometry;