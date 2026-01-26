import os
import sys
import getopt
from datetime import datetime
import utils
import integrate_


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
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('suffix:', arg_suffix)
    print('country codes:', args)
    print('verbose:', arg_verbose)

    #country
    if len(args) != 2:
        print("Two and only two country must be specified in arguments")
        sys.exit(1)

    #conf
    if not os.path.isfile(arg_conf):
        print("The configuration file "+ arg_conf + " does not exist.")
        sys.exit(1)

    conf = utils.getConf(arg_conf)

    #bd conf
    db_conf = {}
    if not os.path.isfile(conf["db_conf_file"]):
        print("The configuration file "+ conf["db_conf_file"] + " does not exist, loading DB conf from environment variables...")
        db_conf = utils.getDbConfFromEnv()
    else:
        db_conf = utils.getConf(conf["db_conf_file"])

    #merge confs
    conf.update(db_conf)

    print("[START INTEGRATE AREA MATCHING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        integrate_.integrate_operation(
            conf,
            arg_theme,
            arg_tables,
            args,
            "area_matching",
            arg_suffix,
            False,
            False,
            arg_verbose
        )

    except Exception as e:
        print(e)
        sys.exit(1)

    print("[END INTEGRATE AREA MATCHING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)