-- WATERCOURSE AREA

ALTER TABLE watercourse_area_double ADD COLUMN w_national_identifier_1 character varying;
ALTER TABLE watercourse_area_double ADD COLUMN w_national_identifier_2 character varying;
ALTER TABLE watercourse_area_double ADD COLUMN persistence_1 character varying;
ALTER TABLE watercourse_area_double ADD COLUMN persistence_2 character varying;
ALTER TABLE watercourse_area_double ADD COLUMN tidal_1 character varying;
ALTER TABLE watercourse_area_double ADD COLUMN tidal_2 character varying;
ALTER TABLE watercourse_area_double ADD COLUMN origin_1 character varying;
ALTER TABLE watercourse_area_double ADD COLUMN origin_2 character varying;
ALTER TABLE watercourse_area_double ADD COLUMN hydro_identifier_1 character varying;
ALTER TABLE watercourse_area_double ADD COLUMN hydro_identifier_2 character varying;

-- Calculate w_national_identifier_1 (country 1) and w_national_identifier_2 (country 2)
UPDATE watercourse_area_double SET w_national_identifier_1 = SUBSTRING(w_national_identifier, 1, POSITION('#' IN w_national_identifier)-1);
UPDATE watercourse_area_double SET w_national_identifier_2 = SUBSTRING(w_national_identifier, POSITION('#' IN w_national_identifier)+1);

-- Calculate attribute values for country 1 using watercourse_area as source
UPDATE watercourse_area_double a
SET persistence_1 = b.persistence, tidal_1 = b.tidal, origin_1 = b.origin, hydro_identifier_1 = b.hydro_identifier
FROM watercourse_area_init b
WHERE a.w_national_identifier_1 = b.w_national_identifier;

-- Calculate attribute values for country 2 using watercourse_area as source
UPDATE watercourse_area_double a
SET persistence_2 = b.persistence, tidal_2 = b.tidal, origin_2 = b.origin, hydro_identifier_2 = b.hydro_identifier
FROM watercourse_area_init b
WHERE a.w_national_identifier_2 = b.w_national_identifier;

-- Calculate attribute values for country 1 using standing_water as source
UPDATE watercourse_area_double a
SET persistence_1 = b.persistence, tidal_1 = b.tidal, origin_1 = b.origin, hydro_identifier_1 = b.hydro_identifier
FROM standing_water_init b
WHERE a.w_national_identifier_1 = b.w_national_identifier;

-- Calculate attribute values for country 2 using standing_water as source
UPDATE watercourse_area_double a
SET persistence_2 = b.persistence, tidal_2 = b.tidal, origin_2 = b.origin, hydro_identifier_2 = b.hydro_identifier
FROM standing_water_init b
WHERE a.w_national_identifier_2 = b.w_national_identifier;

-- Correct original attributes
DO $$ DECLARE
    att character varying;
    att_list text[] := '{persistence,tidal,origin,hydro_identifier}' ;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        EXECUTE 'UPDATE watercourse_area_double
            SET ' || att || ' = 
                CASE
                    WHEN ' || att || '_1 != ' || att || '_2 THEN ' || att || '_1 || ''#'' || ' || att || '_2
                    ELSE ' || att || '_1
                END
            ;';
    END LOOP;
END $$;

-- Correct attributes in the original table
DO $$ DECLARE
    att character varying;
    att_list text[] := '{persistence, tidal,origin,hydro_identifier}' ;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        EXECUTE 'UPDATE hy.watercourse_area a
            SET ' || att || ' = b.' || att || '
            FROM watercourse_area_double b
            WHERE a.objectid = b.objectid
            ;';
    END LOOP;
END $$;


-- STANDING_WATER
ALTER TABLE standing_water_double ADD COLUMN w_national_identifier_1 character varying;
ALTER TABLE standing_water_double ADD COLUMN w_national_identifier_2 character varying;
ALTER TABLE standing_water_double ADD COLUMN persistence_1 character varying;
ALTER TABLE standing_water_double ADD COLUMN persistence_2 character varying;
ALTER TABLE standing_water_double ADD COLUMN tidal_1 character varying;
ALTER TABLE standing_water_double ADD COLUMN tidal_2 character varying;
ALTER TABLE standing_water_double ADD COLUMN origin_1 character varying;
ALTER TABLE standing_water_double ADD COLUMN origin_2 character varying;
ALTER TABLE standing_water_double ADD COLUMN hydro_identifier_1 character varying;
ALTER TABLE standing_water_double ADD COLUMN hydro_identifier_2 character varying;

