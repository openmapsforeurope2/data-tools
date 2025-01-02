import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import border_extract


# step 4) On extrait country+neighbours dans les zones de mise à jour
# voir si extraction de country et country# suffisant, sinon voir pour ajouter un param extract_all_countries
# les zones de mise à jour sont celles situées autour des frontières en '#be' à la distance d
# python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 --in_up_area be '#'

# step 7) On extrait country seul depuis _up pour le clean
# python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 --from_up be '#'

# step 12) On extrait les objets autour d'une frontière
# python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 be fr

# step 12a) On extrait les surfaces de mise à jour autout d'une frontière
# python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 --from_area be fr
# Annulée si on peut intégrer l'étape de selection des surfaces autour de la frontière dans la requête d'extraction

# step 12b) On extrait les objets autour d'une frontière qui sont dans les zones de mise à jour
# python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 --in_up_area_w be fr
# Annulée si on peut intégrer l'étape de selection des surfaces autour de la frontière dans la requête d'extraction
# Devient : 
# python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 --in_up_area be fr 

# step 13b) On extrait les objets qui ne sont pas déjà dans _w_id
# python3 script/border_extraction.py -c conf.json -T tn -t road_link -d 4000 be fr -n

# Todo : voir quelle sera la forme du différentiel, voir si développer diff_extraction
# step 15) On extrait les objets deleted et modified du différentiel
# python3 script/border_extraction.py -c conf.json -T tn

# Todo : voir quelle sera la forme du différentiel, voir si développer diff_extraction
# step 17) On extrait les objets created et modified du différentiel depuis _up
# python3 script/border_extraction.py -c conf.json -T tn --from_up

# Todo : voir quelle sera la forme du différentiel, voir si développer diff_extraction
# step 19b) On extrait les objets created et modified du différentiel depuis _up vers _ref
# python3 script/border_extraction.py -c conf.json -T tn --from_up --to_ref


# voir si nécessaire de créer une table des buffer autour des frontières
# y a t il un shéma up ?
# où localiser les tables roadlink_up, roadlink_area_up (renomer roadlink_area_up_w ?), roadlink_ref ?
# que se passe-t-il si une zone de mise à jour est à cheval sur le buffer d'extraction? faut il prendre uniquement les objets situés dans la zone d'intersection entre le buffer et les zone de mise à jour


# road_link --> road_link_w
# border_extraction -T tn -t road_link

# road_link --> road_link_w (avec _up_area)
# border_extraction -T tn -t road_link -in_up_area

# road_link --> road_link_w (avec _up_area_w)
# border_extraction -T tn -t road_link -in_up_area_w

# road_link_up --> road_link_w
# border_extraction -T tn -t road_link -from_up -to_ref

# [themes][u_schema].road_link[update][suffix] --> [themes][schema].road_link[update][reference_suffix]



# road_link_up --> road_link_w
# border_extraction -T tn -t road_link -from_up




# road_link_up_area --> road_link_up_area_w
# border_extraction -T tn -t road_link -from_area

# [themes][u_schema].road_link[update][area_suffix] --> [themes][w_schema].road_link[update][area_suffix][working][suffix]


# soit in_up_area / in_up_area_w
# soit from_area / from_up
# si to_ref il faut from_up

def run(argv):

    currentDir = os.path.dirname(os.path.abspath(__file__))

    boundary_types = ["international","maritime","land_maritime","coastline","inland_water"]

    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    arg_output = None
    arg_dist = None
    arg_bcc = None
    arg_bt = None
    arg_in_up_area = False
    # arg_in_up_area_w = False
    arg_from_up = False
    # arg_from_area = False
    # arg_to_ref = False
    # arg_extract_all_countries = False
    arg_noreset = False
    arg_verbose = False
    arg_help = "{0} -c <conf> -o <output> -v".format(argv[0])
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:T:t:o:d:b:B:aunvh", [
            "conf=", 
            "theme=", 
            "table=", 
            "output=", 
            "distance=", 
            "border_country=", 
            "boundary_type=", 
            "in_up_area",
            # "in_up_area_w",
            "from_up",
            # "from_area",
            # "to_ref",
            # "extract_all_countries",
            "noreset", 
            "verbose",
            "help"
        ])
    except:
        print(arg_help)
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(arg_help)  # print the help message
            sys.exit(1)
        elif opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-T", "--theme"):
            arg_theme = arg
        elif opt in ("-t", "--table"):
            arg_tables.append(arg)
        elif opt in ("-o", "--output"):
            arg_output = arg
        elif opt in ("-d", "--distance"):
            arg_dist = arg
        elif opt in ("-b", "--border_country"):
            arg_bcc = arg
            if arg_bcc == "false":
                arg_bcc = False
        elif opt in ("-B", "--boundary_type"):
            arg_bt = arg
        elif opt in ("-a", "--in_up_area"):
            arg_in_up_area = True
        # elif opt in ("-in_up_area_w"):
        #     arg_in_up_area_w = True
        elif opt in ("-u", "--from_up"):
            arg_from_up = True
        # elif opt in ("-from_area"):
        #     arg_from_area = True
        # elif opt in ("-to_ref"):
        #     arg_to_ref = True
        # elif opt in ("-e", "--extract_all_countries"):
        #     arg_extract_all_countries = True
        elif opt in ("-n", "--noreset"):
            arg_noreset = True
        elif opt in ("-v", "--verbose"):
            arg_verbose = True
        
    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('output:', arg_output)
    print('distance:', arg_dist)
    print('border country:', arg_bcc)
    print('boundary type:', arg_bt)
    print('in_up_area:', arg_in_up_area)
    # print('in_up_area_w:', arg_in_up_area_w)
    print('from_up:', arg_from_up)
    # print('from_area:', arg_from_area)
    # print('to_ref:', arg_to_ref)
    # print('extract_all_countries:', arg_extract_all_countries)
    print('reset:', (not arg_noreset))
    print('verbose:', arg_verbose)

    if arg_bt is not None and arg_bt not in boundary_types:
        print("le paramètre B (boundary_type) doit être choisi parmi les valeurs : " + ",".join(boundary_types))
        sys.exit(1)

    if arg_dist is None:
        print("le paramètre obligatoire --distance (-d) est manquant")
        sys.exit(1)
        
    workspace = os.path.dirname(currentDir)+"/"

    #conf
    if not os.path.isfile(workspace+"conf/"+arg_conf):
        print("le fichier de configuration "+ arg_conf + " n'existe pas.")
        sys.exit(1)
    arg_conf = workspace+"conf/"+arg_conf

    conf = utils.getConf(arg_conf)

    #bd conf
    if not os.path.isfile(workspace+"conf/"+conf["db_conf_file"]):
        print("le fichier de configuration "+ conf["db_conf_file"] + " n'existe pas.")
        sys.exit(1)
    arg_db_conf = workspace+"conf/"+conf["db_conf_file"]

    db_conf = utils.getConf(arg_db_conf)

    #merge confs
    conf.update(db_conf)

    print("[START EXTRACTION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        border_extract.run(
            conf,
            arg_theme,
            arg_tables,
            arg_output,
            arg_dist,
            args,
            arg_bcc,
            arg_bt,
            arg_in_up_area,
            # arg_in_up_area_w,
            arg_from_up,
            # arg_from_area,
            # arg_extract_all_countries,
            (not arg_noreset),
            arg_verbose
        )
    except:
        sys.exit(1)

    print("[END EXTRACTION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

if __name__ == "__main__":
    run(sys.argv)