import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import copy_table_


def run(argv):

    currentDir = os.path.dirname(os.path.abspath(__file__))

    arg_conf = ""
    arg_help = "{0} -c <conf> -o <output> -v".format(argv[0])
    args = ""
    
    try:
        opts, args = getopt.getopt(argv[1:], "hc:", ["help", "conf="])
    except:
        print(arg_help)
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(arg_help)  # print the help message
            sys.exit(1)
        elif opt in ("-c", "--conf"):
            arg_conf = arg

    print('conf:', arg_conf)
    print('tables:', args)

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


    print("[START TABLE COPY] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        copy_table_.run(conf, args)
    except:
        sys.exit(1)

    print("[END TABLE COPY] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)