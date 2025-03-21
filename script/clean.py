import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import clean_


def run(argv):

    currentDir = os.path.dirname(os.path.abspath(__file__))

    arg_conf = ""
    arg_dist = None
    arg_theme = ""
    arg_tables = []
    arg_verbose = False
    arg_help = "{0} -c <conf> -o <output> -v".format(argv[0])
    args = ""
    
    try:
        opts, args = getopt.getopt(argv[1:], "hc:d:T:t:v", ["help",
        "conf=", "dist=", "theme=", "verbose"])
    except:
        print(arg_help)
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(arg_help)  # print the help message
            sys.exit(1)
        elif opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-d", "--dist"):
            arg_dist = arg
        elif opt in ("-T", "--theme"):
            arg_theme = arg
        elif opt in ("-t", "--table"):
            arg_tables.append(arg)
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    print('conf:', arg_conf)
    print('distance:', arg_dist)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('verbose:', arg_verbose)
    print('args:', args)

    workspace = os.path.dirname(currentDir)+"/"

    if arg_dist is None:
        print("le paramètre -d est obligatoire.")
        sys.exit(1)

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


    print("[START CLEANING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        clean_.run(conf, arg_dist, arg_theme, arg_tables, args, arg_verbose)
    except:
        sys.exit(1)
    
    print("[END CLEANING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)