-- GENERAL FUNCTION - TO BE REPLACED WITH ome2_get_inspire_attributes_equal?
-- This function was used for all modes except road for which it took far too long to run (more than 400h for road_link).
-- It seems that networkref actually holds a single attribute value, so there is probably no need to check with LIKE

CREATE OR REPLACE FUNCTION ome2_get_inspire_attributes (inspireid_name text, networkref_name text, cs_name text, tb_array text[], att_tb_json JSONB)
RETURNS VOID AS $$
DECLARE
    tb_name TEXT;
    ome2_tb TEXT;
    ome2_field TEXT;
    _key   text;
    _value text[];
    _att_value text;
    alter_query text;
    update_query text;
BEGIN
    --SELECT INTO arr_schema string_to_array('au','ib','hy','public','tn');
    FOREACH tb_name IN ARRAY tb_array
    LOOP
        ome2_tb := cs_name || '.ome2_' || tb_name;
        EXECUTE 'DROP TABLE IF EXISTS ' || ome2_tb || ';';
        EXECUTE 'CREATE TABLE ' || ome2_tb || ' AS SELECT * FROM ' || cs_name || '.' || tb_name || ';';
        FOR _key, _value IN SELECT * FROM jsonb_each_text(att_tb_json)
        LOOP
            FOREACH _att_value in ARRAY _value
            LOOP
                ome2_field := 'ome2' || SUBSTRING(_key, POSITION('_' IN _key)) || '_' || _att_value;

                alter_query := 'ALTER TABLE ' || ome2_tb || ' ADD COLUMN ' || ome2_field || ' character varying(255);';
                EXECUTE alter_query;

                update_query := 'UPDATE ' || ome2_tb || ' a SET ' || ome2_field || ' = b.' || _att_value || ' FROM ' || cs_name || '.' || _key || ' b WHERE b.' || networkref_name || '::text LIKE ''%'' || a.' || inspireid_name || '::text || ''%'';';
                RAISE notice 'update_query = %', update_query;
                EXECUTE update_query;
            END LOOP;
        END LOOP;
    END LOOP;
END
$$ LANGUAGE plpgsql;


-- GENERAL FUNCTION with EQUAL instead of LIKE (used for road transport)
CREATE OR REPLACE FUNCTION ome2_get_inspire_attributes_equal (inspireid_name text, networkref_name text, cs_name text, tb_array text[], att_tb_json JSONB)
RETURNS VOID AS $$
DECLARE
    tb_name TEXT;
    ome2_tb TEXT;
    ome2_field TEXT;
    _key   text;
    _value text[];
    _att_value text;
    alter_query text;
    update_query text;
BEGIN
    --SELECT INTO arr_schema string_to_array('au','ib','hy','public','tn');
    FOREACH tb_name IN ARRAY tb_array
    LOOP
        ome2_tb := cs_name || '.ome2_' || tb_name;
        EXECUTE 'DROP TABLE IF EXISTS ' || ome2_tb || ';';
        EXECUTE 'CREATE TABLE ' || ome2_tb || ' AS SELECT * FROM ' || cs_name || '.' || tb_name || ';';
        FOR _key, _value IN SELECT * FROM jsonb_each_text(att_tb_json)
        LOOP
            FOREACH _att_value in ARRAY _value
            LOOP
                ome2_field := 'ome2' || SUBSTRING(_key, POSITION('_' IN _key)) || '_' || _att_value;

                alter_query := 'ALTER TABLE ' || ome2_tb || ' ADD COLUMN ' || ome2_field || ' character varying(255);';
                EXECUTE alter_query;

                update_query := 'UPDATE ' || ome2_tb || ' a SET ' || ome2_field || ' = b.' || _att_value || ' FROM ' || cs_name || '.' || _key || ' b WHERE b.' || networkref_name || '::text = a.' || inspireid_name || '::text ;';
                RAISE notice 'update_query = %', update_query;
                EXECUTE update_query;
            END LOOP;
        END LOOP;
    END LOOP;
END
$$ LANGUAGE plpgsql;



