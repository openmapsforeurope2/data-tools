# data-tools

## Paramètrages

paramètres communs:
* c [obligatoire] : fichier de configuration
* T [obligatoire] : thème (on ne peut spécifier qu'un seul thème)
* t [optionnel] : table (on peut spécifier plusieurs tables en ajoutant autant de fois cette option). Les tables doivent appartenir au thème T

border_extraction:
* d [obligatoire] : rayon du buffer (en degrés)
* b [optionnel] : code du pays frontalier
* arguments : le(s) code(s) pays à extraire (un ou deux)

integration:
* s [obligatoire] : numéro de l'étape

reversion:
* s [obligatoire] : numéro de l'étape

table_creation:
* m [obligatoire] : fichier de configuration du mcd


## Creation des tables
~~~
python3 script/table_creation.py -c conf.json -m mcd.json -T tn -t road_link
~~~


## Etape de nettoyage (10)
### 1) Extraction des objets autour des frontières d'un pays pour l'étape de nettoyage:
~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 3000 fr
~~~
~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 be
~~~

### 2) Etape de nettoyage - suppression des objets hors territoire - (se placer dans le répertoire du projet data-cleaner):
~~~
python3 script/clean.py -c conf.json -T tn -t road_link_w fr
~~~
~~~
python3 script/clean.py -c conf.json -T tn -t road_link_w be
~~~

### 3) Intégration des modifications dans la table principale et la table d'historique:
~~~
python3 script/integration.py -c conf.json -T tn -t road_link -s 10
~~~


## Etape de matching (20)
### 1) Extraction des objets autour des frontières d'un couple de pays pour l'étape de matching:
~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 1000 be fr
~~~

### 2) Etape de matching
creation_cn -c conf.json -t road_link

road_link modifiée avec mise à jour du champ modification_type


### 3) Intégration des modifications dans la table principale et la table d'historique:
~~~
python3 script/integration.py -c conf.json -T tn -t road_link -s 20
~~~


## Etape de matching administratif (30)
### 1) Extraction des objets autour des frontières d'un pays matching:

#### Belgique:
Exemple d'extraction autour des frontières avec un seul pays frontalier:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_5 -b nl -d 1000 be
~~~

Exemple d'extraction autour des frontières avec plusieurs pays frontaliers:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_5 -b nl -d 1000 be
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_5 -b de -d 1000 -n be
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_5 -b lu -d 1000 -n be
~~~

Exemple d'extraction autour de toutes les frontières:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_5 -d 1000 be '#'
~~~

#### Pays-Bas:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_3 -d 1000 nl '#'
~~~

#### France:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_6 -d 1000 fr '#'
~~~

### 2) Etape de matching
Copier les tables des frontières et des contours des pays dans le schéma public:
~~~
python3 script/table_copy.py -c conf.json au.administrative_unit_1 ib.international_boundary_line
~~~

Lancer le traitement:
#### Belgique:
~~~
bin/ome2_au_matching --c data/config/epg_parameters.ini --t administrative_unit_5_w --cc be
~~~

#### Pays-Bas:
~~~
bin/ome2_au_matching --c data/config/epg_parameters.ini --t administrative_unit_3_w --cc nl
~~~

#### France
~~~
au_matching --c conf.json --t administrative_unit_6_w fr
~~~

### 3) Intégration des modifications dans la table principale et la table d'historique:
Dans un premier temps, vérifier dans le fichier de log si des polygones non-valides ont été générés au cours de processus de matching, les corriger dans QGIS le cas échéant.

#### Belgique:
~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_5 -s 30
~~~

#### France:
~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_6 -s 30
~~~


## Etape de merging administratif (30)
### Niveau 5)
#### 1) Extraction des objets autour des frontières d'un pays:
#### France:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_5 -b be -d 1000 fr '#'
~~~

#### 2) Etape de merging
Copier les tables des surfaces administratives de niveau inférieur dans le schéma public:
~~~
DROP TABLE IF EXISTS au_administrative_unit_6; CREATE TABLE au_administrative_unit_6 AS TABLE au.administrative_unit_6;
~~~

Lancer le traitement:
#### France
~~~
au_merging --c path/to/epg_parameters.ini --s au_administrative_unit_6 --t administrative_unit_5_w --cc fr
~~~

#### 3) Intégration des modifications dans la table principale et la table d'historique:
~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_5 -s 30
~~~


### Niveau 4)
#### 1) Extraction des objets autour des frontières d'un pays:
#### Belgique:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_4 -d 1000 be '#'
~~~

#### France:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_4 -d 1000 fr '#'
~~~

#### 2) Etape de merging
Copier les tables des surfaces administratives de niveau inférieur dans le schéma public:
#### Belgique:
~~~
DROP TABLE IF EXISTS au_administrative_unit_5; CREATE TABLE au_administrative_unit_5 AS TABLE au.administrative_unit_5;
~~~

#### France:
~~~
DROP TABLE IF EXISTS au_administrative_unit_6; CREATE TABLE au_administrative_unit_6 AS TABLE au.administrative_unit_6;
~~~

Lancer le traitement:
#### Belgique:
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_5 --t administrative_unit_4_w --cc be
~~~

#### France:
~~~
au_matching -c path/to/epg_parameters.ini -s au_administrative_unit_6 -t administrative_unit_4_w --cc fr
~~~

#### 3) Intégration des modifications dans la table principale et la table d'historique:
Dans un premier temps, vérifier dans le fichier de log si des polygones non-valides ont été générés au cours de processus de matching, les corriger dans QGIS le cas échéant.

~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_4 -s 30
~~~

### Niveau 3)
#### 1) Extraction des objets autour des frontières d'un pays matching:
#### Belgique:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_3 -b nl -d 1000 be
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_3 -b de -d 1000 -n be
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_3 -b lu -d 1000 -n be
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_3 -b fr -d 1000 -n be
~~~

#### France:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_3 -b be -d 1000 fr '#'
~~~

#### 2) Etape de matching
Copier les tables des surfaces administratives de niveau inférieur dans le schéma public:
Belgique, France:
~~~
DROP TABLE IF EXISTS au_administrative_unit_4; CREATE TABLE au_administrative_unit_4 AS TABLE au.administrative_unit_4;
~~~

Lancer le traitement:
#### Belgique:
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_4 --t administrative_unit_3_w --cc be
~~~

#### France
~~~
au_matching -c path/to/epg_parameters.ini -s au_administrative_unit_4 -t administrative_unit_3_w fr
~~~

#### 3) Intégration des modifications dans la table principale et la table d'historique:
Dans un premier temps, vérifier dans le fichier de log si des polygones non-valides ont été générés au cours de processus de matching, les corriger dans QGIS le cas échéant.

~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_3 -s 30
~~~

### Niveau 2)
#### 1) Extraction des objets autour des frontières d'un pays matching:
#### Belgique:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_2 -d 1000 be '#'
~~~

#### France:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_2 --d 1000 fr '#'
~~~

#### 2) Etape de matching
Copier les tables des surfaces administratives de niveau inférieur dans le schéma public:
Belgique, France:
~~~
DROP TABLE IF EXISTS au_administrative_unit_3; CREATE TABLE au_administrative_unit_3 AS TABLE au.administrative_unit_3;
~~~

Lancer le traitement:
#### Belgique:
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_3 --t administrative_unit_2_w --cc be
~~~

#### France
~~~
au_matching -c path/to/epg_parameters.ini -s au_administrative_unit_3 -t administrative_unit_2_w fr
~~~

#### 3) Intégration des modifications dans la table principale et la table d'historique:
Dans un premier temps, vérifier dans le fichier de log si des polygones non-valides ont été générés au cours de processus de matching, les corriger dans QGIS le cas échéant.

~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_2 -s 30
~~~

### Niveau 1)
#### 1) Extraction des objets autour des frontières d'un pays matching:
#### Belgique:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_1 -d 1000 be '#'
~~~

#### France:
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_1 -d 1000 fr '#'
~~~

#### 2) Etape de matching
Copier les tables des surfaces administratives de niveau inférieur dans le schéma public:
~~~
DROP TABLE IF EXISTS au_administrative_unit_2; CREATE TABLE au_administrative_unit_2 AS TABLE au.administrative_unit_2;
~~~

Lancer le traitement:
#### Belgique:
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_2 --t administrative_unit_1_w --cc be
~~~

#### France:
~~~
au_matching -c path/to/epg_parameters.ini -s au_administrative_unit_2 -t administrative_unit_1_w fr
~~~

#### 3) Intégration des modifications dans la table principale et la table d'historique:
~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_1 -s 30
~~~



## Rollback
Retour à l'étape N (annulation des changement jusqu'à l'étape N incluse):
~~~
python3 script/revertion.py -c conf.json -T tn -t road_link -s 10
python3 script/revertion.py -c conf.json -T au -t administrative_unit_4 -s 30
~~~


