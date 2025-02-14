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

-- label
ALTER TABLE tn.road_node ADD COLUMN label character varying(255);
ALTER TABLE tn.road_node_h ADD COLUMN label character varying(255);
ALTER TABLE tn.road_node_wh ADD COLUMN label character varying(255);
ALTER TABLE road_node_w ADD COLUMN label character varying(255);

-----------------------------
--  railway_link
-----------------------------

-- min_max_track
ALTER TABLE tn.railway_link ADD COLUMN min_max_track character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN min_max_track character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN min_max_track character varying(255);
ALTER TABLE railway_link_w ADD COLUMN min_max_track character varying(255);

-- nominal_track_gauge
ALTER TABLE tn.railway_link ADD COLUMN nominal_track_gauge character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN nominal_track_gauge character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN nominal_track_gauge character varying(255);
ALTER TABLE railway_link_w ADD COLUMN nominal_track_gauge character varying(255);

-- track_gauge_category
ALTER TABLE tn.railway_link ADD COLUMN track_gauge_category character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN track_gauge_category character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN track_gauge_category character varying(255);
ALTER TABLE railway_link_w ADD COLUMN track_gauge_category character varying(255);

-- speed_class
ALTER TABLE tn.railway_link ADD COLUMN speed_class character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN speed_class character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN speed_class character varying(255);
ALTER TABLE railway_link_w ADD COLUMN speed_class character varying(255);

-- railway_use
ALTER TABLE tn.railway_link ADD COLUMN railway_use character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN railway_use character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN railway_use character varying(255);
ALTER TABLE railway_link_w ADD COLUMN railway_use character varying(255);

-- access_restriction
ALTER TABLE tn.railway_link ADD COLUMN access_restriction character varying(255);
ALTER TABLE tn.railway_link_h ADD COLUMN access_restriction character varying(255);
ALTER TABLE tn.railway_link_wh ADD COLUMN access_restriction character varying(255);
ALTER TABLE railway_link_w ADD COLUMN access_restriction character varying(255);

----------------------------------------------------
--  railway_station_area and railway_station_point
----------------------------------------------------

-- form_of_railway_station
ALTER TABLE tn.railway_station_area ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE tn.railway_station_area_h ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE tn.railway_station_area_wh ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE railway_station_area_w ADD COLUMN form_of_railway_station character varying(255);

ALTER TABLE tn.railway_station_point ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE tn.railway_station_point_h ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE tn.railway_station_point_wh ADD COLUMN form_of_railway_station character varying(255);
ALTER TABLE railway_station_point_w ADD COLUMN form_of_railway_station character varying(255);

----------------------------------------------------
--  aerodrome_area and aerodrome_point
----------------------------------------------------

-- condition_of_facility
ALTER TABLE tn.aerodrome_area ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE tn.aerodrome_area_h ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE tn.aerodrome_area_wh ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE aerodrome_area_w ADD COLUMN condition_of_facility character varying(255);

ALTER TABLE tn.aerodrome_point ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE tn.aerodrome_point_h ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE tn.aerodrome_point_wh ADD COLUMN condition_of_facility character varying(255);
ALTER TABLE aerodrome_point_w ADD COLUMN condition_of_facility character varying(255);

----------------------------------------------------
--  ferry_crossing
----------------------------------------------------

-- access_restriction
ALTER TABLE tn.ferry_crossing ADD COLUMN access_restriction character varying(255);
ALTER TABLE tn.ferry_crossing_h ADD COLUMN access_restriction character varying(255);
ALTER TABLE tn.ferry_crossing_wh ADD COLUMN access_restriction character varying(255);
ALTER TABLE ferry_crossing_w ADD COLUMN access_restriction character varying(255);