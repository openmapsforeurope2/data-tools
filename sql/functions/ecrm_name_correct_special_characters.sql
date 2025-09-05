-- Function to replace special characters in jsonb field names
-- 2 queries are applied:
-- * the first query removes double backslashes
-- * the second query replaces series of characters indicated as keys in the char_conversion jsonb file with the corresponding values.
-- PARAMETERS:
-- cs_name: schema name
-- table_list: jsonb value with a list of tables to process and, for each, the name field to correct
-- char_conversion: reference jsonb indicating the characters to replace and the values to apply
-- where_clause: filter the data on which the queries should be applied
CREATE OR REPLACE FUNCTION public.ecrm_name_correct_special_characters(	cs_name TEXT, table_list jsonb, char_conversion jsonb,  where_clause TEXT = true)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    tb_name text;
    name_att text;
    _key text;
    _value text;
    alter_query text;
    update_query text;
    update_query1 text;
BEGIN
        FOR tb_name, name_att IN SELECT * FROM jsonb_each_text(table_list)
        LOOP
            FOR _key, _value IN SELECT * FROM jsonb_each_text(char_conversion)
            LOOP
                update_query1 := 'UPDATE ' || cs_name || '.' || tb_name || ' SET ' || name_att || ' = REPLACE(' || name_att || '::text, ''\\'', '''' )::json where ' || name_att || '::text like ''%\\%'' AND ' || where_clause || ';';
                update_query := 'UPDATE ' || cs_name || '.' || tb_name || ' SET ' || name_att || ' = REPLACE(' || name_att || '::text, ''' || _key ||''', ''' || _value ||''' )::json where ' || name_att || '::text like ''%' || _key ||'%'' AND ' || where_clause || ';';
                
                RAISE notice 'update_query1 = %', update_query1;
                EXECUTE update_query1;

                RAISE notice 'update_query = %', update_query;
                EXECUTE update_query;
            END LOOP;
        END LOOP;
END
$BODY$;





-- EXAMPLE on the AU theme
DO $$ DECLARE
    cs_name TEXT := 'au';

    table_list JSONB := '{ "administrative_unit_area_1":"name",
                        "administrative_unit_area_2":"name",
                        "administrative_unit_area_3":"name",
                        "administrative_unit_area_4":"name",
                        "administrative_unit_area_5":"name",
                        "administrative_unit_area_6":"name"
                        }' ;
    char_conversion JSONB := '{
        "u001a": "",
        "u0081": "",
        "u008d": "",
        "u00a0": " ",
        "u00a1": "¡",
        "u00a5": "¥",
        "u00a9": "©",
        "u00aa": "ª",
        "u00ad": "",
        "u00b0": "°",
        "u00b1": "±",
        "u00b3": "³",
        "u00b4": "´",
        "u00b7": "l·",
        "u00ba": "º",     
        "u00c0": "À",
        "u00c1": "Á",
        "u00c2": "Â",
        "u00c3": "Ã",
        "u00c4": "Ä",
        "u00c5": "Å",
        "u00c6": "Æ",
        "u00c7": "Ç",
        "u00c8": "È",
        "u00c9": "É",
        "u00ca": "Ê",
        "u00cb": "Ë",
        "u00cc": "Ì",
        "u00cd": "Í",
        "u00ce": "Î",
        "u00cf": "Ï",
        "u00d1": "Ñ",
        "u00d2": "Ò",
        "u00d3": "Ó",
        "u00d4": "Ô",   
        "u00d6": "Ö",
        "u00d9": "Ù",
        "u00dc": "Ü",
        "u00df": "ß",
        "u00e1": "á",
        "u00e3": "ã",
        "u00e5": "å",
        "u00e6": "æ",
        "u00ed": "í",
        "u00ec": "ì",
        "u00f1": "ñ",
        "u00f2": "ò",
        "u00f3": "ó",
        "u00f5": "õ",
        "u00f8": "ø",
        "u00fa": "ú",
        "u00ff": "ÿ",
        "u0081": "",
        "u0092": "",
        "u1ebd": "ẽ",
        "u0105": "ą",
        "u010e": "Ď",
        "u0111": "đ",
        "u0119": "ę",
        "u0129": "ĩ",
        "u013d": "Ľ",
        "u0142": "ł",
        "u0143": "Ń",
        "u014b": "ŋ",
        "u015a": "Ś",
        "u0151": "ő",
        "u0152": "Œ",
        "u0153": "œ",  
        "u0164": "Ť",
        "u0169": "ũ",
        "u0170": "Ű", 
        "u0171": "ű",
        "u0197": "Ɨ",
        "u0268": "ɨ",
        "u2018": "‘",
        "u2019": "’",
        "u2021": "‡"
    }';
BEGIN
    EXECUTE ecrm_name_correct_special_characters (cs_name, table_list, char_conversion, 'country = ''es''');
END $$;

-- AU theme
table_list JSONB := '{ "administrative_unit_area_1":"name",
                    "administrative_unit_area_2":"name",
                    "administrative_unit_area_3":"name",
                    "administrative_unit_area_4":"name",
                    "administrative_unit_area_5":"name",
                    "administrative_unit_area_6":"name"
                    }' ;

-- TN theme
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

-- HY theme
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

link_conversion JSONB := '{
    "http://inspire.ec.europa.eu/codelist/NativenessValue/endonym": "endonym",
    "http://inspire.ec.europa.eu/codelist/NativenessValue/exonym": "exonym",
    "http://inspire.ec.europa.eu/codelist/NameStatusValue/other": "other",
    "http://inspire.ec.europa.eu/codelist/NameStatusValue/historical": "historical",
    "http://inspire.ec.europa.eu/codelist/NameStatusValue/official": "official",
    "http://inspire.ec.europa.eu/codelist/NameStatusValue/standardised": "standardised",
    "Latn": "latn"
    };
 
    

-- Control query
SELECT  name, label  FROM au.administrative_unit_area_6 WHERE name::text LIKE '%\\%' OR name::text LIKE '%u0%' OR name::text LIKE '%http%';