-- Calculate w_national_identifier_1 (country 1) and w_national_identifier_2 (country 2)
UPDATE standing_water_double SET w_national_identifier_1 = SUBSTRING(w_national_identifier, 1, POSITION('#' IN w_national_identifier)-1);
UPDATE standing_water_double SET w_national_identifier_2 = SUBSTRING(w_national_identifier, POSITION('#' IN w_national_identifier)+1);

-- Calculate attribute values for country 1 using standing_water as source
UPDATE standing_water_double a
SET persistence_1 = b.persistence, tidal_1 = b.tidal, origin_1 = b.origin, hydro_identifier_1 = b.hydro_identifier
FROM standing_water_init b
WHERE a.w_national_identifier_1 = b.w_national_identifier;

-- Calculate attribute values for country 2 using standing_water as source
UPDATE standing_water_double a
SET persistence_2 = b.persistence, tidal_2 = b.tidal, origin_2 = b.origin, hydro_identifier_2 = b.hydro_identifier
FROM standing_water_init b
WHERE a.w_national_identifier_2 = b.w_national_identifier;

-- Correct original attributes
DO $$ DECLARE
    att character varying;
    att_list text[] := '{persistence, tidal,origin,hydro_identifier}' ;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        EXECUTE 'UPDATE standing_water_double
            SET ' || att || ' = 
                CASE
                    WHEN ' || att || '_1 != ' || att || '_2 THEN ' || att || '_1 || ''#'' || ' || att || '_2
                    ELSE ' || att || '_1
                END
            ;';
    END LOOP;
END $$;

-- Correct attributes in the original table
DO $$ DECLARE
    att character varying;
    att_list text[] := '{persistence, tidal,origin,hydro_identifier}' ;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        EXECUTE 'UPDATE hy.standing_water a
            SET ' || att || ' = b.' || att || '
            FROM standing_water_double b
            WHERE a.objectid = b.objectid
            ;';
    END LOOP;
END $$;

-- WATERCOURSE_LINK
ALTER TABLE watercourse_link_double ADD COLUMN w_national_identifier_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN w_national_identifier_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN level_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN level_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN persistence_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN persistence_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN tidal_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN tidal_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN flow_direction_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN flow_direction_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN stream_order_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN stream_order_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN hydro_identifier_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN hydro_identifier_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN origin_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN origin_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN fictitious_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN fictitious_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN tent_network_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN tent_network_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN cemt_class_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN cemt_class_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN navigable_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN navigable_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN width_lower_range_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN width_lower_range_2 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN width_upper_range_1 character varying;
ALTER TABLE watercourse_link_double ADD COLUMN width_upper_range_2 character varying;


-- Calculate w_national_identifier_1 (country 1) and w_national_identifier_2 (country 2)
UPDATE watercourse_link_double SET w_national_identifier_1 = SUBSTRING(w_national_identifier, 1, POSITION('#' IN w_national_identifier)-1);
UPDATE watercourse_link_double SET w_national_identifier_2 = SUBSTRING(w_national_identifier, POSITION('#' IN w_national_identifier)+1);

-- Calculate attribute values for country 1 using watercourse_link as source
UPDATE watercourse_link_double a
SET level_1 = b.level,
    persistence_1 = b.persistence, 
    tidal_1 = b.tidal, 
    flow_direction_1 = b.flow_direction,
    stream_order_1 = b.stream_order,
    hydro_identifier_1 = b.hydro_identifier,
    origin_1 = b.origin, 
    fictitious_1 = b.fictitious,
    tent_network_1 = b.tent_network,
    cemt_class_1 = b.cemt_class,
    navigable_1 = b.navigable,
    width_lower_range_1 = b.width_lower_range,
    width_upper_range_1 = b.width_upper_range
FROM watercourse_link_init b
WHERE a.w_national_identifier_1 = b.w_national_identifier;

-- Calculate attribute values for country 2 using watercourse_link as source
UPDATE watercourse_link_double a
SET level_2 = b.level,
    persistence_2 = b.persistence, 
    tidal_2 = b.tidal, 
    flow_direction_2 = b.flow_direction,
    stream_order_2 = b.stream_order,
    hydro_identifier_2 = b.hydro_identifier,
    origin_2 = b.origin, 
    fictitious_2 = b.fictitious,
    tent_network_2 = b.tent_network,
    cemt_class_2 = b.cemt_class,
    navigable_2 = b.navigable,
    width_lower_range_2 = b.width_lower_range,
    width_upper_range_2 = b.width_upper_range
FROM watercourse_link_init b
WHERE a.w_national_identifier_2 = b.w_national_identifier;

