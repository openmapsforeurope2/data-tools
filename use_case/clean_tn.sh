#!/bin/sh

cd ..
# AT all TN layers, country by country (02/04/2025)
python3 script/border_extract.py -c conf_v6.json -T tn -b de -d 1000 at
python3 script/border_extract.py -c conf_v6.json -T tn -b ch -d 1000 -n at
python3 script/border_extract.py -c conf_v6.json -T tn -b cz -d 1000 -n at
python3 script/border_extract.py -c conf_v6.json -T tn -b hu -d 1000 -n at
python3 script/border_extract.py -c conf_v6.json -T tn -b it -d 1000 -n at
python3 script/border_extract.py -c conf_v6.json -T tn -b li -d 1000 -n at
python3 script/border_extract.py -c conf_v6.json -T tn -b si -d 1000 -n at
python3 script/border_extract.py -c conf_v6.json -T tn -b sk -d 1000 -n at
python3 script/clean.py -c conf_v6.json -d 5 -T tn at
python3 script/integrate.py -c conf_v6.json -T tn -s 10

# BE road_link only
python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -d 1000 be '#'
python3 data-tools/script/clean.py -c conf.json -d 5 -T tn -t road_link_w be
python3 data-tools/script/integrate.py -c conf.json -T tn -t road_link -s 10

# CZ all TN layers
python3 script/border_extract.py -c conf_v6.json -T tn -d 1000 cz #
python3 script/clean.py -c conf_v6.json -d 5 -T tn cz
python3 script/integrate.py -c conf_v6.json -T tn -s 10

# FR (trop lourd pour faire toutes les frontières d'un coup) road_link only
#python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -d 1000 fr '#'
python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -b false -B international -d 3000 fr
python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -b ad -d 3000 -n fr
python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -b mc -d 3000 -n fr
python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -b lu -d 3000 -n fr
python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -b it -d 3000 -n fr
python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -b es -d 3000 -n fr
python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -b ch -d 3000 -n fr
python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -b de -d 3000 -n fr
python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -b be -d 3000 -n fr
python3 data-tools/script/clean.py -c conf.json -d 5 -T tn -t road_link_w fr
python3 data-tools/script/integrate.py -c conf.json -T tn -t road_link -s 10

python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -d 1000 nl '#'
python3 data-tools/script/clean.py -c conf.json -d 5 -T tn -t road_link_w nl
python3 data-tools/script/integrate.py -c conf.json -T tn -t road_link -s 10

# CH all TN layers
#python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -d 1000 ch '#'
#python3 data-tools/script/clean.py -c conf.json -d 5 -T tn -t road_link_w ch
#python3 data-tools/script/integrate.py -c conf.json -T tn -t road_link -s 10
#[UPDATE 01/10/2024] Clean launched on all tables at once
python3 data-tools/script/border_extract.py -c conf.json -T tn -d 1000 ch '#'
python3 data-tools/script/clean.py -c conf.json -d 5 -T tn ch
python3 data-tools/script/integrate.py -c conf.json -T tn -s 10

# LU all TN layers
#python3 data-tools/script/border_extract.py -c conf.json -T tn -t road_link -d 1000 lu '#'
#python3 data-tools/script/clean.py -c conf.json -d 5 -T tn -t road_link_w lu
#python3 data-tools/script/integrate.py -c conf.json -T tn -t road_link -s 10 # Lancer avec -n sur v4 non historisée

#[UPDATE 01/10/2024] Clean launched on all tables at once
python3 data-tools/script/border_extract.py -c conf.json -T tn -d 1000 lu '#'
python3 data-tools/script/clean.py -c conf.json -d 5 -T tn lu
python3 data-tools/script/integrate.py -c conf.json -T tn -s 10