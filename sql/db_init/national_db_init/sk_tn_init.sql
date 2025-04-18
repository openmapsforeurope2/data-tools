-- TABLE tn.ome2_roadlink
CREATE TABLE tn.ome2_roadlink AS SELECT * FROM tn.roadlink;

ALTER TABLE tn.ome2_roadlink ADD COLUMN conditionoffacility character varying(80);
UPDATE tn.ome2_roadlink
SET conditionoffacility = tn.conditionoffacility.currentstatus
FROM tn.conditionoffacility
WHERE SUBSTRING(tn.ome2_roadlink.localid,STRPOS(tn.ome2_roadlink.localid,'_')+1) = SUBSTRING(tn.conditionoffacility.localid,STRPOS(tn.conditionoffacility.localid,'_')+1);

ALTER TABLE tn.ome2_roadlink ADD COLUMN formofway character varying(80);
UPDATE tn.ome2_roadlink
SET formofway = tn.formofway.formofway
FROM tn.formofway
WHERE SUBSTRING(tn.ome2_roadlink.localid,STRPOS(tn.ome2_roadlink.localid,'_')+1) = SUBSTRING(tn.formofway.localid,STRPOS(tn.formofway.localid,'_')+1);

ALTER TABLE tn.ome2_roadlink ADD COLUMN functionalroadclass character varying(80);
UPDATE tn.ome2_roadlink
SET functionalroadclass = tn.functionalroadclass.functionalclass
FROM tn.functionalroadclass
WHERE SUBSTRING(tn.ome2_roadlink.localid,STRPOS(tn.ome2_roadlink.localid,'_')+1) = SUBSTRING(tn.functionalroadclass.localid,STRPOS(tn.functionalroadclass.localid,'_')+1);

ALTER TABLE tn.ome2_roadlink ADD COLUMN roadsurfacecategory character varying(80);
UPDATE tn.ome2_roadlink
SET roadsurfacecategory = tn.roadsurfacecategory.surfacecategory
FROM tn.roadsurfacecategory
WHERE SUBSTRING(tn.ome2_roadlink.localid,STRPOS(tn.ome2_roadlink.localid,'_')+1) = SUBSTRING(tn.roadsurfacecategory.localid,STRPOS(tn.roadsurfacecategory.localid,'_')+1);

ALTER TABLE tn.ome2_roadlink ADD COLUMN width character varying(80);
ALTER TABLE tn.ome2_roadlink ADD COLUMN width_uom character varying(80);
ALTER TABLE tn.ome2_roadlink ADD COLUMN measuredroadpart character varying(80);
UPDATE tn.ome2_roadlink
SET width = tn.roadwidth.width, width_uom = tn.roadwidth.width_uom, measuredroadpart = tn.roadwidth.measuredroadpart
FROM tn.roadwidth
WHERE SUBSTRING(tn.ome2_roadlink.localid,STRPOS(tn.ome2_roadlink.localid,'_')+1) = SUBSTRING(tn.roadwidth.localid,STRPOS(tn.roadwidth.localid,'_')+1);

ALTER TABLE tn.ome2_roadlink ADD COLUMN verticalposition character varying(80);
UPDATE tn.ome2_roadlink
SET verticalposition = tn.verticalposition.verticalposition
FROM tn.verticalposition
WHERE SUBSTRING(tn.ome2_roadlink.localid,STRPOS(tn.ome2_roadlink.localid,'_')+1) = SUBSTRING(tn.verticalposition.localid,STRPOS(tn.verticalposition.localid,'_')+1);


-- TABLE tn.ome2_railwaylink

CREATE TABLE tn.ome2_railwaylink AS SELECT * FROM tn.railwaylink;

ALTER TABLE tn.ome2_railwaylink ADD COLUMN nominalgauge character varying(80);
ALTER TABLE tn.ome2_railwaylink ADD COLUMN nominalgauge_uom character varying(80);
ALTER TABLE tn.ome2_railwaylink ADD COLUMN nominalgaugecategory character varying(80);
UPDATE tn.ome2_railwaylink
SET nominalgauge = tn.nominaltrackgauge.nominalgauge, nominalgauge_uom = tn.nominaltrackgauge.nominalgauge_uom, nominalgaugecategory = tn.nominaltrackgauge.nominalgaugecategory
FROM tn.nominaltrackgauge
WHERE SUBSTRING(tn.ome2_railwaylink.localid,STRPOS(tn.ome2_railwaylink.localid,'_')+1) = SUBSTRING(tn.nominaltrackgauge.localid,STRPOS(tn.nominaltrackgauge.localid,'_')+1);

