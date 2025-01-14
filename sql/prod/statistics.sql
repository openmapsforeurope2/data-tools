SELECT count(*), form_of_way FROM tn.road_link WHERE country = 'ch' GROUP BY form_of_way;
SELECT count(*), functional_road_class FROM tn.road_link WHERE country = 'ch' GROUP BY functional_road_class;
SELECT count(*), number_of_lanes FROM tn.road_link WHERE country = 'ch' GROUP BY number_of_lanes;
SELECT count(*), vertical_position FROM tn.road_link WHERE country = 'ch' GROUP BY vertical_position;
SELECT count(*), vertical_level FROM tn.road_link WHERE country = 'ch' GROUP BY vertical_level;
SELECT count(*), road_surface_category FROM tn.road_link WHERE country = 'ch' GROUP BY road_surface_category;
SELECT count(*), traffic_flow_direction FROM tn.road_link WHERE country = 'ch' GROUP BY traffic_flow_direction;
SELECT count(*), access_restriction FROM tn.road_link WHERE country = 'ch' GROUP BY access_restriction;
SELECT count(*), condition_of_facility FROM tn.road_link WHERE country = 'ch' GROUP BY condition_of_facility;