-- Supprimer les champs w_step et gcms_* de toutes les tables d'une base ome2
DO $$ DECLARE
    r RECORD;
    cs character varying;
    arr_schema text[] := '{au,ib,hy,tn}' ;
BEGIN
    FOREACH cs IN ARRAY arr_schema
    LOOP
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = cs AND tablename != 'spatial_ref_sys') 
        LOOP
            EXECUTE 'ALTER TABLE ' || cs || '.' || quote_ident(r.tablename) || ' DROP COLUMN IF EXISTS w_step, DROP COLUMN IF EXISTS gcms_numrec, DROP COLUMN IF EXISTS gcms_detruit, DROP COLUMN IF EXISTS gcms_date_creation, DROP COLUMN IF EXISTS gcms_date_modification, DROP COLUMN IF EXISTS gcms_date_destruction;';
        END LOOP;
    END LOOP;
END $$;


-- Delete destroyed objects v1
DO $$ DECLARE
    r RECORD;
    cs character varying;
    arr_schema text[] := '{au,ib,hy,tn}' ;
BEGIN
    FOREACH cs IN ARRAY arr_schema
    LOOP
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = cs AND tablename != 'spatial_ref_sys') 
        LOOP
            EXECUTE 'DELETE FROM ' || cs || '.' || quote_ident(r.tablename) || ' WHERE end_lifespan_version is not NULL;';
        END LOOP;
    END LOOP;
END $$;


-- Delete destroyed objects v2
DO $$ DECLARE
    r RECORD;
    cs character varying;
    arr_schema text[] := '{au,ib,hy,tn}' ;
BEGIN
    FOREACH cs IN ARRAY arr_schema
    LOOP
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = cs AND tablename != 'spatial_ref_sys' AND tablename != 'administrative_hierarchy') 
        LOOP
            RAISE notice 'tablename = %', r.tablename;
            EXECUTE 'DELETE FROM ' || cs || '.' || quote_ident(r.tablename) || ' WHERE gcms_detruit;';
        END LOOP;
    END LOOP;
END $$;