# data-tools

## Context

Open Maps For Europe 2 est un projet qui a pour objectif de développer un nouveau processus de production dont la finalité est la construction d'un référentiel cartographique pan-européen à grande échelle (1:10 000).

L'élaboration de la chaîne de production a nécessité le développement d'un ensemble de composants logiciels qui constituent le projet [OME2](https://github.com/openmapsforeurope2/OME2).


## Description

Cette application regroupe l'ensemble des fonctionnalités du projet OME2 qui consistent à éxecuter des scripts SQL.

Les outils proposés sont les suivants :

- create_table : génére et lance les scripts de création de l'ensemble des tables nécessaires au fonctionnement du projet OME2.
- border_extract : sert à l'extraction des objets proches d'une frontière d'une table source vers un table cible.
- integrate : ré-intégrate dans la table source des données extraites et traitées dans la table de travail. Un numéro de 'step' est attribué aux données modifiées et crées.
- revert : annule les modifications correspondant au 'step' indiqué en paramêtre. Toutes les modifications liées aux 'steps' postérieurs sont annulées également.
- copy_table : copie les tables localisées dans un schéma vers le schéma public.
- clean : supprime les données hors de leur pays (à partir d'un seuil d'éloignement). Ce nettoyage constitue la première étape des processus de mise en cohérence des données aux frontières.

On trouve également dans ce projet les [scripts SQL](https://github.com/openmapsforeurope2/data-tools/tree/main/sql/db_init) destinés à la mise en place des méchanismes interne de la base OME2 (gestion de l'historique, de la résolution, des identifiants...)


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
* d [mandatory] : buffer radius
* b [optional] : neighbouring country code
* n [optional] : option which enables not to delete data already present in the work table
* arguments : codes of country/countries to extract (one or two)

<br>

Exemple d'extraction des données d'un pays sur l'ensemble de ses frontières :
~~~
python3 script/border_extract.py -c conf.json -T tn -t road_link -d 4000 nl '#'
~~~

Exemple d'extraction des données de deux pays frontaliers:
~~~
python3 script/border_extract.py -c conf.json -T hy -t watercourse_link -d 1000 be fr
~~~

Exemple d'extraction de l'ensemble des données d'un pays et des données des pays limitrophes frontière par frontière:
~~~
python3 script/border_extract.py -c conf.json -T tn -t road_link -b false -B international -d 3000 fr
python3 script/border_extract.py -c conf.json -T tn -t road_link -b ad -d 3000 -n fr
python3 script/border_extract.py -c conf.json -T tn -t road_link -b mc -d 3000 -n fr
python3 script/border_extract.py -c conf.json -T tn -t road_link -b lu -d 3000 -n fr
python3 script/border_extract.py -c conf.json -T tn -t road_link -b it -d 3000 -n fr
python3 script/border_extract.py -c conf.json -T tn -t road_link -b es -d 3000 -n fr
python3 script/border_extract.py -c conf.json -T tn -t road_link -b ch -d 3000 -n fr
python3 script/border_extract.py -c conf.json -T tn -t road_link -b de -d 3000 -n fr
python3 script/border_extract.py -c conf.json -T tn -t road_link -b be -d 3000 -n fr
~~~
> _Note : la première ligne permet d'extraire les données autour des frontières internationales qui ont un code pays simple. Cela correspond aux frontières non reconnues ('in dispute')._


### integrate

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* s [mandatory] : step number

<br>

Exemples d'appel:
~~~
python3 script/integrate.py -c conf.json -T tn -t road_link -s 10
~~~


### revert

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* s [mandatory] : step number

<br>

Exemples d'appel:
~~~
python3 script/reverte.py -c conf.json -T au -t administrative_unit_area_3 -s 30
~~~


### create_table

Cette fonction permet de créer une table ou l'ensemble des tables d'un thème.

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* m [mandatory] : conceptual data model configuration file

<br>

Exemples d'appel pour la création de l'ensemble des tables du thème transport :
~~~
python3 script/create_table.py -c conf.json -m mcd.json -T tn
~~~

Exemples d'appel pour la création d'une seul table :
~~~
python3 script/create_table.py -c conf.json -m mcd.json -T tn -t railway_link
~~~


### clean

Paramètres
* c [mandatory] : configuration file
* T [mandatory] : theme (only one theme can be specified)
* t [optional] : table (several tables can be specified by adding that option as many times as necessary). Tables must belong to theme T
* d [mandatory] : cleaning distance
* arguments : codes of country/countries to clean

<br>

Exemples d'appel:
~~~
python3 script/clean.py -c conf.json -d 5 -T tn -t road_link_w be
~~~


### copy_table

Cette fonction permet de copier la table schema.table dans public.schema_table.

Paramètres
* c [mandatory] : configuration file
* arguments : table(s) to copy

<br>

Exemples d'appel:
~~~
python3 script/copy_table.py -c conf.json au.administrative_unit_area_1 ib.international_boundary_line
~~~

### integrate_from_validation
~~~
python3 script/integrate_from_validation.py -c conf.json -T hy at cz
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
python3 script/create_table.py -c conf.json -m mcd.json -T tn
python3 script/create_table.py -c conf.json -m mcd.json -T hy
python3 script/create_table.py -c conf.json -m mcd.json -T au
python3 script/create_table.py -c conf.json -m mcd.json -T ib
~~~


#### Historisation des tables
~~~
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/HVLSP_2_GCMS_1_COMMON.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/HVLSP_3_GCMS_3_HISTORIQUE.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/ign_gcms_history_trigger_function.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -f ./sql/db_init/HVLSP_4_GCMS_4_OME2_ADD_HISTORY.sql
psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_test_cd -c "ALTER SEQUENCE public.seqnumrec OWNER TO g_ome2_user;"
~~~
