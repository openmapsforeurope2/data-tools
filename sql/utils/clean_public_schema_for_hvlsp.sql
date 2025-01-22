--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---------------------------- CLEAN PUBLIC SCHEMA -------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- This script can be used after creating a new version of the HVLSP from a 
-- dump/restore from a former version. It aims at removing all tables from the 
-- public schema except xxx_w and www_w_ids tables (and spatial_sys_ref).

DO $$ DECLARE
    r RECORD;
    cs character varying;
    arr_schema text[] := '{public}' ;
BEGIN
    --SELECT INTO arr_schema string_to_array('au','ib','hy','public','tn');
    FOREACH cs IN ARRAY arr_schema
    LOOP
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = cs AND tablename != 'spatial_ref_sys' AND tablename NOT LIKE ('%_w') AND tablename NOT LIKE ('%_w_ids') AND tablename != 'gcvs_lockfinevol' AND tablename != 'reconciliations') 
        LOOP
            RAISE notice 'tablename = %', tablename;
            --EXECUTE 'DROP TABLE IF EXISTS ' || cs || '.' || quote_ident(r.tablename) || ' CASCADE';
        END LOOP;
    END LOOP;
END $$;


-- Manage sequences
GRANT USAGE, SELECT ON SEQUENCE seqnumrec TO ome2_user; 
GRANT USAGE, SELECT ON SEQUENCE seqnumordrefinevol TO ome2_user; 