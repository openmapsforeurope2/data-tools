--------------------------------------------------------------------------------
-- Create function to update the label field
-- based on the order indicated in the name JSON field.
-- Params:
-- - tb_name: table name
-- - name_field: JSON field name
-- - label_field: Text label field to be filled automatically
-- - where_clause: filter
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_label_from_name(tb_name TEXT, name_field TEXT, label_field TEXT, where_clause TEXT = true )
    RETURNS void AS $$
DECLARE
    field RECORD;
    q text;
BEGIN

    EXECUTE 'UPDATE ' || tb_name || ' AS main
        SET ' || label_field || ' = sub.label_final_preview
        FROM (
        SELECT
            objectid,
            string_agg(spelling, ''#'' ORDER BY min_ordinality) AS label_final_preview
        FROM (
            SELECT
            objectid,
            elem->>''spelling'' AS spelling,
            MIN(ordinality) AS min_ordinality
            FROM ' || tb_name || ',
            LATERAL jsonb_array_elements(' || name_field || ') WITH ORDINALITY AS arr(elem, ordinality)
            WHERE ' || where_clause || ' AND (elem->>''display'')::integer > 0 
            GROUP BY objectid, elem->>''spelling''
        ) AS dedup
        GROUP BY objectid
        ) AS sub
        WHERE main.objectid = sub.objectid;';

END;
$$ LANGUAGE plpgsql;



--------------------------------------------------------------------------------
-- Create function to update the label field
-- for a whole schema.
-- Params:
-- - sc_name: schema name
-- - where_clause: filter
--------------------------------------------------------------------------------
-- NE FONCTIONNE PAS !!!!!!!!!!!!!!!!!!!
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.update_label_for_schema(arr_schema text[], where_clause TEXT );
CREATE OR REPLACE FUNCTION public.update_label_for_schema_au(where_clause TEXT )
    RETURNS void AS $$
DECLARE
    r RECORD;
    tb character varying;
    q text;
    arr_tables text[] := '{administrative_unit_area_1,administrative_unit_area_2,administrative_unit_area_3,administrative_unit_area_4,administrative_unit_area_5,administrative_unit_area_6,maritime_zone}';
BEGIN
    --SELECT INTO arr_schema string_to_array('au','ib','hy','public','tn');
    FOREACH tb IN ARRAY arr_tables
    LOOP
        FOR r IN (SELECT tb FROM pg_tables WHERE schemaname = 'au' AND tablename != 'spatial_ref_sys') 
        LOOP        
            -- CONTINUE WHEN quote_ident(r.tb) = ANY(arr_tables_exceptions0);
            q := 'SELECT update_label_from_name(''au.' || quote_ident(r.tb) || ''', ''name'', ''label'', ''' || where_clause || ''');';
            RAISE notice 'q = %', q;
            EXECUTE q;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;