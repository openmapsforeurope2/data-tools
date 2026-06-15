-- Add country key filled with country field value (including double values if they exist -> to be corrected with other queries)

DO $$ DECLARE
    cs_name TEXT := 'au';
    table_list JSONB := '{ "administrative_unit_area_1":"name",
                        "administrative_unit_area_2":"name",
                        "administrative_unit_area_3":"name",
                        "administrative_unit_area_4":"name",
                        "administrative_unit_area_5":"name",
                        "administrative_unit_area_6":"name",
						"administrative_hierarchy":"national_level_name",
						"maritime_zone":"name",
						"residence_of_authority":"name"
                        }' ;
	tb_name text;
    name_att text;
	update_query text;

BEGIN
	FOR tb_name, name_att IN SELECT * FROM jsonb_each_text(table_list)
    LOOP
		RAISE NOTICE 'table:%',tb_name;
		update_query:= 'UPDATE ' || cs_name || '.' || tb_name || ' t SET ' || name_att || ' = (
		  SELECT jsonb_agg(
			elem || jsonb_build_object(''country'', t.country)
		  )
		  FROM jsonb_array_elements(t.' || name_att || ') AS elem
		)
		WHERE ' || name_att || ' IS NOT NULL
		  AND jsonb_typeof(' || name_att || ') = ''array'';';
		  RAISE notice 'update_query = %', update_query;
		  EXECUTE update_query;
	  END LOOP;
END $$;


-- TN theme: reuse query above with this table
-- NB: when the query was launched on the full list, road_link/street_name was not processed. The query had to be relaunched on this table only.
table_list JSONB := '{ "aerodrome_area":"name",
                    "aerodrome_point":"name",
                    "ferry_crossing":"name",
                    "port_area":"name",
                    "port_point":"name",
                    "railway_line":"railway_line_name",
                    "railway_link":"railway_line_name",
                    "railway_station_area":"name",
                    "railway_station_point":"name",
                    "road_service_area":"name",
                    "road_service_point":"name",
                    "road": "road_name",
                    "road_link": "street_name",
                    "road_link": "road_name"
                    }' ;

-- HY theme: reuse query above with this table
table_list JSONB := '{ "dam_area":"name",
                    "dam_line":"name",
                    "dam_point":"name",
                    "drainage_basin":"name",
                    "falls_area":"name",
                    "falls_line":"name",
                    "falls_point":"name",
                    "glacier_snowfield":"name",
                    "hydro_node":"name",
                    "lock_area":"name",
                    "lock_line":"name",
                    "lock_point":"name",
                    "shore":"name",
                    "shoreline_construction_area":"name",
                    "shoreline_construction_line":"name",
                    "standing_water":"name",
                    "watercourse":"name",
                    "watercourse_area":"name",
                    "watercourse_link":"name"
                    }' ;


-- TO CORRECT DOUBLE COUNTRY CODES IN THE country KEY
-- Create copies of tables containing double country codes, with only these objects
DROP TABLE IF EXISTS road_link_double_street;
CREATE TABLE road_link_double_street AS SELECT * FROM tn.road_link WHERE country LIKE '%#%' AND street_label != 'void_unk';

DROP TABLE IF EXISTS road_link_double_road;
CREATE TABLE road_link_double_road AS SELECT * FROM tn.road_link WHERE country LIKE '%#%' AND road_label != 'void_unk';

DROP TABLE IF EXISTS watercourse_link_double;
CREATE TABLE watercourse_link_double AS SELECT * FROM hy.watercourse_link WHERE country LIKE '%#%' AND label != 'void_unk';

DROP TABLE IF EXISTS watercourse_area_double;
CREATE TABLE watercourse_area_double AS SELECT * FROM hy.watercourse_area WHERE country LIKE '%#%' AND label != 'void_unk';

DROP TABLE IF EXISTS standing_water_double;
CREATE TABLE standing_water_double AS SELECT * FROM hy.standing_water WHERE country LIKE '%#%' AND label != 'void_unk';

-- Use this query on each table and field name successively to correct double country codes
-- In each case, at least one country had the language field filled, so it was possible to deduce the country value
-- ad: void_unk
-- at: ger
-- be: void_unk
-- cz: ces
-- ch: void_unk
-- es: void_unk
-- fr: fre
-- li: void_unk
-- lu: void_unk

UPDATE standing_water_double t
SET name = s.new_names
FROM (
    SELECT objectid,
           jsonb_agg(
             CASE
               WHEN elem->>'language' = 'fre'
                 THEN jsonb_set(elem, '{country}', '"fr"', false)
               WHEN elem->>'language' = 'void_unk'
                 THEN jsonb_set(elem, '{country}', '"es"', false)
               ELSE elem
             END
           ) AS new_names
    FROM standing_water_double
    CROSS JOIN LATERAL jsonb_array_elements(name) AS elem
    WHERE name IS NOT NULL
      AND jsonb_typeof(name) = 'array'
      AND country = 'es#fr'
    GROUP BY objectid
) s
WHERE t.objectid = s.objectid;

-- Update original tables with join query (to performe successively on each table)
UPDATE hy.standing_water a
SET name = b.name
FROM standing_water_double b
WHERE a.objectid = b.objectid;