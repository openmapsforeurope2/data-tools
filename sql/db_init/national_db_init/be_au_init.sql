-- Copy all BE tables
CREATE TABLE au.province_ome2 AS SELECT * FROM au.province;
CREATE TABLE au.arrondissement_ome2 AS SELECT * FROM au.arrondissement;
CREATE TABLE au.municipality_ome2 AS SELECT * FROM au.municipality;

-- Province: add niscode_region
ALTER TABLE au.province_ome2 ADD COLUMN niscode_region character varying(25);
UPDATE au.province_ome2
SET niscode_region = au.region.niscode
FROM au.region
WHERE ST_Intersects(ST_GeneratePoints(au.province_ome2.geom,1),au.region.geom);

-- Arrondissement: add niscode_region
ALTER TABLE au.arrondissement_ome2 ADD COLUMN niscode_region character varying(25);
UPDATE au.arrondissement_ome2
SET niscode_region = au.region.niscode
FROM au.region
WHERE ST_Intersects(ST_GeneratePoints(au.arrondissement_ome2.geom,1),au.region.geom);

-- Municipality: add niscode_region
ALTER TABLE au.municipality_ome2 ADD COLUMN niscode_region character varying(25);
UPDATE au.municipality_ome2
SET niscode_region = au.region.niscode
FROM au.region
WHERE ST_Intersects(ST_GeneratePoints(au.municipality_ome2.geom,1),au.region.geom);
