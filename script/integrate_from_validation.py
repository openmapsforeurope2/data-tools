import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import integrate_from_validation_


def run(argv):

    currentDir = os.path.dirname(os.path.abspath(__file__))

    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    arg_verbose = False
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:T:t:v", [
            "conf=",
            "theme=",
            "table=",
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
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('country codes:', args)
    print('verbose:', arg_verbose)

    workspace = os.path.dirname(currentDir)+"/"

    #conf
    if not os.path.isfile(workspace+"conf/"+arg_conf):
        print("The configuration file "+ arg_conf + " does not exist.")
        sys.exit(1)
    arg_conf = workspace+"conf/"+arg_conf

    conf = utils.getConf(arg_conf)

    #bd conf
    print(workspace+"conf/"+conf["db_conf_file"])
    if not os.path.isfile(workspace+"conf/"+conf["db_conf_file"]):
        print("The configuration file "+ conf["db_conf_file"] + " does not exist.")
        sys.exit(1)
    arg_db_conf = workspace+"conf/"+conf["db_conf_file"]

    db_conf = utils.getConf(arg_db_conf)

    #merge confs
    conf.update(db_conf)

    print("[START INTEGRATION FROM VALIDATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        integrate_from_validation_.run(
            conf,
            arg_theme,
            arg_tables,
            args,
            arg_verbose
        )

    except Exception as e:
        print(e)
        sys.exit(1)

    print("[END INTEGRATION FROM VALIDATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)