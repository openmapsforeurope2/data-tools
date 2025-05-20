import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import prepare_data_


def run(argv):

    currentDir = os.path.dirname(os.path.abspath(__file__))

    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    arg_suffix = ""
    arg_verbose = False
    arg_operation = ""
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:T:t:s:mv", [
            "conf=",
            "theme=",
            "table=",
            "suffix=",
            "matching",
            "verbose"
        ])
    except:
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-T", "--theme"):
            arg_theme = arg
        elif opt in ("-t", "--table"):
            arg_tables.append(arg)
        elif opt in ("-s", "--suffix"):
            arg_suffix = arg
        elif opt in ("-m", "--matching"):
                arg_operation = "matching" if arg_operation == "" else None
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    #operation
    if not arg_operation :
        print("One and only one operation must be chosen from among : matching (-m)")
        sys.exit(1)
        
    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('suffix:', arg_suffix)
    print('country codes:', args)
    print('operation:', arg_operation)
    print('verbose:', arg_verbose)

    workspace = os.path.dirname(currentDir)+"/"

    #conf
    if not os.path.isfile(workspace+"conf/"+arg_conf):
        print("The configuration file "+ arg_conf + " does not exist.")
        sys.exit(1)
    arg_conf = workspace+"conf/"+arg_conf

    conf = utils.getConf(arg_conf)

    #mcd
    print(workspace+"conf/"+conf["mcd_conf_file"])
    if not os.path.isfile(workspace+"conf/"+conf["mcd_conf_file"]):
        print("The configuration file "+ conf["mcd_conf_file"] + " does not exist.")
        sys.exit(1)
    arg_mcd_conf = workspace+"conf/"+conf["mcd_conf_file"]

    mcd = utils.getConf(arg_mcd_conf)

    #bd conf
    print(workspace+"conf/"+conf["db_conf_file"])
    if not os.path.isfile(workspace+"conf/"+conf["db_conf_file"]):
        print("The configuration file "+ conf["db_conf_file"] + " does not exist.")
        sys.exit(1)
    arg_db_conf = workspace+"conf/"+conf["db_conf_file"]

    db_conf = utils.getConf(arg_db_conf)

    #merge confs
    conf.update(db_conf)

    print("[START PREPARE DATA] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        prepare_data_.run(
            conf,
            mcd,
            arg_theme,
            arg_tables,
            arg_suffix,
            args,
            arg_operation,
            arg_verbose
        )

    except Exception as e:
        print(e)
        sys.exit(1)

    print("[END PREPARE DATA] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)