-- Correct original attributes
DO $$ DECLARE
    att character varying;
    att_list text[] := '{level,persistence,tidal,flow_direction,stream_order,hydro_identifier,origin,fictitious,tent_network,cemt_class,navigable,width_lower_range,width_upper_range}' ;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        EXECUTE 'UPDATE watercourse_link_double
            SET ' || att || ' = 
                CASE
                    WHEN ' || att || '_1 != ' || att || '_2 THEN ' || att || '_1 || ''#'' || ' || att || '_2
                    ELSE ' || att || '_1
                END
            ;';
    END LOOP;
END $$;

-- Correct attributes in the original table
DO $$ DECLARE
    att character varying;
    att_list text[] := '{level,persistence,tidal,flow_direction,stream_order,hydro_identifier,origin,fictitious,tent_network,cemt_class,navigable,width_lower_range,width_upper_range}' ;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        EXECUTE 'UPDATE hy.watercourse_link a
            SET ' || att || ' = b.' || att || '
            FROM watercourse_link_double b
            WHERE a.objectid = b.objectid
            ;';
    END LOOP;
END $$;


-- ROAD_LINK
ALTER TABLE road_link_double ADD COLUMN w_national_identifier_1 character varying;
ALTER TABLE road_link_double ADD COLUMN w_national_identifier_2 character varying;
ALTER TABLE road_link_double ADD COLUMN form_of_way_1 character varying;
ALTER TABLE road_link_double ADD COLUMN form_of_way_2 character varying;
ALTER TABLE road_link_double ADD COLUMN functional_road_class_1 character varying;
ALTER TABLE road_link_double ADD COLUMN functional_road_class_2 character varying;
ALTER TABLE road_link_double ADD COLUMN vertical_position_1 character varying;
ALTER TABLE road_link_double ADD COLUMN vertical_position_2 character varying;
ALTER TABLE road_link_double ADD COLUMN vertical_level_1 character varying;
ALTER TABLE road_link_double ADD COLUMN vertical_level_2 character varying;
ALTER TABLE road_link_double ADD COLUMN tent_network_1 character varying;
ALTER TABLE road_link_double ADD COLUMN tent_network_2 character varying;
ALTER TABLE road_link_double ADD COLUMN road_surface_category_1 character varying;
ALTER TABLE road_link_double ADD COLUMN road_surface_category_2 character varying;
ALTER TABLE road_link_double ADD COLUMN traffic_flow_direction_1 character varying;
ALTER TABLE road_link_double ADD COLUMN traffic_flow_direction_2 character varying;
ALTER TABLE road_link_double ADD COLUMN access_restriction_1 character varying;
ALTER TABLE road_link_double ADD COLUMN access_restriction_2 character varying;
ALTER TABLE road_link_double ADD COLUMN speed_limit_1 character varying;
ALTER TABLE road_link_double ADD COLUMN speed_limit_2 character varying;
ALTER TABLE road_link_double ADD COLUMN condition_of_facility_1 character varying;
ALTER TABLE road_link_double ADD COLUMN condition_of_facility_2 character varying;
ALTER TABLE road_link_double ADD COLUMN national_road_code_1 character varying;
ALTER TABLE road_link_double ADD COLUMN national_road_code_2 character varying;
ALTER TABLE road_link_double ADD COLUMN european_route_number_1 character varying;
ALTER TABLE road_link_double ADD COLUMN european_route_number_2 character varying;

-- Calculate w_national_identifier_1 (country 1) and w_national_identifier_2 (country 2)
UPDATE road_link_double SET w_national_identifier_1 = SUBSTRING(w_national_identifier, 1, POSITION('#' IN w_national_identifier)-1);
UPDATE road_link_double SET w_national_identifier_2 = SUBSTRING(w_national_identifier, POSITION('#' IN w_national_identifier)+1);

-- Calculate attribute values for country 1 using road_link as source
UPDATE road_link_double a
SET form_of_way_1 = b.form_of_way,
    functional_road_class_1 = b.functional_road_class, 
    vertical_position_1 = b.vertical_position, 
    vertical_level_1 = b.vertical_level,
    tent_network_1 = b.tent_network,
    road_surface_category_1 = b.road_surface_category,
    traffic_flow_direction_1 = b.traffic_flow_direction, 
    access_restriction_1 = b.access_restriction,
    speed_limit_1 = b.speed_limit,
    condition_of_facility_1 = b.condition_of_facility,
    national_road_code_1 = b.national_road_code,
    european_route_number_1 = b.european_route_number
FROM road_link_init b
WHERE a.w_national_identifier_1 = b.w_national_identifier;

