# data-tools

Ensemble de scripts SQL et de scripts python exécutant des requêtes SQL.


## border_extraction

Extraction des données autour des frontières depuis la table de production vers la table de travail.

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* d [mandatory] : buffer radius (degrees)
* b [optional] : neighbouring country code
* n [optional] : option which enables not to delete data already present in the work table
* arguments : codes of country/countries to extract (one or two)


Exemple d'extraction des données d'un pays sur l'ensemble de ses frontières :

~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 nl '#'
~~~


Exemple d'extraction des données de deux pays frontaliers:

~~~
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -d 1000 be fr
~~~


Exemple d'extraction de l'ensemble des données et des données des pays limitrophes frontière par frontière:

~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b false -B international -d 3000 fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b ad -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b mc -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b lu -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b it -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b es -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b ch -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b de -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b be -d 3000 -n fr
~~~


## integrate

Intégration des données de la table de travail dans la table de production.

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* s [mandatory] : step number


Exemples d'appels:

~~~
python3 script/integrate.py -c conf.json -T tn -t road_link -s 10
~~~


## revert

Roll-back jusqu'à l'étape précédent l'étape indiquée en paramètre.

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* s [mandatory] : step number


Exemples d'appels:

~~~
python3 script/reverte.py -c conf.json -T au -t administrative_unit_area_3 -s 30
~~~


## create_table

Création d'une table ou de l'ensemble des tables d'un thème.

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* m [mandatory] : conceptual data model configuration file


Exemples d'appels:

~~~
python3 script/create_table.py -c conf.json -m mcd.json -T tn
python3 script/create_table.py -c conf.json -m mcd.json -T tn -t railway_link
~~~


## clean

Supprime les données éloignés du pays de la distance indiquée en paramètre.

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* d [mandatory] : cleaning distance
* arguments : codes of country/countries to clean


Exemples d'appels:

~~~
python3 script/clean.py -c conf.json -d 5 -T tn -t road_link_w be
~~~


## copy_table

Copy les tables dans le schéma public (la table schema.table sera copiée dans public.schema_table)

Paramètres
* c [mandatory] : configuration file
* arguments : table(s) to copy


Exemples d'appels:

~~~
python3 script/copy_table.py -c conf.json au.administrative_unit_area_1 ib.international_boundary_line
~~~


## Création de la Base de Données OME2


### Initialisation de la structure
~~~
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d OME2 -f ./sql/db_init/HVLSP_0_GCMS_0_ADMIN.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d OME2 -f ./sql/db_init/HVLSP_1_CREATE_SCHEMAS.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d OME2 -f ./sql/db_init/ome2_reduce_precision_3d_trigger_function.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d OME2 -f ./sql/db_init/ome2_reduce_precision_2d_trigger_function.sql
~~~


### Création des tables

Création de toutes les tables pour l'ensemble des schémas:

~~~
python3 script/create_table.py -c conf.json -m mcd.json -T tn
python3 script/create_table.py -c conf.json -m mcd.json -T hy
python3 script/create_table.py -c conf.json -m mcd.json -T au
python3 script/create_table.py -c conf.json -m mcd.json -T ib
~~~


### Historisation des tables
~~~
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/HVLSP_2_GCMS_1_COMMON.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/HVLSP_3_GCMS_3_HISTORIQUE.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/ign_gcms_history_trigger_function.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/HVLSP_4_GCMS_4_OME2_ADD_HISTORY.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -c "ALTER SEQUENCE public.seqnumrec OWNER TO g_ome2_user;"
~~~



























## Cleaning step (10)
### 1) Extract objects around a country's boundaries for cleaning: 

<u>The Netherlands:</u>
~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 nl '#'
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -d 4000 nl '#'
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -d 4000 nl '#'
~~~

<u>Belgium:</u>
~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 be '#'
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -d 4000 be '#'
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -d 4000 be '#'
~~~

<u>France:</u>

~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 3000 fr '#'