ALTER TABLE tn.ome2_railwaylink ADD COLUMN numberoftracks character varying(80);
ALTER TABLE tn.ome2_railwaylink ADD COLUMN minmaxnumberoftracks character varying(80);
UPDATE tn.ome2_railwaylink
SET numberoftracks = tn.numberoftracks.numberoftracks, minmaxnumberoftracks = tn.numberoftracks.minmaxnumberoftracks
FROM tn.numberoftracks
WHERE SUBSTRING(tn.ome2_railwaylink.localid,STRPOS(tn.ome2_railwaylink.localid,'_')+1) = SUBSTRING(tn.numberoftracks.localid,STRPOS(tn.numberoftracks.localid,'_')+1);

ALTER TABLE tn.ome2_railwaylink ADD COLUMN verticalposition character varying(80);
UPDATE tn.ome2_railwaylink
SET verticalposition = tn.verticalposition.verticalposition
FROM tn.verticalposition
WHERE SUBSTRING(tn.ome2_railwaylink.localid,STRPOS(tn.ome2_railwaylink.localid,'_')+1) = SUBSTRING(tn.verticalposition.localid,STRPOS(tn.verticalposition.localid,'_')+1);

ALTER TABLE tn.ome2_railwaylink ADD COLUMN railwayelectrification integer;
UPDATE tn.ome2_railwaylink
SET railwayelectrification = tn.railwayelectrification.electrified
FROM tn.railwayelectrification
WHERE SUBSTRING(tn.ome2_railwaylink.localid,STRPOS(tn.ome2_railwaylink.localid,'_')+1) = SUBSTRING(tn.railwayelectrification.localid,STRPOS(tn.railwayelectrification.localid,'_')+1);

ALTER TABLE tn.ome2_railwaylink ADD COLUMN type character varying(80);
UPDATE tn.ome2_railwaylink
SET type = tn.railwaytype.type
FROM tn.railwaytype
WHERE SUBSTRING(tn.ome2_railwaylink.localid,STRPOS(tn.ome2_railwaylink.localid,'_')+1) = SUBSTRING(tn.railwaytype.localid,STRPOS(tn.railwaytype.localid,'_')+1);


-- TABLE ome2_aerodromearea
CREATE TABLE tn.ome2_aerodromearea AS SELECT * FROM tn.aerodromearea;

ALTER TABLE tn.ome2_aerodromearea ADD COLUMN aerodrometype character varying(80);
UPDATE tn.ome2_aerodromearea
SET aerodrometype = tn.aerodrometype.aerodrometype
FROM tn.aerodrometype
WHERE SUBSTRING(tn.ome2_aerodromearea.localid,STRPOS(tn.ome2_aerodromearea.localid,'_')+1) = SUBSTRING(tn.aerodrometype.localid,STRPOS(tn.aerodrometype.localid,'_')+1);


-- TABLE ome2_runwayarea

CREATE TABLE tn.ome2_runwayarea AS SELECT * FROM tn.runwayarea;

ALTER TABLE tn.ome2_runwayarea ADD COLUMN surfacecomposition character varying(80);
UPDATE tn.ome2_runwayarea
SET surfacecomposition = tn.surfacecomposition.surfacecomposition
FROM tn.surfacecomposition
WHERE SUBSTRING(tn.ome2_runwayarea.localid,STRPOS(tn.ome2_runwayarea.localid,'_')+1) = SUBSTRING(tn.surfacecomposition.localid,STRPOS(tn.surfacecomposition.localid,'_')+1);

-- TABLE ome2_railwaystationarea
CREATE TABLE tn.ome2_railwaystationarea AS SELECT * FROM tn.railwaystationarea;

-- TABLE ome2_roadservicearea
CREATE TABLE tn.ome2_roadservicearea AS SELECT * FROM tn.roadservicearea;

ALTER TABLE tn.ome2_roadservicearea ADD COLUMN type character varying(80);
ALTER TABLE tn.ome2_roadservicearea ADD COLUMN availablefacility character varying(80);
UPDATE tn.ome2_roadservicearea
SET type = tn.roadservicetype.type, availablefacility = tn.roadservicetype.availablefacility
FROM tn.roadservicetype
WHERE SUBSTRING(tn.ome2_roadservicearea.localid,STRPOS(tn.ome2_roadservicearea.localid,'_')+1) = SUBSTRING(tn.roadservicetype.localid,STRPOS(tn.roadservicetype.localid,'_')+1);

-- TABLE road
CREATE TABLE tn.ome2_road AS SELECT * FROM tn.road;