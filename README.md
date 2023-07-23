# data-tools

## Paramètrages

paramètres communs:
* c [obligatoire] : fichier de configuration
* T [obligatoire] : thème (on ne peut spécifier qu'un seul thème)
* t [optionnel] : table (on peut spécifier plusieurs tables en ajoutant autant de fois cette option). Les tables doivent appartenir au thème T

border_extraction:
* d [obligatoire] : rayon du buffer (en degrés)
* b [optionnel] : code du pays frontalier
* n [optionnel] : option pour ne pas supprimer les données déjà extraites dans la table de travail
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
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 3000 fr '#'

// ou
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

~~~
python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 be '#'
~~~

### 2) Etape de nettoyage - suppression des objets hors territoire - (se placer dans le répertoire du projet data-cleaner):

<u>Pays-Bas:</u>
~~~
python3 script/clean.py -c conf.json -d 100 -T tn -t road_link_w nl
~~~

<u>Belgique:</u>
~~~
python3 script/clean.py -c conf.json -d 100 -T tn -t road_link_w be
~~~

<u>France:</u>
~~~
python3 script/clean.py -c conf.json -d 100 -T tn -t road_link_w fr
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

<u>Pays-Bas:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_3 -d 1000 nl '#'
~~~

<u>Belgique:</u>

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

<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_6 -d 1000 fr '#'
~~~

### 2) Etape de matching
Copier les tables des frontières et des contours des pays dans le schéma public:
~~~
python3 script/table_copy.py -c conf.json au.administrative_unit_1 ib.international_boundary_line
~~~

Lancer le traitement:

<u>Pays-Bas:</u>
~~~
bin/ome2_au_matching --c data/config/epg_parameters.ini --t administrative_unit_3_w --cc nl
~~~

<u>Belgique:</u>
~~~
bin/ome2_au_matching --c data/config/epg_parameters.ini --t administrative_unit_5_w --cc be
~~~

<u>France:</u>
~~~
bin/ome2_au_matching --c data/config/epg_parameters.ini --t administrative_unit_6_w --cc fr
~~~

### 3) Intégration des modifications dans la table principale et la table d'historique:
Dans un premier temps, vérifier dans le fichier de log si des polygones non-valides ont été générés au cours de processus de matching, les corriger dans QGIS le cas échéant.

<u>Pays-Bas:</u>
~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_3 -s 30
~~~

<u>Belgique:</u>
~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_5 -s 30
~~~

<u>France:</u>
~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_6 -s 30
~~~


## Etape de merging administratif (30)
### Niveau 5)
#### 1) Extraction des objets autour des frontières d'un pays:
<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_5 -d 1000 fr '#'
~~~

#### 2) Etape de merging
Copier les tables des surfaces administratives de niveau inférieur dans le schéma public:
~~~
python3 script/table_copy.py -c conf.json au.administrative_unit_6
~~~

Lancer le traitement:

<u>France:</u>
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_6 --t administrative_unit_5_w --cc fr
~~~

#### 3) Intégration des modifications dans la table principale et la table d'historique:
~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_5 -s 30
~~~


### Niveau 4)
#### 1) Extraction des objets autour des frontières d'un pays:
<u>Belgique:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_4 -d 1000 be '#'
~~~

<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_4 -d 1000 fr '#'
~~~

#### 2) Etape de merging
Copier les tables des surfaces administratives de niveau inférieur dans le schéma public:

<u>Belgique:</u>
~~~
python3 script/table_copy.py -c conf.json au.administrative_unit_5
~~~

<u>France:</u>
~~~
python3 script/table_copy.py -c conf.json au.administrative_unit_6
~~~

Lancer le traitement:

<u>Belgique:</u>
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_5 --t administrative_unit_4_w --cc be
~~~

<u>France:</u>
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_6 --t administrative_unit_4_w --cc fr
~~~

#### 3) Intégration des modifications dans la table principale et la table d'historique:
Dans un premier temps, vérifier dans le fichier de log si des polygones non-valides ont été générés au cours de processus de matching, les corriger dans QGIS le cas échéant.

~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_4 -s 30
~~~

### Niveau 3)
#### 1) Extraction des objets autour des frontières d'un pays matching:

<u>Belgique:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_3 -d 1000 be '#'
~~~

<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_3 -d 1000 fr '#'
~~~

#### 2) Etape de matching
Copier les tables des surfaces administratives de niveau inférieur dans le schéma public:

<u>Belgique, France:</u>
~~~
python3 script/table_copy.py -c conf.json au.administrative_unit_4
~~~

Lancer le traitement:

<u>Belgique:</u>
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_4 --t administrative_unit_3_w --cc be
~~~

<u>France:</u>
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_4 --t administrative_unit_3_w --cc fr
~~~

#### 3) Intégration des modifications dans la table principale et la table d'historique:
Dans un premier temps, vérifier dans le fichier de log si des polygones non-valides ont été générés au cours de processus de matching, les corriger dans QGIS le cas échéant.

~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_3 -s 30
~~~

### Niveau 2)
#### 1) Extraction des objets autour des frontières d'un pays matching:
<u>Pays-Bas:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_2 -d 1000 nl '#'
~~~

<u>Belgique:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_2 -d 1000 be '#'
~~~

<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_2 --d 1000 fr '#'
~~~

#### 2) Etape de matching
Copier les tables des surfaces administratives de niveau inférieur dans le schéma public:

<u>Pays-Bas, Belgique, France:</u>
~~~
python3 script/table_copy.py -c conf.json au.administrative_unit_3
~~~

Lancer le traitement:

<u>Pays-Bas:</u>
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_3 --t administrative_unit_2_w --cc nl
~~~

<u>Belgique:</u>
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_3 --t administrative_unit_2_w --cc be
~~~

<u>France:</u>
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_3 --t administrative_unit_2_w --cc fr
~~~

#### 3) Intégration des modifications dans la table principale et la table d'historique:
Dans un premier temps, vérifier dans le fichier de log si des polygones non-valides ont été générés au cours de processus de matching, les corriger dans QGIS le cas échéant.

~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_2 -s 30
~~~

### Niveau 1)
#### 1) Extraction des objets autour des frontières d'un pays matching:
<u>Pays-Bas:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_1 -d 1000 nl '#'
~~~

<u>Belgique:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_1 -d 1000 be '#'
~~~

<u>France:</u>
~~~
python3 script/border_extraction.py -c conf.json -T au -t administrative_unit_1 -d 1000 fr '#'
~~~

#### 2) Etape de matching
Copier les tables des surfaces administratives de niveau inférieur dans le schéma public:

<u>Pays-Bas, Belgique, France:</u>
~~~
python3 script/table_copy.py -c conf.json au.administrative_unit_2
~~~

Lancer le traitement:

<u>Pays-Bas:</u>
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_2 --t administrative_unit_1_w --cc nl
~~~

<u>Belgique:</u>
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_2 --t administrative_unit_1_w --cc be
~~~

<u>France:</u>
~~~
bin/ome2_au_merging --c data/config/epg_parameters.ini --s au_administrative_unit_2 --t administrative_unit_1_w --cc fr
~~~

#### 3) Intégration des modifications dans la table principale et la table d'historique:
~~~
python3 script/integration.py -c conf.json -T au -t administrative_unit_1 -s 30
~~~


## Rollback
Retour à l'étape N (annulation des changement jusqu'à l'étape N incluse):
~~~
python3 script/revertion.py -c conf.json -T tn -t road_link -s 10
python3 script/revertion.py -c conf.json -T au -t administrative_unit_3 -s 30
~~~


