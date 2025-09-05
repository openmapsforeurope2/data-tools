-- Level 3
ALTER TABLE maakunta ADD COLUMN ome2_natcode_level2 character varying DEFAULT 'void_unk';

UPDATE maakunta a
SET ome2_natcode_level2 = b.natcode 
FROM aluehallintovirasto b
WHERE ST_Within(ST_PointOnSurface(a.multipolygon),b.multipolygon);

-- Level 4
ALTER TABLE hyvinvointialue ADD COLUMN ome2_natcode_level2 character varying DEFAULT 'void_unk';
UPDATE hyvinvointialue a
SET ome2_natcode_level2 = b.natcode 
FROM aluehallintovirasto b
WHERE ST_Within(ST_PointOnSurface(a.multipolygon),b.multipolygon);

ALTER TABLE hyvinvointialue ADD COLUMN ome2_natcode_level3 character varying DEFAULT 'void_unk';
UPDATE hyvinvointialue a
SET ome2_natcode_level3 = b.natcode 
FROM maakunta b
WHERE ST_Within(ST_PointOnSurface(a.multipolygon),b.multipolygon);

-- Level 5
ALTER TABLE kunta ADD COLUMN ome2_natcode_level2 character varying DEFAULT 'void_unk';
UPDATE kunta a
SET ome2_natcode_level2 = b.natcode 
FROM aluehallintovirasto b
WHERE ST_Within(ST_PointOnSurface(a.multipolygon),b.multipolygon);

ALTER TABLE kunta ADD COLUMN ome2_natcode_level3 character varying DEFAULT 'void_unk';
UPDATE kunta a
SET ome2_natcode_level3 = b.natcode 
FROM maakunta b
WHERE ST_Within(ST_PointOnSurface(a.multipolygon),b.multipolygon);

ALTER TABLE kunta ADD COLUMN ome2_natcode_level4 character varying DEFAULT 'void_unk';
UPDATE kunta a
SET ome2_natcode_level4 = b.natcode 
FROM hyvinvointialue b
WHERE ST_Within(ST_PointOnSurface(a.multipolygon),b.multipolygon);

----- Names
ALTER TABLE kunta ADD COLUMN ome2_targetcode character varying DEFAULT '-1';

UPDATE kunta
SET ome2_targetcode = trim(both '''' from b.targetcode)
FROM kunta_1_20250101_kielisuhde_1_20250101 b
WHERE natcode = trim(both '''' from b.sourcecode);