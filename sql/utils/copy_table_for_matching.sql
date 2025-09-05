--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------------- COPY TABLES FOR MATCHING -----------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- This script can be used to create a copy of a work table prior to launching 
-- the edge-matching process.
-- The target table retains the identifiers from the source table and all indexes are recreated.

DROP TABLE IF EXISTS yy.target_table;
CREATE TABLE yy.target_table AS SELECT * FROM  xx.source_table
--WHERE ST_intersects(geom, ST_SetSRID(ST_Envelope('LINESTRING(3877955 3150042, 3878080 3150130)'::geometry), 3035));
;

ALTER TABLE yy.target_table
   ALTER objectid DROP DEFAULT,
   ALTER objectid TYPE uuid,
   ALTER objectid SET DEFAULT gen_random_uuid();


-- DROP INDEX IF EXISTS public.road_link_w_20231109_2_country_idx;

CREATE INDEX IF NOT EXISTS target_table_country_idx
    ON yy.target_table USING btree
    (country COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: road_link_w_20231109_2_geom_idx

-- DROP INDEX IF EXISTS public.road_link_w_20231109_2_geom_idx;

CREATE INDEX IF NOT EXISTS target_table_lu_geom_idx
    ON yy.target_table USING gist
    (geom)
    TABLESPACE pg_default;
-- Index: road_link_w_20231109_2_inspireid_idx

-- DROP INDEX IF EXISTS public.road_link_w_20231109_2_inspireid_idx;

CREATE INDEX IF NOT EXISTS target_table_objectid_idx
    ON yy.target_table USING btree
    (objectid ASC NULLS LAST)
    TABLESPACE pg_default;
    
CREATE INDEX IF NOT EXISTS target_table_national_identifier_idx
    ON yy.target_table USING btree
    (w_national_identifier ASC NULLS LAST)
    TABLESPACE pg_default;
	
ALTER TABLE yy.target_table ADD CONSTRAINT target_table_pkey PRIMARY KEY(objectid);
