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

DROP TYPE IF EXISTS form_of_way_value;
CREATE TYPE form_of_way_value AS ENUM (
    'bicycle_road', 
    'dual_carriage_way',
    'enclosed_traffic_area',
    'entrance_or_exit_car_park',
    'entrance_or_exit_service',
    'freeway',
    'motorway',
    'pedestrian_zone',
    'roundabout',
    'service_road',
    'single_carriage_way',
    'slip_road',
    'tractor',
    'traffic_square',
    'walkway',
    ''
);

DROP TYPE IF EXISTS functional_road_class_value;
CREATE TYPE functional_road_class_value AS ENUM (
    'main_road', 
    'first_class',
    'second_class',
    'third_class',
    'fourth_class',
    'fifth_class',
    'sixth_class',
    'seventh_class',
    'eighth_class',
    'ninth_class',
    ''
);

DROP TYPE IF EXISTS vertical_position_value;
CREATE TYPE vertical_position_value AS ENUM (
    'on_ground_surface', 
    'suspended_or_elevated',
    'underground',
    ''
);

DROP TYPE IF EXISTS vertical_level_value;
CREATE TYPE vertical_level_value AS ENUM (
    '-4', 
    '-3',
    '-2',
    '-1',
    '0',
    '1',
    '2',
    '3',
    '4'
);

DROP TYPE IF EXISTS ten_t_network_value;
CREATE TYPE ten_t_network_value AS ENUM (
    'comprehensive_ten_t_network', 
    'core_ten_t_network',
    'no_ten_t_network',
    ''
);

DROP TYPE IF EXISTS road_surface_category_value;
CREATE TYPE road_surface_category_value AS ENUM (
    'paved', 
    'unpaved',
    ''
);

-- pas trouvé dans diagrammes UML
DROP TYPE IF EXISTS link_direction_value;
CREATE TYPE link_direction_value AS ENUM (
    'both_directions',
    'indirection',  
    'opposite_direction',
    ''
);

DROP TYPE IF EXISTS access_restriction_value;
CREATE TYPE access_restriction_value AS ENUM (
    'forbidden_legally',
    'physically_impossible',
    'private',
    'public_access',
    'seasonal',
    'toll',
    ''
);

DROP TYPE IF EXISTS condition_of_facility_value;
CREATE TYPE condition_of_facility_value AS ENUM (
    'disused',
    'functional',
    'projected',
    'under_construction',
    'decommissioned',
    ''
);

DROP TYPE IF EXISTS form_of_road_node_value;
CREATE TYPE form_of_road_node_value AS ENUM (
    'enclosed_traffic_area',
    'interchange',
    'junction',
    'level_crossing',
    'pseudo_node',
    'road_end',
    'roundabout',
    'traffic_square',
    'road_service_area',
    ''
);

DROP TYPE IF EXISTS road_service_type_value;
CREATE TYPE road_service_type_value AS ENUM (
    'bus_station',
    'parking',
    'rest_area',
    'toll',
    --'electric_car_loading_stations' valeur présente dans specs mais pas dans diagrammes UML,
    ''
);

DROP TYPE IF EXISTS railway_type_value;
CREATE TYPE railway_type_value AS ENUM (
    'cog_railway',
    'funicular',
    'magnetic_levitation',
    'metro',
    'monorail',
    'suspended_rail',
    'train',
    'tramway',
    ''
);

DROP TYPE IF EXISTS railway_use_value;
CREATE TYPE railway_use_value AS ENUM (
    'cargo',
    'passenger',
    'mixed',
    'car_shuttle',
    ''
);
