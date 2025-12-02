import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import prepare_data_


def run(argv):

    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    arg_suffix = ""
    arg_verbose = False
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:T:t:s:v", [
            "conf=",
            "theme=",
            "table=",
            "suffix=",
            "verbose"
        ])
    except getopt.GetoptError as err:
        print(err)
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
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    if len(args) != 2 :
        print("deux et seulement deux codes pays doivent être renseignés en arguments")
        sys.exit(1)
        
    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('suffix:', arg_suffix)
    print('country codes:', args)
    print('verbose:', arg_verbose)

    #conf
    if not os.path.isfile(arg_conf):
        print("The configuration file "+ arg_conf + " does not exist.")
        sys.exit(1)

    conf = utils.getConf(arg_conf)

    #mcd
    if not os.path.isfile(conf["mcd_conf_file"]):
        print("The mcd configuration file "+ conf["mcd_conf_file"] + " does not exist.")
        sys.exit(1)

    mcd = utils.getConf(conf["mcd_conf_file"])

    #bd conf
    db_conf = {}
    if not os.path.isfile(conf["db_conf_file"]):
        print("The configuration file "+ conf["db_conf_file"] + " does not exist, loading DB conf from environment variables...")
        db_conf = utils.getDbConfFromEnv()
    else:
        db_conf = utils.getConf(conf["db_conf_file"])

    #merge confs
    conf.update(db_conf)


    print("[START PREPARE NET MATCHING VALIDATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        prepare_data_.run(
            conf,
            mcd,
            arg_theme,
            arg_tables,
            arg_suffix,
            args,
            None,
            "net_matching_validation",
            arg_verbose
        )

    except Exception as e:
        print(e)
        sys.exit(1)

    print("[END PREPARE NET MATCHING VALIDATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)