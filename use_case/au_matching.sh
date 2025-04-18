#################################################################################################
# AT                                                                                            #
#################################################################################################

# Launched on 07/04/2025

# Matching (level 5) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_5 -d 1000 at #
au_matching --c D:/dev/au_matching/config/epg_parameters_ng.ini --t public.administrative_unit_area_5_w --cc at
# 2 invalid polygons corrected manually
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_5 -s 30

# Merging (level 4) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_4 -d 1000 at #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_5 --t public.administrative_unit_area_4_w --cc at
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_4 -s 30

# Merging (level 3) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_3 -d 1000 at #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_4 --t public.administrative_unit_area_3_w --cc at
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_3 -s 30

# Merging (level 2) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_2 -d 1000 at #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_3 --t public.administrative_unit_area_2_w --cc at
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_2 -s 30

# Merging (level 1) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_1 -d 1000 at #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_2 --t public.administrative_unit_area_1_w --cc at
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_1 -s 30

#################################################################################################
# BE - TO BE REVIEWED                                                                           #
#################################################################################################

# Launched on 27/07/2024

# Matching (level 5) :   
# ********************

python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_5 -d 1000 be '#'
python3 script/table_copy.py -c conf.json au.administrative_unit_area_1 ib.international_boundary_line
ome2_au_matching.exe --c D:\Dev\au_matching\data\config\epg_parameters_au_ng.ini --t administrative_unit_area_5_w --cc be
# Vérifier (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_5 -s 30

# Merging (level 4) :   
# ********************

python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_4 -d 1000 be '#'
python3 script/table_copy.py -c conf.json au.administrative_unit_area_5
# Vérifier (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_4 -s 30

# Merging (level 3) :   
# ********************

python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_3 -d 1000 be '#'
python3 script/table_copy.py -c conf.json au.administrative_unit_area_4
ome2_au_merging --c d:/dev/au_merging/data/config/epg_parameters_merging_ng.ini --s au_administrative_unit_area_4 --t administrative_unit_area_3_w --cc be
# Vérifier (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_3 -s 30

# Merging (level 2) :   
# ********************

python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_2 -d 1000 be '#'
python3 script/table_copy.py -c conf.json au.administrative_unit_area_3 
ome2_au_merging --c d:/dev/au_merging/data/config/epg_parameters_merging_ng.ini --s au_administrative_unit_area_3 --t administrative_unit_area_2_w --cc be
# Vérifier (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_2 -s 30

# Merging (level 1) :   
# ********************

python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_1 -d 1000 be '#'
python3 script/table_copy.py -c conf.json au.administrative_unit_area_2 
ome2_au_merging --c d:/dev/au_merging/data/config/epg_parameters_merging_ng.ini --s au_administrative_unit_area_2 --t administrative_unit_area_1_w --cc be
# Vérifier (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_1 -s 30

# Mettre à jour au.administrative_hierarchy avec fme_workbenches\AU_manage_administrative_hierarchy.fmw
# ********************


#################################################################################################
# CH                                                                                            #
#################################################################################################

# Launched on 27/07/2024 sur ch#fr / relancé sur toutes les frontières le 18/04

# Matching (level 4) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_4 -d 1000 ch #
au_matching --c D:/dev/au_matching/config/epg_parameters_ng.ini --t public.administrative_unit_area_4_w --cc ch
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_4 -s 30

# Merging (level 3) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_3 -d 1000 ch #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_4 --t public.administrative_unit_area_3_w --cc ch
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_3 -s 30

# Merging (level 2) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_2 -d 1000 ch #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_3 --t public.administrative_unit_area_2_w --cc ch
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_2 -s 30

# Merging (level 1) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_1 -d 1000 ch #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_2 --t public.administrative_unit_area_1_w --cc ch
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_1 -s 30


# Mettre à jour au.administrative_hierarchy avec fme_workbenches\AU_manage_administrative_hierarchy.fmw
# ********************


#################################################################################################
# CZ                                                                                            #
#################################################################################################

# Launched on 27/07/2024 sur ch#fr / relancé sur toutes les frontières le 18/04

# Matching (level 4) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_4 -d 1000 cz #
au_matching --c D:/dev/au_matching/config/epg_parameters_ng.ini --t public.administrative_unit_area_4_w --cc cz
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_4 -s 30

# Merging (level 3) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_3 -d 1000 cz #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_4 --t public.administrative_unit_area_3_w --cc cz
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_3 -s 30

# Merging (level 2) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_2 -d 1000 cz #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_3 --t public.administrative_unit_area_2_w --cc cz
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_2 -s 30

# Merging (level 1) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_1 -d 1000 cz #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_2 --t public.administrative_unit_area_1_w --cc cz
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_1 -s 30


