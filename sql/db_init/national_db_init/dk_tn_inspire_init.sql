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
