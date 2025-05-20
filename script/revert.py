import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import revert_


def run(argv):

    currentDir = os.path.dirname(os.path.abspath(__file__))

    arg_conf = ""
    arg_step = ""
    arg_theme = ""
    arg_tables = []
    arg_verbose = False
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:s:T:t:v", [
        "conf=", "step=", "theme=", "table=", "verbose"])
    except:
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-s", "--step"):
            arg_step = arg
        elif opt in ("-T", "--theme"):
            arg_theme = arg
        elif opt in ("-t", "--table"):
            arg_tables.append(arg)
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    print('step:', arg_step)
    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('verbose:', arg_verbose)
    
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


    print("[START REVERSION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        revert.run(arg_step, conf, arg_theme, arg_tables, arg_verbose)
    except:
        sys.exit(1)
    
    print("[END REVERSION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)