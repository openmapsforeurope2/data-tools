UPDATE tn.road_link SET
    geom = road_link_w.geom,
    form_of_way = road_link_w.form_of_way
FROM road_link_w
WHERE tn.road_link.objectid = road_link_w.objectid 
AND tn.road_link.objectid in ('8a47ffd8-49ad-43cb-912b-94c3725c5842', '35f00071-6dc6-4e8c-9267-c1ca9ef33346');


SELECT * FROM road_link_w WHERE objectid = '8a47ffd8-49ad-43cb-912b-94c3725c5842';
SELECT * FROM tn.road_link WHERE objectid = '8a47ffd8-49ad-43cb-912b-94c3725c5842';



DO $$ DECLARE
    field RECORD;
    array_fields text[];
    q text;
BEGIN
    q := 'UPDATE tn.road_link SET ';
    FOR field IN (SELECT column_name FROM information_schema.columns WHERE column_name not like '%gcms%' AND column_name not like '%_lifespan_version' AND column_name != 'objectid' AND table_name = 'road_link' AND table_schema = 'tn')
    LOOP
        q := q || quote_ident(field.column_name) || ' = road_link_w.' || quote_ident(field.column_name) || ',';
    END LOOP;
    q:= SUBSTRING(q, 1, LENGTH(q)-1);
    q:= q || ' FROM road_link_w WHERE tn.road_link.objectid = road_link_w.objectid 
AND tn.road_link.objectid in (''48039fb4-a9f2-45b8-a9f5-9966257d3a1f'');';
    EXECUTE q;
END $$;



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
    q:= SUBSTRING(q, 1, LENGTH(q)-1);
    q:= q || ' FROM ' || tb_name || '_w WHERE ' || sc_name || '.' || tb_name || '.' || id_field || ' = ' || tb_name || '_w.objectid AND ' || sc_name || '.' || tb_name || '. || id_field ||  in ' || id_list || ';';
    EXECUTE q;
END 
$$ LANGUAGE plpgsql;

SELECT ign_update_from_working_table('road_link', 'tn', '(''8a47ffd8-49ad-43cb-912b-94c3725c5842'')' );

SELECT column_name FROM information_schema.columns WHERE table_name = 'road_link' AND table_schema = 'tn';