# Mettre à jour au.administrative_hierarchy avec fme_workbenches\AU_manage_administrative_hierarchy.fmw
# ********************


#################################################################################################
# ES                                                                                            #
#################################################################################################

# Launched on 18/04/2025 on es#fr boundary

# Matching (level 4) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_4 -b fr -d 1000 es
au_matching --c D:/dev/au_matching/config/epg_parameters_ng.ini --t public.administrative_unit_area_4_w --cc es
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_4 -s 30

# Merging (level 3) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_3 -d 1000 es #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_4 --t public.administrative_unit_area_3_w --cc es
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_3 -s 30

# Merging (level 2) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_2 -d 1000 es #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_3 --t public.administrative_unit_area_2_w --cc es
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_2 -s 30

# Merging (level 1) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_1 -d 1000 es #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_2 --t public.administrative_unit_area_1_w --cc es
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_1 -s 30


# Update au.administrative_hierarchy avec fme_workbenches\AU_manage_administrative_hierarchy.fmw
# ********************


#################################################################################################
# FR - TO BE REVIEWED                                                                           #
#################################################################################################

# Launched on 27/07/2024

# Matching (level 6) :   
# ********************

#relancé uniquement sur les frontières fr#lu et ch#fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_6 -b lu -d 1000 fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_6 -b ch -d 1000 -n fr

python3 script/table_copy.py -c conf.json au.administrative_unit_area_1 ib.international_boundary_line
ome2_au_matching.exe --c D:\Dev\au_matching\data\config\epg_parameters_au_ng.ini --t administrative_unit_area_6_w --cc fr
# Vérifier (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_6 -s 30

# Merging (level 5) :   
# ********************

# python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_5 -d 1000 fr '#'

# relancé uniquement sur les frontières fr#lu et ch#fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_5 -b lu -d 1000 fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_5 -b ch -d 1000 -n fr

python3 script/table_copy.py -c conf.json au.administrative_unit_area_6
ome2_au_merging --c d:/dev/au_merging/data/config/epg_parameters_merging_ng.ini --s au_administrative_unit_area_6 --t administrative_unit_area_5_w --cc fr
# Vérifier (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_5 -s 30


# Merging (level 4) :   
# ********************

# python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_4 -d 1000 fr '#'

# relancé uniquement sur les frontières fr#lu et ch#fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_4 -b lu -d 1000 fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_4 -b ch -d 1000 -n fr

# Attention on repart du level 6 car les levelx 4 et 5 ne sont pas cohérents en France
python3 script/table_copy.py -c conf.json au.administrative_unit_area_6
ome2_au_merging --c d:/dev/au_merging/data/config/epg_parameters_merging_ng.ini --s au_administrative_unit_area_6 --t administrative_unit_area_4_w --cc fr
# Vérifier (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_4 -s 30

# Merging (level 3) :   
# ********************

# python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_3 -d 1000 fr '#'

# relancé uniquement sur les frontières fr#lu et ch#fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_3 -b lu -d 1000 fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_3 -b ch -d 1000 -n fr

python3 script/table_copy.py -c conf.json au.administrative_unit_area_4
ome2_au_merging --c d:/dev/au_merging/data/config/epg_parameters_merging_ng.ini --s au_administrative_unit_area_4 --t administrative_unit_area_3_w --cc fr
# Vérifier (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_3 -s 30

# Merging (level 2) :   
# ********************

# python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_2 -d 1000 fr '#'

# relancé uniquement sur les frontières fr#lu et ch#fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_2 -b lu -d 1000 fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_2 -b ch -d 1000 -n fr

python3 script/table_copy.py -c conf.json au.administrative_unit_area_3 
ome2_au_merging --c d:/dev/au_merging/data/config/epg_parameters_merging_ng.ini --s au_administrative_unit_area_3 --t administrative_unit_area_2_w --cc fr
# Vérifier (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_2 -s 30

# Merging (level 1) :   
# ********************

# python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_1 -d 1000 fr '#'

# relancé uniquement sur les frontières fr#lu et ch#fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_1 -b lu -d 1000 fr
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_1 -b ch -d 1000 -n fr

python3 script/table_copy.py -c conf.json au.administrative_unit_area_2 
ome2_au_merging --c d:/dev/au_merging/data/config/epg_parameters_merging_ng.ini --s au_administrative_unit_area_2 --t administrative_unit_area_1_w --cc fr
# Vérifier (pas d'erreurs)
# On récupère 444 small_or_slim_surface (cf. shape logger). Verif dans QGIS : small_or_slim_surface est à l'intérieur de international_boundary_line
# C'est le cas pour tous les contours donc on considère qu'il n'y a pas d'erreur.
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_1 -s 30

