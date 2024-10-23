DROP TYPE IF EXISTS administrative_hierarchy_level_type_value;
CREATE TYPE administrative_hierarchy_level_type_value AS ENUM (
'1st_order', 
'2nd_order',
'3rd_order',
'4th_order',
'5th_order',
'6th_order');

DROP TYPE IF EXISTS legal_status_value;
CREATE TYPE legal_status_value AS ENUM (
'agreed', 
'not_agreed');

DROP TYPE IF EXISTS technical_status_value;
CREATE TYPE technical_status_value AS ENUM (
'edge_matched', 
'calculated',
'not_edge_matched');

DROP TYPE IF EXISTS land_cover_type_value;
CREATE TYPE land_cover_type_value AS ENUM (
'land_area', 
'coastal_water',
'inland_water');

DROP TYPE IF EXISTS boundary_type_value;
CREATE TYPE boundary_type_value AS ENUM (
    'international_boundary',
    'maritime_boundary',
    'land_maritime_boundary',
    'coastline_sea_limit',
    'directory_line'
);


