import os
import sys
import getopt
from datetime import datetime
import utils
import extract_

def run(argv):

    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    arg_db_name = None
    arg_suffix = ""
    arg_xmin = None
    arg_xmax = None
    arg_ymin = None
    arg_ymax = None
    arg_noreset = False
    arg_verbose = False
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:T:t:d:s:x:X:y:Y:nv", [
            "conf=", 
            "theme=", 
            "table=",
            "dbname=",
            "suffix="
            "xmin=",
            "xmax=",
            "ymin=",
            "ymax=,"
            "noreset", 
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
        elif opt in ("-d", "--dbname"):
            arg_db_name = arg
        elif opt in ("-s", "--suffix"):
            arg_suffix = arg
        elif opt in ("-x", "--xmin"):
            arg_xmin = arg
        elif opt in ("-X", "--xmax"):
            arg_xmax = arg
        elif opt in ("-y", "--ymin"):
            arg_ymin = arg
        elif opt in ("-Y", "--ymax"):
            arg_ymax = arg
        elif opt in ("-n", "--noreset"):
            arg_noreset = True
        elif opt in ("-v", "--verbose"):
            arg_verbose = True
        
    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('suffix:', arg_suffix)
    print('xmin:', arg_xmin)
    print('xmax:', arg_xmax)
    print('ymin:', arg_ymin)
    print('ymax:', arg_ymax)
    print('codes:', args)
    print('reset:', (not arg_noreset))
    print('verbose:', arg_verbose)

    if arg_xmin is not None or arg_xmax is not None or arg_ymin is not None or arg_ymax is not None:
        if arg_xmin is None or arg_xmax is None or arg_ymin is None or arg_ymax is None:
            print("missing bouding box coordinate(s)")
            sys.exit(1)

    if arg_xmin is not None and arg_xmax is not None:
        if arg_xmin >= arg_xmax:
            print("xmin is not strictly less than xmax")

    if arg_ymin is not None and arg_ymax is not None:
            if arg_ymin >= arg_ymax:
                print("ymin is not strictly less than ymax")

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

    if arg_db_name is not None:
        db_conf["db"]["name"] = arg_db_name

    #merge confs
    conf.update(db_conf)

    print("[START EXTRACTION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        
        extract_.run(
            conf,
            mcd,
            arg_theme,
            arg_tables,
            args,
            "_"+arg_suffix,
            arg_xmin,
            arg_xmax,
            arg_ymin,
            arg_ymax,
            (not arg_noreset),
            arg_verbose
        )

    except Exception as e:
        print(e)
        sys.exit(1)

    print("[END EXTRACTION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)