-- TRANSPORT

CREATE TABLE tn.ome2_geb_3300_verkehr_f AS SELECT * FROM lu.geb_3300_verkehr_f;

ALTER TABLE tn.ome2_geb_3300_verkehr_f ADD COLUMN art_bauten character varying;
ALTER TABLE tn.ome2_geb_3300_verkehr_f ADD COLUMN name_bauten character varying;
ALTER TABLE tn.ome2_geb_3300_verkehr_f ADD COLUMN kurzbez_bauten character varying;
ALTER TABLE tn.ome2_geb_3300_verkehr_f ADD COLUMN f_code_bauten integer;

UPDATE tn.ome2_geb_3300_verkehr_f a
SET art_bauten = b.art, name_bauten = b.name, kurzbez_bauten = kurzbez, f_code_bauten = b.f_code
FROM tn.ver_1200_bauten_p b
WHERE a.p_id_ver_bauten = b.globalid ;


-- HYDROGRAPHY

CREATE TABLE hy.ver_1100_strasse_l AS SELECT * FROM tn.ver_1100_strasse_l;
CREATE TABLE hy.bod_5300_wasser_f AS SELECT * FROM lc.bod_5300_wasser_f;