# data-tools

## Paramètrages

paramètres communs:
* c [obligatoire] : fichier de configuration
* T [obligatoire] : thème (on ne peut spécifier qu'un seul thème)
* t [optionnel] : table (on peut spécifier plusieurs tables en ajoutant autant de fois cette option). Les tables doivent appartenir au thème T

border_extraction:
* d [obligatoire] : rayon du buffer (en degrés)
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


### 3) Intégration des modifications dans la table principale et la table d'historique:
~~~
python3 script/integration.py -c conf.json -T tn -t road_link -s 20
~~~



## Rollback
Retour à l'étape N (annulation des changement jusqu'à l'étape N incluse):
~~~
python3 script/revertion.py -c conf.json -T tn -t road_link -s 10
~~~


