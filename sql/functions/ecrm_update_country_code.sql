------------------------------------------------------------------------------------------
-- Create function to correct country codes for area tables when data was provided by one 
-- producer for several countries/territories (e.g. Liechtenstein provided by Switzerland, 
-- Andorra provided by Spain).
-- The function creates an temporary table in the public schema and deletes it at the end
-- of the process.
-- Params:
-- - tb_name: table to be processed with schema (e.g. 'hy.watercourse_area)
-- - current_country: country code currently applied to all objects (e.g. 'es' or 'ch')
-- - new_country: country code of the second territory (e.g. 'ad' or 'li')
-- - where_clause: filter (default true)
------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ecrm_update_country_code_area(tb_name TEXT, current_country TEXT, new_country TEXT, where_clause TEXT = true )
    RETURNS void AS $$
DECLARE
    field RECORD;
    q text;
    tmp_table text;
BEGIN
    tmp_table := replace(tb_name, '.', '_') || '_' || current_country || '_' || new_country;

    EXECUTE 'DROP TABLE IF EXISTS ' || tmp_table || ';
        CREATE TABLE ' || tmp_table || ' AS SELECT a.objectid, a.country, a.geom FROM ' || tb_name || 
        ' a INNER JOIN au.administrative_unit_area_1 b
          ON ST_Intersects(a.geom, b.geom)
          WHERE NOT b.gcms_detruit AND NOT a.gcms_detruit AND a.country = ''' || current_country || ''' AND b.country = ''' || new_country || ''';';

    EXECUTE 'ALTER TABLE ' || tmp_table || ' ADD COLUMN inter_current real default -1;';
    EXECUTE 'ALTER TABLE ' || tmp_table || ' ADD COLUMN inter_new real default -1;';
    EXECUTE 'ALTER TABLE ' || tmp_table || ' ADD COLUMN dist_current real default -1;';
    EXECUTE 'ALTER TABLE ' || tmp_table || ' ADD COLUMN dist_new real default -1;';
    EXECUTE 'ALTER TABLE ' || tmp_table || ' ADD COLUMN new_country_code character varying (10);';

    EXECUTE 'UPDATE ' || tmp_table || ' a SET new_country_code = ''' || new_country || ''' 
        FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND b.country = ''' || new_country || ''' AND ST_Within(a.geom, b.geom);';

    EXECUTE 'UPDATE ' || tmp_table || ' a SET new_country_code = ''' || current_country || ''' 
        FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND b.country = ''' || current_country || ''' AND ST_Within(a.geom, b.geom);';

-- This is enough for most feature classes. The country attribution can be checked visually in QGIS and corrected manually if necessary. 
-- For feature classes which overlap international boundaries (i.e. those where edge-matching is applied), continue with the steps below.

-- *** For networks and areas
    -- For networks
    --UPDATE ' || tmp_table || ' a SET inter_new = ST_Length(ST_Intersection (a.geom, b.geom))
    --FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND new_country_code is NULL AND b.country = ''' || new_country || ''';

    --UPDATE ' || tmp_table || ' a SET inter_current = ST_Length(ST_Intersection (a.geom, b.geom))
    --FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND new_country_code is NULL AND b.country = ''' || current_country || ''';

    -- For areas
    EXECUTE 'UPDATE ' || tmp_table || ' a SET inter_new = ST_Area(ST_Intersection (a.geom, b.geom))
        FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND new_country_code is NULL AND b.country = ''' || new_country || ''';';

    EXECUTE 'UPDATE ' || tmp_table || ' a SET inter_current = ST_Area(ST_Intersection (a.geom, b.geom))
        FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND new_country_code is NULL AND b.country = ''' || current_country || ''';';

    -- Common for networks and areas
    EXECUTE 'UPDATE ' || tmp_table || '
        SET new_country_code =
            CASE
                WHEN inter_current >= inter_new AND inter_current > 0 THEN ''' || current_country || '''
                WHEN inter_new > inter_current AND inter_new > 0 THEN ''' || new_country || '''
            END
        WHERE new_country_code IS NULL;';

-- ** For all
    EXECUTE 'UPDATE ' || tmp_table || ' a SET dist_new = ST_Distance(a.geom, b.geom)
        FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND new_country_code is NULL AND b.country = ''' || new_country || ''';';

    EXECUTE 'UPDATE ' || tmp_table || ' a SET dist_current = ST_Distance(a.geom, b.geom)
        FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND new_country_code is NULL AND b.country = ''' || current_country || ''';';

    EXECUTE 'UPDATE ' || tmp_table || '
        SET new_country_code =
        CASE
            WHEN dist_current <= dist_new AND dist_current >= 0 THEN ''' || current_country || '''
            WHEN dist_new < dist_current AND dist_new >= 0 THEN ''' || new_country || '''
        END
        WHERE new_country_code IS NULL;';

--** Integration
    EXECUTE 'UPDATE ' || tb_name || ' a SET country = b.new_country_code
        FROM ' || tmp_table || ' b
        WHERE a.objectid = b.objectid and a.country != b.new_country_code AND (a.country = ''' || current_country || ''' OR a.country = ''' || new_country || ''');';
    
    EXECUTE 'DROP TABLE IF EXISTS ' || tmp_table || ';';

END;
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------------------------
-- Create function to correct country codes for linear tables when data was provided by one 
-- producer for several countries/territories (e.g. Liechtenstein provided by Switzerland, 
-- Andorra provided by Spain).
-- The function creates an temporary table in the public schema and deletes it at the end
-- of the process.
-- Params:
-- - tb_name: table to be processed with schema (e.g. 'hy.watercourse_area)
-- - current_country: country code currently applied to all objects (e.g. 'es' or 'ch')
-- - new_country: country code of the second territory (e.g. 'ad' or 'li')
-- - where_clause: filter (default true)
--------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ecrm_update_country_code_line(tb_name TEXT, current_country TEXT, new_country TEXT, where_clause TEXT = true )
    RETURNS void AS $$
DECLARE
    field RECORD;
    q text;
    tmp_table text;
BEGIN
    tmp_table := replace(tb_name, '.', '_') || '_' || current_country || '_' || new_country;

    EXECUTE 'DROP TABLE IF EXISTS ' || tmp_table || ';
        CREATE TABLE ' || tmp_table || ' AS SELECT a.objectid, a.country, a.geom FROM ' || tb_name || 
        ' a INNER JOIN au.administrative_unit_area_1 b
          ON ST_Intersects(a.geom, b.geom)
          WHERE NOT b.gcms_detruit AND NOT a.gcms_detruit AND a.country = ''' || current_country || ''' AND b.country = ''' || new_country || ''';';

    EXECUTE 'ALTER TABLE ' || tmp_table || ' ADD COLUMN inter_current real default -1;';
    EXECUTE 'ALTER TABLE ' || tmp_table || ' ADD COLUMN inter_new real default -1;';
    EXECUTE 'ALTER TABLE ' || tmp_table || ' ADD COLUMN dist_current real default -1;';
    EXECUTE 'ALTER TABLE ' || tmp_table || ' ADD COLUMN dist_new real default -1;';
    EXECUTE 'ALTER TABLE ' || tmp_table || ' ADD COLUMN new_country_code character varying (10);';

    EXECUTE 'UPDATE ' || tmp_table || ' a SET new_country_code = ''' || new_country || ''' 
        FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND b.country = ''' || new_country || ''' AND ST_Within(a.geom, b.geom);';

    EXECUTE 'UPDATE ' || tmp_table || ' a SET new_country_code = ''' || current_country || ''' 
        FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND b.country = ''' || current_country || ''' AND ST_Within(a.geom, b.geom);';

    -- For networks
    EXECUTE 'UPDATE ' || tmp_table || ' a SET inter_new = ST_Length(ST_Intersection (a.geom, b.geom))
        FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND new_country_code is NULL AND b.country = ''' || new_country || ''';';

    EXECUTE 'UPDATE ' || tmp_table || ' a SET inter_current = ST_Length(ST_Intersection (a.geom, b.geom))
    --FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND new_country_code is NULL AND b.country = ''' || current_country || ''';';

    -- Common for networks and areas
    EXECUTE 'UPDATE ' || tmp_table || '
        SET new_country_code =
            CASE
                WHEN inter_current >= inter_new AND inter_current > 0 THEN ''' || current_country || '''
                WHEN inter_new > inter_current AND inter_new > 0 THEN ''' || new_country || '''
            END
        WHERE new_country_code IS NULL;';

-- ** For all
    EXECUTE 'UPDATE ' || tmp_table || ' a SET dist_new = ST_Distance(a.geom, b.geom)
        FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND new_country_code is NULL AND b.country = ''' || new_country || ''';';

    EXECUTE 'UPDATE ' || tmp_table || ' a SET dist_current = ST_Distance(a.geom, b.geom)
        FROM au.administrative_unit_area_1 b WHERE NOT b.gcms_detruit AND new_country_code is NULL AND b.country = ''' || current_country || ''';';

    EXECUTE 'UPDATE ' || tmp_table || '
        SET new_country_code =
        CASE
            WHEN dist_current <= dist_new AND dist_current >= 0 THEN ''' || current_country || '''
            WHEN dist_new < dist_current AND dist_new >= 0 THEN ''' || new_country || '''
        END
        WHERE new_country_code IS NULL;';

--** Integration
    EXECUTE 'UPDATE ' || tb_name || ' a SET country = b.new_country_code
        FROM ' || tmp_table || ' b
        WHERE a.objectid = b.objectid and a.country != b.new_country_code AND (a.country = ''' || current_country || ''' OR a.country = ''' || new_country || ''');';

    EXECUTE 'DROP TABLE IF EXISTS ' || tmp_table || ';';

END;
$$ LANGUAGE plpgsql;





