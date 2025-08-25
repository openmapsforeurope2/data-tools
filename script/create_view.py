import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import create_view_


def run(argv):

    currentDir = os.path.dirname(os.path.abspath(__file__))

    arg_conf = ""
    arg_mcd = ""
    arg_theme = ""
    arg_tables = []
    arg_help = "{0} -c <conf> -o <output> -v".format(argv[0])
    args = ""
    
    try:
        opts, args = getopt.getopt(argv[1:], "hc:m:T:t:", ["help",
        "conf=", "mcd=", "theme=", "table="])
    except:
        print(arg_help)
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(arg_help)  # print the help message
            sys.exit(1)
        elif opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-m", "--mcd"):
            arg_mcd = arg
        elif opt in ("-T", "--theme"):
            arg_theme = arg
        elif opt in ("-t", "--table"):
            arg_tables.append(arg)

    print('conf:', arg_conf)
    print('mcd:', arg_mcd)
    print('theme:', arg_theme)
    print('tables:', arg_tables)

    workspace = os.path.dirname(currentDir)+"/"

    #mcd
    if not os.path.isfile(workspace+"conf/"+arg_mcd):
        print("le fichier de configuration "+ arg_mcd + " n'existe pas.")
        sys.exit(1)
    arg_mcd = workspace+"conf/"+arg_mcd

    mcd = utils.getConf(arg_mcd)

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


    print("[START VIEW CREATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        create_view_.createViews(conf, mcd, arg_theme, arg_tables)
    except:
        sys.exit(1)

    print("[END VIEW CREATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)