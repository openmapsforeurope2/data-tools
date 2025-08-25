CREATE TABLE hy_watercourse_link_ch_li (LIKE hy.watercourse_link INCLUDING CONSTRAINTS INCLUDING DEFAULTS);

Changement de modèle vers hy_watercourse_link_ch_li avec option --no_history

UPDATE hy.watercourse_link a
SET name = b.name, label = b.label
FROM hy_watercourse_link_ch_li b
WHERE a.w_national_identifier = b.w_national_identifier AND (a.country = 'ch' OR a.country = 'li');

 

DROP TABLE IF EXISTS hy_watercourse_link_borders_ch_li;
CREATE TABLE hy_watercourse_link_borders_ch_li AS SELECT * FROM hy.watercourse_link WHERE (country LIKE '%ch%' OR country LIKE '%li%') AND country LIKE '%#%';
	 
ALTER TABLE hy_watercourse_link_borders_ch_li ADD COLUMN name_ch jsonb, ADD COLUMN name_other jsonb, ADD COLUMN name_final jsonb,
    ADD COLUMN label_final character varying(255);
	
	
-- Fill name_other by removing Swiss names (length(spelling) > 1 and language != 'void_unk')
UPDATE hy_watercourse_link_borders_ch_li
SET name_other = (
  SELECT jsonb_agg(elem)
  FROM jsonb_array_elements(name) AS elem
  WHERE length(elem->>'spelling') <> 1 AND elem->>'language' != 'void_unk'
)
WHERE name::text != '{}';


-- Calculate id_ch (Swiss part of w_national_identifier)
ALTER TABLE hy_watercourse_link_borders_ch_li ADD COLUMN id_ch character varying(255);

UPDATE hy_watercourse_link_borders_ch_li 
SET id_ch = 
	CASE
		WHEN country LIKE 'ch%' OR country LIKE 'li%' THEN SUBSTRING(w_national_identifier, 0, POSITION('#' IN w_national_identifier))
		WHEN country LIKE '%ch' OR country LIKE '%li' THEN SUBSTRING(w_national_identifier, POSITION('#' IN w_national_identifier)+1)
		ELSE null
	END
;

-- Calculate name_ch
UPDATE hy_watercourse_link_borders_ch_li a
SET name_ch = b.name
FROM hy_watercourse_link_ch_li b
WHERE a.id_ch = b.w_national_identifier AND b.name::text != '{}';


-- Set 1st letter of French names to upper case
UPDATE hy_watercourse_link_borders_ch_li
SET name_other = (
  SELECT jsonb_agg(
    jsonb_set(
      elem,
      '{spelling}',
      -- Uppercase first letter, rest as-is
      to_jsonb(
        upper(left(elem->>'spelling', 1)) || substr(elem->>'spelling', 2)
      ),
      false
    )
  )
  FROM jsonb_array_elements(name_other) AS arr(elem)
)
WHERE name_other IS NOT NULL AND country LIKE '%fr';

UPDATE hy_watercourse_link_borders_ch_li
SET name_other = (
  SELECT jsonb_agg(
    jsonb_set(
      elem,
      '{spelling_latn}',
      -- Uppercase first letter, rest as-is
      to_jsonb(
        upper(left(elem->>'spelling_latn', 1)) || substr(elem->>'spelling_latn', 2)
      ),
      false
    )
  )
  FROM jsonb_array_elements(name_other) AS arr(elem)
)
WHERE name_other IS NOT NULL AND country LIKE '%fr';


-- Combine name_ch and name_other in the right order based on country code order

UPDATE hy_watercourse_link_borders_ch_li
SET name_final = 
    CASE
        WHEN name_ch is null THEN name_other
		WHEN name_other is null THEN name_ch
		WHEN country LIKE 'ch#%' OR country LIKE 'li#%' THEN name_ch || name_other
        WHEN country LIKE '%#ch' OR country LIKE '%#li' THEN name_other || name_ch
        ELSE name_other
    END
;


-- Calculate label

UPDATE hy_watercourse_link_borders_ch_li AS main
SET label_final = sub.label_final_preview
FROM (
  SELECT
    objectid,
    string_agg(spelling, '#' ORDER BY min_ordinality) AS label_final_preview
  FROM (
    SELECT
      objectid,
      elem->>'spelling' AS spelling,
      MIN(ordinality) AS min_ordinality
    FROM
      hy_watercourse_link_borders_ch_li,
      LATERAL jsonb_array_elements(name_final) WITH ORDINALITY AS arr(elem, ordinality)
    WHERE name_final IS NOT NULL
    GROUP BY objectid, elem->>'spelling'
  ) AS dedup
  GROUP BY objectid
) AS sub
WHERE main.objectid = sub.objectid;

-- Replace null values with void values

UPDATE hy_watercourse_link_borders_ch_li SET name_final = '{}' WHERE name_final is null;
UPDATE hy_watercourse_link_borders_ch_li SET label_final = 'void_unk' WHERE label_final is null;

-- Final update

UPDATE hy.watercourse_link a
SET name = b.name_final, label = b.label_final
FROM hy_watercourse_link_borders_ch_li b
WHERE (a.country LIKE '%ch%' OR a.country LIKE '%li%') AND a.country LIKE '%#%' AND a.objectid = b.objectid;

