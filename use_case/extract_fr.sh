#!/bin/sh

echo $(date)

python3 border_extract.py -c conf.json -T tn -t road_link -b false -B international -d 3000 fr
python3 border_extract.py -c conf.json -T tn -t road_link -b be -d 3000 -n fr
python3 border_extract.py -c conf.json -T tn -t road_link -b lu -d 3000 -n fr
python3 border_extract.py -c conf.json -T tn -t road_link -b de -d 3000 -n fr
python3 border_extract.py -c conf.json -T tn -t road_link -b ch -d 3000 -n fr
python3 border_extract.py -c conf.json -T tn -t road_link -b it -d 3000 -n fr
python3 border_extract.py -c conf.json -T tn -t road_link -b mc -d 3000 -n fr
python3 border_extract.py -c conf.json -T tn -t road_link -b es -d 3000 -n fr
python3 border_extract.py -c conf.json -T tn -t road_link -b ad -d 3000 -n fr

echo $(date)