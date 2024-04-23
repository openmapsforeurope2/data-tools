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