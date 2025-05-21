DROP TABLE IF EXISTS road_link_ch_li;
CREATE TABLE road_link_ch_li AS SELECT * FROM tn.road_link WHERE country = 'ch';

ALTER TABLE road_link_ch_li ADD COLUMN inter_ch real default -1;
ALTER TABLE road_link_ch_li ADD COLUMN inter_li real default -1;
ALTER TABLE road_link_ch_li ADD COLUMN dist_ch real default -1;
ALTER TABLE road_link_ch_li ADD COLUMN dist_li real default -1;
ALTER TABLE road_link_ch_li ADD COLUMN new_country_code character varying (10);

UPDATE road_link_ch_li a SET new_country_code = 'li' 
FROM au.administrative_unit_area_1 b WHERE b.country = 'li' AND ST_Within(a.geom, b.geom);

UPDATE road_link_ch_li a SET new_country_code = 'ch' 
FROM au.administrative_unit_area_1 b WHERE b.country = 'ch' AND ST_Within(a.geom, b.geom);

-- *** For networks and areas
    -- For networks
    UPDATE road_link_ch_li a SET inter_li = ST_Length(ST_Intersection (a.geom, b.geom))
    FROM au.administrative_unit_area_1 b WHERE new_country_code is NULL AND b.country = 'li';

    UPDATE road_link_ch_li a SET inter_ch = ST_Length(ST_Intersection (a.geom, b.geom))
    FROM au.administrative_unit_area_1 b WHERE new_country_code is NULL AND b.country = 'ch';

    -- For areas
    UPDATE road_link_ch_li a SET inter_li = ST_Area(ST_Intersection (a.geom, b.geom))
    FROM au.administrative_unit_area_1 b WHERE new_country_code is NULL AND b.country = 'li';

    UPDATE road_link_ch_li a SET inter_ch = ST_Area(ST_Intersection (a.geom, b.geom))
    FROM au.administrative_unit_area_1 b WHERE new_country_code is NULL AND b.country = 'ch';

    -- Common for networks and areas
    UPDATE road_link_ch_li
    SET new_country_code =
    CASE
    WHEN inter_ch >= dist_li AND inter_ch > 0 THEN 'ch'
    WHEN inter_li > inter_ch AND dist_li > 0 THEN 'li'
    END
    WHERE new_country_code IS NULL;

-- ** For all
UPDATE road_link_ch_li a SET dist_li = ST_Distance(a.geom, b.geom)
FROM au.administrative_unit_area_1 b WHERE new_country_code is NULL AND b.country = 'li';

UPDATE road_link_ch_li a SET dist_ch = ST_Distance(a.geom, b.geom)
FROM au.administrative_unit_area_1 b WHERE new_country_code is NULL AND b.country = 'ch';

UPDATE road_link_ch_li
SET new_country_code =
CASE
  WHEN dist_ch <= dist_li AND dist_ch >= 0 THEN 'ch'
  WHEN dist_li < dist_ch AND dist_li >= 0 THEN 'li'
END
WHERE new_country_code IS NULL;

