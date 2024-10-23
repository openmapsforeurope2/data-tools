-- au.administrative_unit_area_2
UPDATE au.administrative_unit_area_2 a
SET name = 
    CASE 
    WHEN b.namelocal = b.namefre THEN
        jsonb_build_array(                                                         
            jsonb_build_object(
                'script', 'latn',
                'display', '1'::INT,
                'language', 'fre',       
                'spelling', b.namefre,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namefre
            ),
            jsonb_build_object(     
                'script', 'latn',
                'display', '0'::INT,
                'language', 'dut',
                'spelling', b.namedut,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namedut
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '0'::INT,
                'language', 'ger',
                'spelling', b.nameger,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.nameger
                )
            )
     WHEN b.namelocal = b.namedut THEN
        jsonb_build_array(                                                         
            jsonb_build_object(
                'script', 'latn',
                'display', '1'::INT,
                'language', 'dut',       
                'spelling', b.namedut,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namedut
            ),
            jsonb_build_object(     
                'script', 'latn',
                'display', '0'::INT,
                'language', 'fre',
                'spelling', b.namefre,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namefre
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '0'::INT,
                'language', 'ger',
                'spelling', b.nameger,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.nameger
                )
            )
      ELSE a.name
      END
    FROM au.administrative_unit_area_2, region b
    WHERE a.country = 'be' AND a.national_code = b.niscode 
;


-- au.administrative_unit_area_3
UPDATE au.administrative_unit_area_3 a
SET name = 
    CASE 
    WHEN b.namelocal = b.namefre THEN
        jsonb_build_array(                                                         
            jsonb_build_object(
                'script', 'latn',
                'display', '1'::INT,
                'language', 'fre',       
                'spelling', b.namefre,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namefre
            ),
            jsonb_build_object(     
                'script', 'latn',
                'display', '0'::INT,
                'language', 'dut',
                'spelling', b.namedut,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namedut
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '0'::INT,
                'language', 'ger',
                'spelling', b.nameger,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.nameger
                )
            )
     WHEN b.namelocal = b.namedut THEN
        jsonb_build_array(                                                         
            jsonb_build_object(
                'script', 'latn',
                'display', '1'::INT,
                'language', 'dut',       
                'spelling', b.namedut,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namedut
            ),
            jsonb_build_object(     
                'script', 'latn',
                'display', '0'::INT,
                'language', 'fre',
                'spelling', b.namefre,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namefre
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '0'::INT,
                'language', 'ger',
                'spelling', b.nameger,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.nameger
                )
            )
      ELSE a.name
      END
    FROM au.administrative_unit_area_3, province b
    WHERE a.country = 'be' AND a.national_code = b.niscode 
;


-- au.administrative_unit_area_4
UPDATE au.administrative_unit_area_4 a
SET name = 
    CASE 
    WHEN b.namelocal = b.namefre THEN
        jsonb_build_array(                                                         
            jsonb_build_object(
                'script', 'latn',
                'display', '1'::INT,
                'language', 'fre',       
                'spelling', b.namefre,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namefre
            ),
            jsonb_build_object(     
                'script', 'latn',
                'display', '0'::INT,
                'language', 'dut',
                'spelling', b.namedut,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namedut
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '0'::INT,
                'language', 'ger',
                'spelling', b.nameger,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.nameger
                )
            )
     WHEN b.namelocal = b.namedut THEN
        jsonb_build_array(                                                         
            jsonb_build_object(
                'script', 'latn',
                'display', '1'::INT,
                'language', 'dut',       
                'spelling', b.namedut,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namedut
            ),
            jsonb_build_object(     
                'script', 'latn',
                'display', '0'::INT,
                'language', 'fre',
                'spelling', b.namefre,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namefre
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '0'::INT,
                'language', 'ger',
                'spelling', b.nameger,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.nameger
                )
            )
      ELSE a.name
      END
    FROM au.administrative_unit_area_4, arrondissement b
    WHERE a.country = 'be' AND a.national_code = b.niscode 
;

-- au.administrative_unit_area_5
UPDATE au.administrative_unit_area_5 a
SET name = 
    CASE 
    WHEN b.namelocal = b.namefre THEN
        jsonb_build_array(                                                         
            jsonb_build_object(
                'script', 'latn',
                'display', '1'::INT,
                'language', 'fre',       
                'spelling', b.namefre,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namefre
            ),
            jsonb_build_object(     
                'script', 'latn',
                'display', '0'::INT,
                'language', 'dut',
                'spelling', b.namedut,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namedut
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '0'::INT,
                'language', 'ger',
                'spelling', b.nameger,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.nameger
                )
            )
     WHEN b.namelocal = b.namedut THEN
        jsonb_build_array(                                                         
            jsonb_build_object(
                'script', 'latn',
                'display', '1'::INT,
                'language', 'dut',       
                'spelling', b.namedut,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namedut
            ),
            jsonb_build_object(     
                'script', 'latn',
                'display', '0'::INT,
                'language', 'fre',
                'spelling', b.namefre,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namefre
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '0'::INT,
                'language', 'ger',
                'spelling', b.nameger,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.nameger
                )
            )
      ELSE a.name
      END
    FROM au.administrative_unit_area_5, municipality b
    WHERE a.country = 'be' AND a.national_code = b.niscode 
;

-- Update label field

UPDATE au.administrative_unit_area_2 a
SET label = b.namelocal
FROM region b
WHERE a.country = 'be' AND a.national_code = b.niscode ;

UPDATE au.administrative_unit_area_3 a
SET label = b.namelocal
FROM province b
WHERE a.country = 'be' AND a.national_code = b.niscode ;

UPDATE au.administrative_unit_area_4 a
SET label = b.namelocal
FROM arrondissement b
WHERE a.country = 'be' AND a.national_code = b.niscode ;

UPDATE au.administrative_unit_area_5 a
SET label = b.namelocal
FROM municipality b
WHERE a.country = 'be' AND a.national_code = b.niscode ;