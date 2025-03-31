--------------------------------------------
--------------------------------------------
-------------------- TN --------------------
--------------------------------------------
--------------------------------------------
-----------------------------
--  road_node
-----------------------------

-- drop name
ALTER TABLE tn.road_node DROP COLUMN name;
ALTER TABLE tn.road_node_h DROP COLUMN name;
ALTER TABLE tn.road_node_wh DROP COLUMN name;
ALTER TABLE road_node_w DROP COLUMN name;

-- local_name
ALTER TABLE tn.road_node ADD COLUMN local_name character varying(255);
ALTER TABLE tn.road_node_h ADD COLUMN local_name character varying(255);
ALTER TABLE tn.road_node_wh ADD COLUMN local_name character varying(255);
ALTER TABLE road_node_w ADD COLUMN local_name character varying(255);

ALTER TABLE tn.road_node ALTER COLUMN local_name SET DEFAULT 'void_unk';
ALTER TABLE tn.road_node_h ALTER COLUMN local_name SET DEFAULT 'void_unk';
ALTER TABLE tn.road_node_wh ALTER COLUMN local_name SET DEFAULT 'void_unk';
ALTER TABLE road_node_w ALTER COLUMN local_name SET DEFAULT 'void_unk';


-- label
ALTER TABLE tn.road_node ADD COLUMN label character varying(255);
ALTER TABLE tn.road_node_h ADD COLUMN label character varying(255);
ALTER TABLE tn.road_node_wh ADD COLUMN label character varying(255);
ALTER TABLE road_node_w ADD COLUMN label character varying(255);

ALTER TABLE tn.road_node ALTER COLUMN label SET DEFAULT 'void_unk';
ALTER TABLE tn.road_node_h ALTER COLUMN label SET DEFAULT 'void_unk';
ALTER TABLE tn.road_node_wh ALTER COLUMN label SET DEFAULT 'void_unk';
ALTER TABLE road_node_w ALTER COLUMN label SET DEFAULT 'void_unk';

-----------------------------
--  railway_link
-----------------------------

-- min_max_track
ALTER TABLE tn.railway_link ADD COLUMN min_max_track character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN min_max_track character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN min_max_track character varying(255);
ALTER TABLE railway_link_w ADD COLUMN min_max_track character varying(255);

ALTER TABLE tn.railway_link ALTER COLUMN min_max_track SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_h ALTER COLUMN min_max_track SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_wh ALTER COLUMN min_max_track SET DEFAULT 'void_unk';
ALTER TABLE railway_link_w ALTER COLUMN min_max_track SET DEFAULT 'void_unk';

-- nominal_track_gauge
ALTER TABLE tn.railway_link ADD COLUMN nominal_track_gauge character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN nominal_track_gauge character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN nominal_track_gauge character varying(255);
ALTER TABLE railway_link_w ADD COLUMN nominal_track_gauge character varying(255);

ALTER TABLE tn.railway_link ALTER COLUMN nominal_track_gauge SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_h ALTER COLUMN nominal_track_gauge SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_wh ALTER COLUMN nominal_track_gauge SET DEFAULT 'void_unk';
ALTER TABLE railway_link_w ALTER COLUMN nominal_track_gauge SET DEFAULT 'void_unk';

-- track_gauge_category
ALTER TABLE tn.railway_link ADD COLUMN track_gauge_category character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN track_gauge_category character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN track_gauge_category character varying(255);
ALTER TABLE railway_link_w ADD COLUMN track_gauge_category character varying(255);

ALTER TABLE tn.railway_link ALTER COLUMN track_gauge_category SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_h ALTER COLUMN track_gauge_category SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_wh ALTER COLUMN track_gauge_category SET DEFAULT 'void_unk';
ALTER TABLE railway_link_w ALTER COLUMN track_gauge_category SET DEFAULT 'void_unk';

-- speed_class
ALTER TABLE tn.railway_link ADD COLUMN speed_class character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN speed_class character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN speed_class character varying(255);
ALTER TABLE railway_link_w ADD COLUMN speed_class character varying(255);

ALTER TABLE tn.railway_link ALTER COLUMN speed_class SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_h ALTER COLUMN speed_class SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_wh ALTER COLUMN speed_class SET DEFAULT 'void_unk';
ALTER TABLE railway_link_w ALTER COLUMN speed_class SET DEFAULT 'void_unk';

-- railway_use
ALTER TABLE tn.railway_link ADD COLUMN railway_use character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN railway_use character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN railway_use character varying(255);
ALTER TABLE railway_link_w ADD COLUMN railway_use character varying(255);

