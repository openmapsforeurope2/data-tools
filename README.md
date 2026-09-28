# data-tools

## Context

Open Maps For Europe 2 est un projet qui a pour objectif de développer un nouveau processus de production dont la finalité est la construction d'un référentiel cartographique pan-européen à grande échelle (1:10 000).

L'élaboration de la chaîne de production a nécessité le développement d'un ensemble de composants logiciels qui constituent le projet [OME2](https://github.com/openmapsforeurope2/OME2).


## Description

Cette application regroupe l'ensemble des fonctionnalités du projet OME2 qui consistent à éxecuter des scripts SQL.


## Configuration

La configuration de ce projet décrit le modèle de données des tables et la structure de la base de données OME2.

Les fichiers de configuration se trouvent dans le [dossier de configuration](https://github.com/openmapsforeurope2/data-tools/tree/main/conf) et sont les suivants :
- conf.json :  ce fichier liste les tables constituant chaque thème, leur répartition dans les différents schémas, leur principaux champs (champs de travail, identifiant, géométrie, code pays). C'est également dans ce fichier qu'est précisé le système de nommage des tables (suffix des table de travail, de référence, de mise à jour...). C'est la configuration de base utilisé par tous les outils. Il pointe sur le fichier de db_conf.json.
- db_conf.json : informations de connexion à la base de données.
- mcd.json : ce fichier décrit le modèle de données de l'ensemble des tables. Il n'est utilisé que par la fonction 'create_table'.


## Utilisation

Tous les outils sont utilisés en ligne de commande.


### border_extract

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* r [mandatory] : buffer radius
* s [mandatory] : suffix applied for working table naming.
* a [optional] : extract all objects and not only the neighbouring country objets
* B [optional] : boundary type (must be in : "international","maritime","land_maritime","coastline","inland_water")
* d [optional] : database name
* b [optional] : neighbouring country code
* n [optional] : option which enables not to delete data already present in the work table
* arguments : codes of country/countries to extract (one or two)

Le coût du plus gros pays c'est quand on fait plusieurs imports successifs: il faut commencer par les plus petits et finir par les plus gros

<br>

Exemple d'extraction des données d'un pays sur l'ensemble de ses frontières :
~~~
python3 script/border_extract.py -c path/to/conf.json -T tn -t road_link -s 20260928 -r 4000 nl '#'
~~~

Exemple d'extraction des données de deux pays frontaliers :
~~~
python3 script/border_extract.py -c path/to/conf.json -T hy -t watercourse_link -s 20260928 -r 1000 be fr
~~~

Exemple d'extraction de toutes les données autour de la frontière be#fr (toutes les requêtes sont équivalentes) :
~~~
python3 script/border_extract.py -c path/to/conf.json -T hy -t watercourse_link -s 20260928 -r 1000 -a be fr
python3 script/border_extract.py -c path/to/conf.json -T hy -t watercourse_link -s 20260928 -r 1000 -a -b be fr
python3 script/border_extract.py -c path/to/conf.json -T hy -t watercourse_link -s 20260928 -r 1000 -a -b fr be
~~~

Exemple d'extraction des données 'be' autour de la frontière be#fr :
~~~
python3 script/border_extract.py -c path/to/conf.json -T hy -t watercourse_link -r 1000 -b fr be
~~~

Exemple d'extraction de l'ensemble des données d'un pays et des données des pays limitrophes frontière par frontière:
~~~
python3 script/border_extract.py -c path/to/conf.json -T tn -t road_link -s 20260928 -b false -B international -r 3000 fr
python3 script/border_extract.py -c path/to/conf.json -T tn -t road_link -s 20260928 -b ad -r 3000 -n fr
python3 script/border_extract.py -c path/to/conf.json -T tn -t road_link -s 20260928 -b mc -r 3000 -n fr
python3 script/border_extract.py -c path/to/conf.json -T tn -t road_link -s 20260928 -b lu -r 3000 -n fr
python3 script/border_extract.py -c path/to/conf.json -T tn -t road_link -s 20260928 -b it -r 3000 -n fr
python3 script/border_extract.py -c path/to/conf.json -T tn -t road_link -s 20260928 -b es -r 3000 -n fr
python3 script/border_extract.py -c path/to/conf.json -T tn -t road_link -s 20260928 -b ch -r 3000 -n fr
python3 script/border_extract.py -c path/to/conf.json -T tn -t road_link -s 20260928 -b de -r 3000 -n fr
python3 script/border_extract.py -c path/to/conf.json -T tn -t road_link -s 20260928 -b be -r 3000 -n fr
~~~
> _Note : la première ligne permet d'extraire les données autour des frontières internationales qui ont un code pays simple. Cela correspond aux frontières non reconnues ('in dispute')._


### extract

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* s [mandatory] : suffix applied for working table naming.
* d [optional] : database name
* x [optional] : x min extracting box coordinate
* X [optional] : x max extracting box coordinate
* y [optional] : y min extracting box coordinate
* Y [optional] : y max extracting box coordinate
* n [optional] : option which enables not to delete data already present in the work table
* arguments [optional] : codes of country/countries to extract (if no code specified all objects are extracted)

<br>

Exemple d'extraction des données be, fr et lu dans une box :
~~~
python3 script/extract.py -c path/to/conf.json -T tn -t railway_link -s 20260903 -x 4015897 -X 4021467 -y 2941476 -Y 2949763 fr lu be
~~~

Exemple d'extraction des données be, fr et lu :
~~~
python3 script/extract.py -c path/to/conf.json -T tn -t railway_link -s 20260903 fr lu be
~~~

Exemple d'extraction de toutes les données dans une box :
~~~
python3 script/extract.py -c path/to/conf.json -T tn -t railway_link -s 20260903 -x 4015897 -X 4021467 -y 2941476 -Y 2949763
~~~


### integrate

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* d [optional] : database name
* s [mandatory] : suffix applied for working table naming.

<br>

Exemples d'appel:
~~~
python3 script/integrate.py -c path/to/conf.json -T tn -t road_link -s 20260928
~~~


### revert

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* n [mandatory] : numrec
* d [optional] : database name
* h [optional] : specify if the database is historized
* o [optional] : revert only the specified numrec (-n)

<br>

Exemples d'appel:
~~~
python3 script/reverte.py -c path/to/conf.json -T au -t administrative_unit_area_3 -n 3065461
~~~


### create_table

Cette fonction permet de créer une table ou l'ensemble des tables d'un thème.

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* d [optional] : database name

<br>

Exemples d'appel pour la création de l'ensemble des tables du thème transport :
~~~
python3 script/create_table.py -c path/to/conf.json -T tn
~~~

Exemples d'appel pour la création d'une seul table :
~~~
python3 script/create_table.py -c path/to/conf.json -T tn -t railway_link
~~~


### clean

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T. If not defined the cleaning will be processed for all the tables of the theme (specified with -T parameter).
* b [optional] : country code of a border country (several codes can be specified by adding that option as many times as necessary). If this parameter is defined the cleaning will be processed only on the specified border(s).
* i [optional] : if specified the cleaning is processed around in dispute borders.
* a [optional] : parameter ti process the cleaning around all borders of the specified country/countries (c.f. arguments). If specified all defined -b parameters will be ignored.
* d [optional] : database name
* s [mandatory] : suffix applied for working table naming.
* arguments : codes of country/countries to clean

<br>

Exemple de nettoyage de données françaises autour des frontières avec le luxembourg et la belgique.
~~~
python3 script/clean.py -c path/to/conf.json -b lu -b be -T tn -t road_link -s 20260928 fr
~~~

Exemple de nettoyage de données françaises autour de l'ensemble des frontières.
~~~
python3 script/clean.py -c path/to/conf.json -a -T tn -t road_link -s 20260928 fr
~~~

### copy_table

Cette fonction permet de copier la table schema.table dans public.schema_table.

Paramètres
* c [mandatory] : configuration file
* d [optional] : database name
* n [optional] : specify if the database is not historized
* arguments : table(s) to copy

<br>

Exemples d'appel:
~~~
python3 script/copy_table.py -c path/to/conf.json au.administrative_unit_area_1 ib.international_boundary_line
~~~

### prepare_area_matching

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T.
* s [mandatory] : suffix applied for working table naming.
* d [optional] : database name
* arguments : codes of two border countries

Exemple de preparation des données :
~~~
python3 script/prepare_area_matching.py -c path/to/conf.json -n -T hy -t glacier_snowfield -s 20250904 ch fr
~~~

### prepare_au_matching

Paramètres
* c [mandatory] : configuration file
* b [optional] : country code of a border country (several codes can be specified by adding that option as many times as necessary). If this parameter is defined the matching will be processed only on the specified border(s).
* s [mandatory] : suffix applied for working table naming.
* d [optional] : database name
* l [optional] : administrative level to match. Country lowest level if not specified.
* arguments : country code (only one allowed)

Exemple de preparation des données :
~~~
python3 script/prepare_au_matching.py -c path/to/conf.json -l 3 -s 20250904 -b fr be
~~~

### prepare_net_matching_validation

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T.
* s [mandatory] : suffix applied for working table naming.
* d [optional] : database name

Exemple de preparation des données :
~~~
python3 script/prepare_net_matching_validation.py -c path/to/conf.json -T tn -t road_link -s 20250904
~~~

### prepare_net_matching

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T.
* s [mandatory] : suffix applied for working table naming.
* d [optional] : database name
* arguments : codes of two border countries

Exemple de preparation des données :
~~~
python3 script/prepare_net_matching.py -c path/to/conf.json -T tn -t road_link -s 20250904 be fr
~~~


### integrate_area_matching

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T.
* s [mandatory] : suffix applied for working table naming.
* d [optional] : database name

Exemple de preparation des données :
~~~
python3 script/integrate_area_matching.py -c path/to/conf.json -T hy -t glacier_snowfield -s 20250904
~~~


### integrate_au_matching

Paramètres
* c [mandatory] : configuration file
* l [optional] : administrative level to integrate. Country lowest level if not specified.
* s [mandatory] : suffix applied for working table naming.
* d [optional] : database name
* arguments : country code (only one allowed if no level specified)

Exemple de preparation des données :
~~~
python3 script/integrate_au_matching.py -c path/to/conf.json -s 20250904 be
python3 script/integrate_au_matching.py -c path/to/conf.json -l 4 -s 20250904
~~~


### integrate_au_merging

Paramètres
* c [mandatory] : configuration file
* l [optional] : administrative level to integrate. Country lowest level if not specified.
* s [mandatory] : suffix applied for working table naming.
* d [optional] : database name
* arguments [optional] : country code (if no level specified)

Exemple de preparation des données :
~~~
python3 script/integrate_au_merging.py -c path/to/conf.json -l 3 -s 20250904
~~~


### integrate_net_matching_validation

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T.
* s [mandatory] : suffix applied for working table naming.
* d [optional] : database name

Exemple de preparation des données :
~~~
python3 script/integrate_net_matching_validation.py -c path/to/conf.json -T tn -t road_link -s 20250904
~~~


### integrate_net_point_matching

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T.
* s [mandatory] : suffix applied for working table naming.
* d [optional] : database name

Exemple de preparation des données :
~~~
python3 script/integrate_net_point_matching.py -c path/to/conf.json -T hy -t hydro_node -s 20250904
~~~


### Création de la Base de Données OME2

Ci-après est présenté la liste ordonnancé des commandes à lancer pour créer la base de onnées OME2.


#### Initialisation de la structure
~~~
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d OME2 -f ./sql/db_init/HVLSP_0_GCMS_0_ADMIN.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d OME2 -f ./sql/db_init/HVLSP_1_CREATE_SCHEMAS.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d OME2 -f ./sql/db_init/ome2_reduce_precision_3d_trigger_function.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d OME2 -f ./sql/db_init/ome2_reduce_precision_2d_trigger_function.sql
~~~


#### Création des tables

Création de toutes les tables pour l'ensemble des schémas:

~~~
python3 script/create_table.py -c path/to/conf.json -m mcd.json -T tn
python3 script/create_table.py -c path/to/conf.json -m mcd.json -T hy
python3 script/create_table.py -c path/to/conf.json -m mcd.json -T au
python3 script/create_table.py -c path/to/conf.json -m mcd.json -T ib
~~~


#### Historisation des tables
~~~
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/HVLSP_2_GCMS_1_COMMON.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/HVLSP_3_GCMS_3_HISTORIQUE.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/ign_gcms_history_trigger_function.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/HVLSP_4_GCMS_4_OME2_ADD_HISTORY.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -c "ALTER SEQUENCE public.seqnumrec OWNER TO g_ome2_user;"
~~~
