#!/bin/sh

cd ..
python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -d 1000 be '#'
python3 data-tools/script/clean.py -c conf.json -d 5 -T tn -t railway_link_w be
python3 data-tools/script/integrate.py -c conf.json -T tn -t railway_link -s 10

#python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -d 1000 fr '#'
python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -b false -B international -d 3000 fr
python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -b ad -d 3000 -n fr
python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -b mc -d 3000 -n fr
python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -b lu -d 3000 -n fr
python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -b it -d 3000 -n fr
python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -b es -d 3000 -n fr
python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -b ch -d 3000 -n fr
python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -b de -d 3000 -n fr
python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -b be -d 3000 -n fr
python3 data-tools/script/clean.py -c conf.json -d 5 -T tn -t railway_link_w fr
python3 data-tools/script/integrate.py -c conf.json -T tn -t railway_link -s 10

python3 data-tools/script/border_extraction.py -c conf.json -T tn -t railway_link -d 1000 nl '#'
python3 data-tools/script/clean.py -c conf.json -d 5 -T tn -t railway_link_w nl
python3 data-tools/script/integrate.py -c conf.json -T tn -t railway_link -s 10