ALTER TABLE tn.railway_link ALTER COLUMN railway_use SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_h ALTER COLUMN railway_use SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_wh ALTER COLUMN railway_use SET DEFAULT 'void_unk';
ALTER TABLE railway_link_w ALTER COLUMN railway_use SET DEFAULT 'void_unk';

-- access_restriction
ALTER TABLE tn.railway_link ADD COLUMN access_restriction character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN access_restriction character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN access_restriction character varying(255);
ALTER TABLE railway_link_w ADD COLUMN access_restriction character varying(255);

ALTER TABLE tn.railway_link ALTER COLUMN access_restriction SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_h ALTER COLUMN access_restriction SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_link_wh ALTER COLUMN access_restriction SET DEFAULT 'void_unk';
ALTER TABLE railway_link_w ALTER COLUMN access_restriction SET DEFAULT 'void_unk';

----------------------------------------------------
--  railway_station_area and railway_station_point
----------------------------------------------------

-- form_of_railway_station
ALTER TABLE tn.railway_station_area ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE tn.railway_station_area_h ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE tn.railway_station_area_wh ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE railway_station_area_w ADD COLUMN form_of_railway_station character varying(255);

ALTER TABLE tn.railway_station_area ALTER COLUMN form_of_railway_station SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_station_area_h ALTER COLUMN form_of_railway_station SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_station_area_wh ALTER COLUMN form_of_railway_station SET DEFAULT 'void_unk';
ALTER TABLE railway_station_area_w ALTER COLUMN form_of_railway_station SET DEFAULT 'void_unk';


ALTER TABLE tn.railway_station_point ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE tn.railway_station_point_h ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE tn.railway_station_point_wh ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE railway_station_point_w ADD COLUMN form_of_railway_station character varying(255);

ALTER TABLE tn.railway_station_point ALTER COLUMN form_of_railway_station SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_station_point_h ALTER COLUMN form_of_railway_station SET DEFAULT 'void_unk';
ALTER TABLE tn.railway_station_point_wh ALTER COLUMN form_of_railway_station SET DEFAULT 'void_unk';
ALTER TABLE railway_station_point_w ALTER COLUMN form_of_railway_station SET DEFAULT 'void_unk';

----------------------------------------------------
--  aerodrome_area and aerodrome_point
----------------------------------------------------

-- condition_of_facility
ALTER TABLE tn.aerodrome_area ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE tn.aerodrome_area_h ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE tn.aerodrome_area_wh ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE aerodrome_area_w ADD COLUMN condition_of_facility character varying(255);

ALTER TABLE tn.aerodrome_area ALTER COLUMN condition_of_facility SET DEFAULT 'void_unk';
ALTER TABLE tn.aerodrome_area_h ALTER COLUMN condition_of_facility SET DEFAULT 'void_unk';
ALTER TABLE tn.aerodrome_area_wh ALTER COLUMN condition_of_facility SET DEFAULT 'void_unk';
ALTER TABLE aerodrome_area_w ALTER COLUMN condition_of_facility SET DEFAULT 'void_unk';

ALTER TABLE tn.aerodrome_point ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE tn.aerodrome_point_h ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE tn.aerodrome_point_wh ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE aerodrome_point_w ADD COLUMN condition_of_facility character varying(255);

ALTER TABLE tn.aerodrome_point ALTER COLUMN condition_of_facility SET DEFAULT 'void_unk';
ALTER TABLE tn.aerodrome_point_h ALTER COLUMN condition_of_facility SET DEFAULT 'void_unk';
ALTER TABLE tn.aerodrome_point_wh ALTER COLUMN condition_of_facility SET DEFAULT 'void_unk';
ALTER TABLE aerodrome_point_w ALTER COLUMN condition_of_facility SET DEFAULT 'void_unk';

----------------------------------------------------
--  ferry_crossing
----------------------------------------------------

-- access_restriction
ALTER TABLE tn.ferry_crossing ADD COLUMN access_restriction character varying(255);
ALTER TABLE tn.ferry_crossing_h ADD COLUMN access_restriction character varying(255);
ALTER TABLE tn.ferry_crossing_wh ADD COLUMN access_restriction character varying(255);
ALTER TABLE ferry_crossing_w ADD COLUMN access_restriction character varying(255);

ALTER TABLE tn.ferry_crossing ALTER COLUMN access_restriction SET DEFAULT 'void_unk';
ALTER TABLE tn.ferry_crossing_h ALTER COLUMN access_restriction SET DEFAULT 'void_unk';
ALTER TABLE tn.ferry_crossing_wh ALTER COLUMN access_restriction SET DEFAULT 'void_unk';
ALTER TABLE ferry_crossing_w ALTER COLUMN access_restriction SET DEFAULT 'void_unk';