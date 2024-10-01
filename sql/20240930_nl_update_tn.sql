----------------------------------------------
-- road_link
----------------------------------------------

-- form_of_way
UPDATE tn.road_link AS a
SET form_of_way = 'freeway'
FROM top10nl_wegdeel_hartlijn AS b
WHERE a.w_national_identifier = b.national_identifier
AND b.hoofdverkeersgebruik = 'snelverkeer'
AND a.country = 'nl';

UPDATE tn.road_link AS a
SET form_of_way = 'pedestrian_zone'
FROM top10nl_wegdeel_hartlijn AS b
WHERE a.w_national_identifier = b.national_identifier
AND b.hoofdverkeersgebruik = 'voetgangers'
AND a.country = 'nl';

-- Remarque : les requêtes ci-dessus n'ont pas été appliquées aux objets avec code double.
-- Pour la première, il n'y avait que 3 objets avec code double issus d'objets NL avec hoofdverkeersgebruik = 'snelverkeer'. Les
-- 3 objets étaient déjà codés en "motorway" (même valeur pour BE et NL), donc il a semblé inutile de corriger en freeway.
-- Pour la seconde, il n'y a aucun objet avec code double et issus d'un objet NL avec hoofdverkeersgebruik = 'voetgangers' en base.

-- functional_road_class
UPDATE tn.road_link AS a
SET functional_road_class = 'fifth_class'
FROM top10nl_wegdeel_hartlijn AS b
WHERE a.w_national_identifier = b.national_identifier
AND b.typeweg = 'overig'
AND a.country = 'nl';

-- functional_road_class pour objets avec double code
-- Les valeurs existantes ont d'abord été vérifiées : elles étaient toutes simples (void_unk ou fourth_class) donc les valeurs 
-- remplies venait de la Belgique, puisque tous les objets avec typeweg = 'overig' avaient été classés en void_unk.
-- De ce fait, la requête se contente de concaténer '#fifth_class' aux valeurs présentes en base.
UPDATE tn.road_link AS a
SET functional_road_class = functional_road_class || '#fifth_class' 
FROM top10nl_wegdeel_hartlijn b
WHERE a.country like '%nl%' AND a.country != 'nl'
AND a.w_national_identifier like '%#' || b.national_identifier
AND b.typeweg = 'overig'
AND a.functional_road_class NOT LIKE '%#%';

----------------------------------------------
-- railway_link
----------------------------------------------
-- number_of_tracks
UPDATE tn.railway_link AS a
SET number_of_tracks = '1'
FROM top10nl_spoorbaandeel_lijn AS b
WHERE a.w_national_identifier = b.national_identifier
AND b.aantalsporen = 'enkel'
AND a.country = 'nl';

UPDATE tn.railway_link AS a
SET number_of_tracks = '2'
FROM top10nl_spoorbaandeel_lijn AS b
WHERE a.w_national_identifier = b.national_identifier
AND b.aantalsporen = 'dubbel'
AND a.country = 'nl';