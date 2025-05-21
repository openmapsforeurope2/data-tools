---------------------------------------------
-- AIR TRANSPORT
---------------------------------------------
-- No property tables

---------------------------------------------
-- RAIL TRANSPORT
---------------------------------------------
DO $$ DECLARE
    inspireid_name TEXT := 'inspireid';
    networkref_name TEXT := 'networkreference_element';
    cs_name TEXT := 'tn';
    tb_array text[] := '{rail_railway_link}';
    att_tb_json JSONB := '{"rail_condition_of_facility":"{currentstatus}",
                            "rail_number_of_tracks":"{minmaxnumberoftracks,numberoftracks}",
                            "rail_railway_use":"{use}"}' ;
BEGIN
    EXECUTE ome2_get_inspire_attributes_equal (inspireid_name, networkref_name, cs_name, tb_array, att_tb_json);
END $$;

DO $$ DECLARE
    inspireid_name TEXT := 'inspireid';
    networkref_name TEXT := 'networkref_element';
    cs_name TEXT := 'tn';
    tb_array text[] := '{rail_railway_link}';
    att_tb_json JSONB := '{"rail_vertical_position":"{verticalposition}"}' ;
BEGIN
    EXECUTE ome2_get_inspire_attributes_equal_no_create (inspireid_name, networkref_name, cs_name, tb_array, att_tb_json);
END $$;

---------------------------------------------
-- ROAD TRANSPORT
---------------------------------------------

-- Road_link with proper fields
DO $$ DECLARE
    inspireid_name TEXT := 'inspireid';
    networkref_name TEXT := 'networkref_element';
    cs_name TEXT := 'tn';
    tb_array text[] := '{road_road_link}';
    att_tb_json JSONB := '{ "road_form_of_way":"{formofway}",
                            "road_functional_road_class":"{functionalclass}",
                            "road_road_surface_category":"{surfacecategory}",
                            "road_vertical_position":"{verticalposition}"}' ;
BEGIN
    EXECUTE ome2_get_inspire_attributes_equal (inspireid_name, networkref_name, cs_name, tb_array, att_tb_json);
END $$;


DO $$ DECLARE
    inspireid_name TEXT := 'inspireid';
    networkref_name TEXT := 'networkreference_element';
    cs_name TEXT := 'tn';
    tb_array text[] := '{road_road_link}';
    att_tb_json JSONB := '{"road_condition_of_facility":"{currentstatus}"}' ;
BEGIN
    EXECUTE ome2_get_inspire_attributes_equal_no_create (inspireid_name, networkref_name, cs_name, tb_array, att_tb_json);
END $$;


---------------------------------------------
-- WATERCOURSE LINK
---------------------------------------------

-- This function is slightly different from what is usually done because the networkref field in the target tables contains only part
-- of the inspireid field in the source table (the inspireid is a link ending with the value of the networkref id).
-- In order to optimize the calculations, a field containing only the part of the inspireid we are interested in is pre-calculated
-- and stored in a new inspireid_name attribute (here named 'ome2_inspireid_localid').

DO $$ DECLARE
    inspireid_name TEXT := 'ome2_inspireid_localid';
    networkref_name TEXT := 'localid';
    nat_inspireid TEXT := 'inspireid';
    cs_name TEXT := 'hy';
    tb_array text[] := '{net_watercourse_link}';
    att_tb_json JSONB := '{ "p_watercourse":"{geographicalname, hydroid, origin, persistence, tidal, level, lower, upper, width}"}' ;
    nat_tb TEXT;
    tb_name TEXT;
BEGIN
    -- Calculate ome2_inspireid_localid
    FOREACH tb_name IN ARRAY tb_array
    LOOP
        nat_tb := cs_name || '.' || tb_name;
        RAISE notice 'nat_tb = %', nat_tb;
        EXECUTE 'ALTER TABLE ' || nat_tb || ' ADD COLUMN ' || inspireid_name || ' character varying;';
        EXECUTE 'UPDATE ' || nat_tb || ' SET ' || inspireid_name || ' = reverse(SUBSTRING(reverse(inspireid), 0, POSITION(''/'' in reverse(' || nat_inspireid || '))));';
    END LOOP;
    EXECUTE ome2_get_inspire_attributes_equal (inspireid_name, networkref_name, cs_name, tb_array, att_tb_json);
END $$;