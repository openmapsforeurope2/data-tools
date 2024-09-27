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
                'display', '2'::INT,
                'language', 'dut',
                'spelling', b.namedut,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namedut
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '3'::INT,
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
                'display', '2'::INT,
                'language', 'fre',
                'spelling', b.namefre,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namefre
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '3'::INT,
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
                'display', '2'::INT,
                'language', 'dut',
                'spelling', b.namedut,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namedut
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '3'::INT,
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
                'display', '2'::INT,
                'language', 'fre',
                'spelling', b.namefre,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.namefre
            ),
            jsonb_build_object(                                            
                'script', 'latn',
                'display', '3'::INT,
                'language', 'ger',
                'spelling', b.nameger,
                'nativeness', 'endonym',
                'name_status', 'official',
                'spelling_latn', b.nameger
                )
            )
      ELSE a.name
      END
    FROM au.administrative_unit_area_2, province b
    WHERE a.country = 'be' AND a.national_code = b.niscode 
;