-- Calculate attribute values for country 2 using road_link as source
UPDATE road_link_double a
SET form_of_way_2 = b.form_of_way,
    functional_road_class_2 = b.functional_road_class, 
    vertical_position_2 = b.vertical_position, 
    vertical_level_2 = b.vertical_level,
    tent_network_2 = b.tent_network,
    road_surface_category_2 = b.road_surface_category,
    traffic_flow_direction_2 = b.traffic_flow_direction, 
    access_restriction_2 = b.access_restriction,
    speed_limit_2 = b.speed_limit,
    condition_of_facility_2 = b.condition_of_facility,
    national_road_code_2 = b.national_road_code,
    european_route_number_2 = b.european_route_number
FROM road_link_init b
WHERE a.w_national_identifier_2 = b.w_national_identifier;

-- Correct original attributes
DO $$ DECLARE
    att character varying;
    att_list text[] := '{form_of_way, functional_road_class, vertical_position, vertical_level, tent_network, road_surface_category, traffic_flow_direction, access_restriction, speed_limit, condition_of_facility, national_road_code, european_route_number}' ;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        EXECUTE 'UPDATE road_link_double
            SET ' || att || ' = 
                CASE
                    WHEN ' || att || '_1 != ' || att || '_2 THEN ' || att || '_1 || ''#'' || ' || att || '_2
                    ELSE ' || att || '_1
                END
            ;';
    END LOOP;
END $$;


UPDATE road_link_double 
SET maximum_single_axle_weight = '-32768#' || maximum_single_axle_weight WHERE maximum_single_axle_weight != '-32768';

UPDATE road_link_double 
SET maximum_total_weight = '-32768#' || maximum_total_weight WHERE maximum_total_weight != '-32768';


-- Correct attributes in the original table
DO $$ DECLARE
    att character varying;
    att_list text[] := '{form_of_way, functional_road_class, vertical_position, vertical_level, tent_network, road_surface_category, traffic_flow_direction, access_restriction, speed_limit, condition_of_facility, national_road_code, european_route_number}' ;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        EXECUTE 'UPDATE tn.road_link a
            SET ' || att || ' = b.' || att || '
            FROM road_link_double b
            WHERE a.objectid = b.objectid
            ;';
    END LOOP;
END $$;


-- NEW SOLUTION FOR CASE (same value provided by the two countries -> keep both values separated by #)
---- watercourse_area
DO $$ DECLARE
    att character varying;
    att_list text[] := '{persistence,tidal,origin,hydro_identifier}' ;
    update_query text;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        update_query:= 'UPDATE hy.watercourse_area SET ' || att || ' = ' || att || ' || ''#'' || ' || att || ' WHERE country LIKE ''%#%'' AND ' || att || ' NOT LIKE ''%#%'';';
        RAISE notice 'update_query = %', update_query;
        EXECUTE update_query;
     END LOOP;   
END $$;

---- standing_water
DO $$ DECLARE
    att character varying;
    att_list text[] := '{persistence,tidal,origin,hydro_identifier}' ;
    update_query text;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        update_query:= 'UPDATE hy.standing_water SET ' || att || ' = ' || att || ' || ''#'' || ' || att || ' WHERE country LIKE ''%#%'' AND ' || att || ' NOT LIKE ''%#%'';';
        RAISE notice 'update_query = %', update_query;
        EXECUTE update_query;
     END LOOP;   
END $$;

---- watercourse_link
DO $$ DECLARE
    att character varying;
    att_list text[] := '{level,persistence,tidal,flow_direction,stream_order,hydro_identifier,origin,fictitious,tent_network,cemt_class,navigable,width_lower_range,width_upper_range}' ;
    update_query text;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        update_query:= 'UPDATE hy.watercourse_link SET ' || att || ' = ' || att || ' || ''#'' || ' || att || ' WHERE country LIKE ''%#%'' AND ' || att || ' NOT LIKE ''%#%'';';
        RAISE notice 'update_query = %', update_query;
        EXECUTE update_query;
     END LOOP;   
END $$;

---- road_link
DO $$ DECLARE
    att character varying;
    att_list text[] := '{form_of_way, functional_road_class, vertical_position, vertical_level, tent_network, road_surface_category, traffic_flow_direction, access_restriction, speed_limit, condition_of_facility, national_road_code, european_route_number}' ;
    update_query text;
BEGIN
    FOREACH att IN ARRAY att_list
    LOOP
        update_query:= 'UPDATE tn.road_link SET ' || att || ' = ' || att || ' || ''#'' || ' || att || ' WHERE country LIKE ''%#%'' AND ' || att || ' NOT LIKE ''%#%'';';
        RAISE notice 'update_query = %', update_query;
        EXECUTE update_query;
     END LOOP;   
END $$;