# Mettre à jour au.administrative_hierarchy avec fme_workbenches\AU_manage_administrative_hierarchy.fmw
# ********************


#################################################################################################
# LI                                                                                            #
#################################################################################################

# Launched on 18/04/2025 on WINDOWS VM 

# Matching (level 2) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_2 -d 1000 li #
au_matching --c D:/Dev/au_matching/config/epg_parameters_ng.ini --t public.administrative_unit_area_2_w --cc li
# 2 invalid polygons corrected manually
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_2 -s 30

# Merging (level 1) :   
# ********************
python3 script/border_extract.py -c conf_v6.json -T au -t administrative_unit_area_1 -d 1000 li #
au_merging --c d:/dev/au_merging/config/epg_parameters_ng.ini --s au.administrative_unit_area_2 --t public.administrative_unit_area_1_w --cc li
# Vérifier (pas d'erreurs)
python3 script/integrate.py -c conf_v6.json -T au -t administrative_unit_area_1 -s 30



#################################################################################################
# LU - TO BE REVIEWED                                                                           #
#################################################################################################

# Launched on 11/04/2024

# Matching (level 3) :   
# ********************

python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_3 -d 1000 lu '#'
python3 script/table_copy.py -c conf.json au.administrative_unit_area_1 ib.international_boundary_line
ome2_au_matching.exe --c D:\Dev\Europe\OME2\au_matching\data\config\epg_parameters_au_ng.ini --t administrative_unit_area_3_w --cc lu
# Vérifier (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_3 -s 30

# Merging (level 2) :   
# ********************

python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_2 -d 1000 lu '#'
python3 script/table_copy.py -c conf.json au.administrative_unit_area_3
ome2_au_merging.exe --c D:\Dev\Europe\OME2\au_merging\data\config\epg_parameters_merging_ng.ini --s au_administrative_unit_area_3 --t administrative_unit_area_2_w --cc lu
# vérifier dans le fichier de log si des polygones non-valides ont été générés au cours de processus de matching, les corriger dans QGIS le cas échéant (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_2 -s 30

# Merging (level 1) :   
# ********************

python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_1 -d 1000 lu '#'
python3 script/table_copy.py -c conf.json au.administrative_unit_area_2
ome2_au_merging.exe --c D:\Dev\Europe\OME2\au_merging\data\config\epg_parameters_merging_ng.ini --s au_administrative_unit_area_2 --t administrative_unit_area_1_w --cc lu
# Vérif (pas d'erreurs)
python3 script/integration.py -c conf.json -T au -t administrative_unit_area_1 -s 30

# Mettre à jour au.administrative_hierarchy avec fme_workbenches\AU_manage_administrative_hierarchy.fmw
# ********************

#################################################################################################
# LABEL UPDATE                                                                                  #
#################################################################################################
# Il faut avoir installé la fonction update_label_from_name au préalable (data-tools\sql\UPDATE_LABEL_FROM_NAME.sql)
# Launched on 29/07/2024

# administrative_unit_area_4 (CH) -> pas lancé car label a été traité dans le changement de modèle
# ALTER TABLE au.administrative_unit_area_4 DISABLE TRIGGER ign_gcms_history_trigger;
# SELECT update_label_from_name('au.administrative_unit_area_4', 'name', 'label', 'country = ''ch''' );
# ALTER TABLE au.administrative_unit_area_4 ENABLE TRIGGER ign_gcms_history_trigger;

# administrative_unit_area_3 (LU) -> pas lancé pour CH car label a été traité dans le changement de modèle
ALTER TABLE au.administrative_unit_area_3 DISABLE TRIGGER ign_gcms_history_trigger;
SELECT update_label_from_name('au.administrative_unit_area_3', 'name', 'label', 'country = ''lu''' );
ALTER TABLE au.administrative_unit_area_3 ENABLE TRIGGER ign_gcms_history_trigger;

# administrative_unit_area_2 (LU) -> pas lancé pour CH car label a été traité dans le changement de modèle
ALTER TABLE au.administrative_unit_area_2 DISABLE TRIGGER ign_gcms_history_trigger;
SELECT update_label_from_name('au.administrative_unit_area_2', 'name', 'label', 'country = ''lu''' );
ALTER TABLE au.administrative_unit_area_2 ENABLE TRIGGER ign_gcms_history_trigger;

# administrative_unit_area_1 (LU) -> pas lancé pour CH car label a été traité dans le changement de modèle
ALTER TABLE au.administrative_unit_area_1 DISABLE TRIGGER ign_gcms_history_trigger;
SELECT update_label_from_name('au.administrative_unit_area_1', 'name', 'label', 'country = ''lu''' );
ALTER TABLE au.administrative_unit_area_1 ENABLE TRIGGER ign_gcms_history_trigger;