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
-- Add objects in history table
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ign_add_to_history_table(nomTable TEXT, id_list TEXT, numderrec integer)
    RETURNS void AS $BODY$

DECLARE
    schema_table text[];
    table_h text ;
    requete text ;
    colonnes text ;

BEGIN
    schema_table := ign_gcms_decompose_table_name(nomTable);
    table_h := schema_table[1] || '_h' ;

    requete := 'SELECT string_agg(quote_ident(attname), '','') FROM pg_attribute WHERE  attrelid = ''' || nomTable ||
               '''::regclass AND attnum > 0 AND NOT attisdropped GROUP BY attrelid';
    --RAISE NOTICE '%', requete;
    EXECUTE requete INTO colonnes;

    requete := 'INSERT INTO ' || quote_ident(schema_table[0]) || '.' || quote_ident(table_h) || '(' || colonnes || ', gcms_numrecmodif)' ||
               ' SELECT ' || colonnes || ', ' || numderrec ||
               ' FROM ' || quote_ident(schema_table[0]) || '.' || quote_ident(schema_table[1]) ||
               ' WHERE objectid IN ' || id_list;
    --RAISE NOTICE '%', requete;
    EXECUTE requete ;

    RETURN ;

END
$BODY$
LANGUAGE plpgsql ;