-- GENERAL FUNCTION with EQUAL instead of LIKE (used for road transport) on an EXISTING TABLE
CREATE OR REPLACE FUNCTION ome2_get_inspire_attributes_equal_no_create (inspireid_name text, networkref_name text, cs_name text, tb_array text[], att_tb_json JSONB)
RETURNS VOID AS $$
DECLARE
    tb_name TEXT;
    ome2_tb TEXT;
    ome2_field TEXT;
    _key   text;
    _value text[];
    _att_value text;
    alter_query text;
    update_query text;
BEGIN
    --SELECT INTO arr_schema string_to_array('au','ib','hy','public','tn');
    FOREACH tb_name IN ARRAY tb_array
    LOOP
        ome2_tb := cs_name || '.ome2_' || tb_name;
        --EXECUTE 'DROP TABLE IF EXISTS ' || ome2_tb || ';';
        --EXECUTE 'CREATE TABLE ' || ome2_tb || ' AS SELECT * FROM ' || cs_name || '.' || tb_name || ';';
        FOR _key, _value IN SELECT * FROM jsonb_each_text(att_tb_json)
        LOOP
            FOREACH _att_value in ARRAY _value
            LOOP
                ome2_field := 'ome2' || SUBSTRING(_key, POSITION('_' IN _key)) || '_' || _att_value;

                alter_query := 'ALTER TABLE ' || ome2_tb || ' ADD COLUMN ' || ome2_field || ' character varying(255);';
                EXECUTE alter_query;

                update_query := 'UPDATE ' || ome2_tb || ' a SET ' || ome2_field || ' = b.' || _att_value || ' FROM ' || cs_name || '.' || _key || ' b WHERE b.' || networkref_name || '::text = a.' || inspireid_name || '::text ;';
                RAISE notice 'update_query = %', update_query;
                EXECUTE update_query;
            END LOOP;
        END LOOP;
    END LOOP;
END
$$ LANGUAGE plpgsql;


-- GENERAL FUNCTION with EQUAL instead of LIKE (used for road transport)
CREATE OR REPLACE FUNCTION ome2_get_inspire_attributes_equal_uri (inspireid_name text, networkref_name text, cs_name text, tb_array text[], att_tb_json JSONB)
RETURNS VOID AS $$
DECLARE
    tb_name TEXT;
    ome2_tb TEXT;
    ome2_field TEXT;
    _key   text;
    _value text[];
    _att_value text;
    alter_query text;
    update_query text;
BEGIN
    --SELECT INTO arr_schema string_to_array('au','ib','hy','public','tn');
    FOREACH tb_name IN ARRAY tb_array
    LOOP
        ome2_tb := cs_name || '.ome2_' || tb_name;
        EXECUTE 'DROP TABLE IF EXISTS ' || ome2_tb || ';';
        EXECUTE 'CREATE TABLE ' || ome2_tb || ' AS SELECT * FROM ' || cs_name || '.' || tb_name || ';';
        EXECUTE 'ALTER TABLE ' || ome2_tb || ' ADD COLUMN ' || inspireid_name || '_ome2 character varying;';
        EXECUTE 'UPDATE ' || ome2_tb || ' SET ' || inspireid_name || '_ome2 = SUBSTRING()';
        FOR _key, _value IN SELECT * FROM jsonb_each_text(att_tb_json)
        LOOP
            FOREACH _att_value in ARRAY _value
            LOOP
                ome2_field := 'ome2' || SUBSTRING(_key, POSITION('_' IN _key)) || '_' || _att_value;

                alter_query := 'ALTER TABLE ' || ome2_tb || ' ADD COLUMN ' || ome2_field || ' character varying(255);';
                EXECUTE alter_query;

                update_query := 'UPDATE ' || ome2_tb || ' a SET ' || ome2_field || ' = b.' || _att_value || ' FROM ' || cs_name || '.' || _key || ' b WHERE b.' || networkref_name || ' = a.' || inspireid_name || ';';
                RAISE notice 'update_query = %', update_query;
                EXECUTE update_query;
            END LOOP;
        END LOOP;
    END LOOP;
END
$$ LANGUAGE plpgsql;