ATTENTION!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
voir si pour avoir les zone "in dispute", plutot ecrire :
python3 script/border_extraction.py -c conf.json -T tn -t road_link -B international -d 3000 fr


// or
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b false -B international -d 3000 fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b ad -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b mc -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b lu -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b it -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b es -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b ch -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b de -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t road_link -b be -d 3000 -n fr

python3 script/border_extraction.py -c conf.json -T tn -t railway_link -b false -B international -d 3000 fr
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -b ad -d 4000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -b mc -d 4000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -b lu -d 4000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -b it -d 4000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -b es -d 4000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -b ch -d 4000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -b de -d 4000 -n fr
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -b be -d 4000 -n fr

python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -b false -B international -d 3000 fr
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -b ad -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -b mc -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -b lu -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -b it -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -b es -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -b ch -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -b de -d 3000 -n fr
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -b be -d 3000 -n fr
~~~

<u>Suisse:</u>
~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 ch '#'
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -d 4000 ch '#'
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -d 4000 ch '#'
~~~

<u>Luxembourg:</u>
~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 lu '#'
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -d 4000 lu '#'
python3 script/border_extraction.py -c conf.json -T tn -t watercourse_link -d 4000 lu '#'
~~~

### 2) Clean (delete) objects outside border - (to be run from the data-tools project directory):

<u>The Netherlands:</u>
~~~
python3 script/clean.py -c conf.json -d 5 -T tn -t road_link_w nl
python3 script/clean.py -c conf.json -d 5 -T tn -t railway_link_w nl
python3 script/clean.py -c conf.json -d 5 -T hy -t watercourse_link_w nl
~~~

<u>Belgium:</u>
~~~
python3 script/clean.py -c conf.json -d 5 -T tn -t road_link_w be
python3 script/clean.py -c conf.json -d 5 -T tn -t railway_link_w be
python3 script/clean.py -c conf.json -d 5 -T hy -t watercourse_link_w be
~~~

<u>France:</u>
~~~
python3 script/clean.py -c conf.json -d 5 -T tn -t road_link_w fr
python3 script/clean.py -c conf.json -d 5 -T tn -t railway_link_w fr
python3 script/clean.py -c conf.json -d 5 -T hy -t watercourse_link_w fr
~~~

<u>Suisse:</u>
~~~
python3 script/clean.py -c conf.json -d 5 -T tn -t road_link_w ch
python3 script/clean.py -c conf.json -d 5 -T tn -t railway_link_w ch
python3 script/clean.py -c conf.json -d 5 -T hy -t watercourse_link_w ch
~~~

<u>Luxembourg:</u>
~~~
python3 script/clean.py -c conf.json -d 5 -T tn -t railway_link_w lu
~~~

### 3) Integrate modifications in the main table and working history table:
~~~
python3 script/integrate.py -c conf.json -T tn -t road_link -s 10
python3 script/integrate.py -c conf.json -T tn -t railway_link -s 10
python3 script/integrate.py -c conf.json -T hy -t watercourse_link -s 10
~~~


## Matching step (20)
### 1) Extract objects on the border between two neighbouring countries for matching:
~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 1000 be fr
python3 script/border_extraction.py -c conf.json -T tn -t railway_link -d 1000 be fr
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_link -d 1000 be fr
~~~

~~~
python3 script/border_extraction.py -c conf.json -T hy -t watercourse_area -d 1000 be fr
python3 script/border_extraction.py -c conf.json -T hy -t standing_water -d 1000 be fr
~~~

### 2) Match
~~~
./bin/net_matching --c ./data/config/epg_parameters.ini --T tn --cc be#lu
~~~

### 3) Integrate modifications in the main table and working history table:
~~~
python3 script/integrate.py -c conf.json -T tn -t road_link -s 20
~~~


## AU matching (30)
### 1) Extract objects around a country's boundaries for matching:

<u>The Netherlands:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_3 -d 1000 nl '#'
~~~

