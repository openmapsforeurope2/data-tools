SELECT ign_gcms_create_reconciliations_table();

-- Historiser les tables pertinentes
DO $$ DECLARE
    r RECORD;
    cs character varying;
    arr_schema text[] := '{au,ib,hy,tn}' ;
BEGIN
    FOREACH cs IN ARRAY arr_schema
    LOOP
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = cs AND tablename not like '%_wh' AND tablename not like '%_h' AND tablename != 'administrative_hierarchy') 
        LOOP
            EXECUTE 'SELECT ign_gcms_create_history_triggers ( ''' || cs || '.' || quote_ident(r.tablename) || ''')';
        END LOOP;
    END LOOP;
END $$;


--------------------------------------------------------------------------------
-- Create function which will update regular tables
-- based on what was done on the work tables from the public schema.
-- Params:
-- - tb_name: table name
-- - sc_name: schema name
-- - idlist: list of modified objects' identifiers
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ign_update_from_working_table(tb_name TEXT, sc_name TEXT, id_field TEXT, id_list TEXT )
    RETURNS void AS $$
DECLARE
    field RECORD;
    array_fields text[];
    q text;
BEGIN
    q := 'UPDATE ' || sc_name || '.' || tb_name || ' SET ';
    FOR field IN (SELECT column_name FROM information_schema.columns WHERE column_name not like '%gcms%' AND column_name not like '%_lifespan_version' AND column_name != id_field AND table_name = tb_name AND table_schema = sc_name)
    LOOP
        q := q || quote_ident(field.column_name) || ' = ' || tb_name || '_w.' || quote_ident(field.column_name) || ',';
    END LOOP;
    --q:= SUBSTRING(q, 1, LENGTH(q)-1);
    q:= q || ' FROM ' || tb_name || '_w WHERE ' || sc_name || '.' || tb_name || '.' || id_field || ' = ' || tb_name || '_w.objectid AND ' || sc_name || '.' || tb_name || '.' || id_field ||  ' in ' || id_list || ';';
    EXECUTE q;
END 
$$ LANGUAGE plpgsql;