<u>Belgium:</u>

Example of an extraction around boundaries with only one neighbouring country:
~~~
python3 script/border_extraction.py exit-c conf.json -T au -t administrative_unit_area_5 -b nl -d 1000 be
~~~

Example of an extraction around boundaries with several neighbouring countries:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_5 -b nl -d 1000 be
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_5 -b de -d 1000 -n be
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_5 -b lu -d 1000 -n be
~~~

Example of an extraction around all boundaries:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_5 -d 1000 be '#'
~~~

<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_6 -d 1000 fr '#'
~~~

### 2) Matching
Copy boundary tables and country outlines in the public schema: 
~~~
python3 script/copy_table.py -c conf.json au.administrative_unit_area_1 ib.international_boundary_line
~~~

Run process:

<u>The Netherlands:</u>
~~~
bin/au_matching --c data/config/epg_parameters.ini --t work.administrative_unit_area_3_w --cc nl
~~~

<u>Belgium:</u>
~~~
bin/au_matching --c data/config/epg_parameters.ini --t work.administrative_unit_area_5_w --cc be
~~~

<u>France:</u>
~~~
bin/au_matching --c data/config/epg_parameters.ini --t work.administrative_unit_area_6_w --cc fr
~~~

### 3) Integrate modifications in the main table and working history (wh) table
Before running the integrate, check in the log file whether invalid polygons have been generated by the matching process. If there are some, correct them in QGIS.

<u>The Netherlands:</u>
~~~
python3 script/integrate.py -c conf.json -T au -t administrative_unit_area_3 -s 30
~~~

<u>Belgium:</u>
~~~
python3 script/integrate.py -c conf.json -T au -t administrative_unit_area_5 -s 30
~~~

<u>France:</u>
~~~
python3 script/integrate.py -c conf.json -T au -t administrative_unit_area_6 -s 30
~~~


## Administrative merging (30)
### Level 5)
#### 1) Extract objects around a country's boundaries
<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_5 -d 1000 fr '#'
~~~

#### 2) Merging
Copy lower level administrative unit table in the public schema:
~~~
python3 script/copy_table.py -c conf.json au.administrative_unit_area_6
~~~

Run process:

<u>France:</u>
~~~
bin/au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_area_6 --t administrative_unit_area_5_w --cc fr
~~~

#### 3)  Integrate modifications in the main table and working history (wh) table
~~~
python3 script/integrate.py -c conf.json -T au -t administrative_unit_area_5 -s 30
~~~


### Level 4)
#### 1) Extract objects around a country's boundaries
<u>Belgium:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_4 -d 1000 be '#'
~~~

<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_4 -d 1000 fr '#'
~~~

#### 2) Merging
Copy lower level administrative unit table in the public schema:

<u>Belgium:</u>
~~~
python3 script/copy_table.py -c conf.json au.administrative_unit_area_5
~~~

<u>France:</u>
~~~
python3 script/copy_table.py -c conf.json au.administrative_unit_area_6
~~~

Run process:

<u>Belgium:</u>
~~~
bin/au_merging --c data/config/epg_parameters.ini --s prod.administrative_unit_area_5 --t work.administrative_unit_area_4_w --cc be
~~~

<u>France:</u>
~~~
bin/au_merging --c data/config/epg_parameters.ini --s prod.administrative_unit_area_6 --t work.administrative_unit_area_4_w --cc fr
~~~

#### 3)  Integrate modifications in the main table and working history (wh) table
Before running the integrate, check in the log file whether invalid polygons have been generated by the matching process. If there are some, correct them in QGIS.

~~~
python3 script/integrate.py -c conf.json -T au -t administrative_unit_area_4 -s 30
~~~

### Level 3)
#### 1) Extract objects around a country's boundaries

<u>Belgium:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_3 -d 1000 be '#'
~~~

<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_3 -d 1000 fr '#'
~~~

#### 2) Matching
Copy lower level administrative unit table in the public schema:

<u>Belgium, France:</u>
~~~
python3 script/copy_table.py -c conf.json au.administrative_unit_area_4
~~~

Run process:

<u>Belgium:</u>
~~~
bin/au_merging --c data/config/epg_parameters.ini --s prod.administrative_unit_area_4 --t work.administrative_unit_area_3_w --cc be
~~~

<u>France:</u>
~~~
bin/au_merging --c data/config/epg_parameters.ini --s prod.administrative_unit_area_4 --t work.administrative_unit_area_3_w --cc fr
~~~

#### 3)  Integrate modifications in the main table and working history (wh) table
Before running the integrate, check in the log file whether invalid polygons have been generated by the matching process. If there are some, correct them in QGIS.

~~~
python3 script/integrate.py -c conf.json -T au -t administrative_unit_area_3 -s 30
~~~

### Level 2)
#### 1) Extract objects around a country's boundaries
<u>The Netherlands:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_2 -d 1000 nl '#'
~~~

<u>Belgium:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_2 -d 1000 be '#'
~~~

<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_2 --d 1000 fr '#'
~~~

#### 2) Matching
Copy lower level administrative unit table in the public schema:

<u>The Netherlands, Belgium, France:</u>
~~~
python3 script/copy_table.py -c conf.json au.administrative_unit_area_3
~~~

Run process:

<u>The Netherlands:</u>
~~~
bin/au_merging --c data/config/epg_parameters.ini --s prod.administrative_unit_area_3 --t work.administrative_unit_area_2_w --cc nl
~~~

<u>Belgium:</u>
~~~
bin/au_merging --c data/config/epg_parameters.ini --s prod.administrative_unit_area_3 --t work.administrative_unit_area_2_w --cc be
~~~

<u>France:</u>
~~~
bin/au_merging --c data/config/epg_parameters.ini --s prod.administrative_unit_area_3 --t work.administrative_unit_area_2_w --cc fr
~~~

#### 3)  Integrate modifications in the main table and working history (wh) table
Before running the integrate, check in the log file whether invalid polygons have been generated by the matching process. If there are some, correct them in QGIS.

~~~
python3 script/integrate.py -c conf.json -T au -t administrative_unit_area_2 -s 30
~~~

### Level 1)
#### 1) Extract objects around a country's boundaries
<u>The Netherlands:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_1 -d 1000 nl '#'
~~~

<u>Belgium:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_1 -d 1000 be '#'
~~~

<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_area_1 -d 1000 fr '#'
~~~

#### 2) Matching
Copy lower level administrative unit table in the public schema:

<u>The Netherlands, Belgium, France:</u>
~~~
python3 script/copy_table.py -c conf.json au.administrative_unit_area_2
~~~

Run process:

<u>The Netherlands:</u>
~~~
bin/au_merging --c data/config/epg_parameters.ini --s prod.administrative_unit_area_2 --t work.administrative_unit_area_1_w --cc nl
~~~

<u>Belgium:</u>
~~~
bin/au_merging --c data/config/epg_parameters.ini --s prod.administrative_unit_area_2 --t work.administrative_unit_area_1_w --cc be
~~~

<u>France:</u>
~~~
bin/au_merging --c data/config/epg_parameters.ini --s prod.administrative_unit_area_2 --t work.administrative_unit_area_1_w --cc fr
~~~

#### 3)  Integrate modifications in the main table and working history (wh) table
~~~
python3 script/integrate.py -c conf.json -T au -t administrative_unit_area_1 -s 30
~~~


## Rollback
Go back to step N (cancel modifications including those performed by step N):
~~~
python3 script/revert.py -c conf.json -T hy -t watercourse_link -s 10
python3 script/revert.py -c conf.json -T tn -t road_link -s 10
python3 script/revert.py -c conf.json -T tn -t railway_link -s 10
python3 script/revert.py -c conf.json -T au -t administrative_unit_area_3 -s 30
~~~


