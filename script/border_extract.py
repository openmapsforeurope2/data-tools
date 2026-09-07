import os
import sys
import getopt
from datetime import datetime
import utils
import border_extract_

def run(argv):

    boundary_types = ["international","maritime","land_maritime","coastline","inland_water"]

    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    arg_db_name = None
    arg_radius = None
    arg_bcc = None
    arg_bt = None
    arg_suffix = ""
    arg_from_up = False
    arg_noreset = False
    arg_verbose = False
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:T:t:d:r:b:B:s:aunv", [
            "conf=", 
            "theme=", 
            "table=",
            "dbname=",
            "radius=", 
            "border_country=", 
            "boundary_type=",
            "suffix="
            "in_up_area",
            "from_up",
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
        elif opt in ("-r", "--radius"):
            arg_radius = arg
        elif opt in ("-b", "--border_country"):
            arg_bcc = arg
            if arg_bcc == "false":
                arg_bcc = False
        elif opt in ("-B", "--boundary_type"):
            arg_bt = arg
        elif opt in ("-s", "--suffix"):
            arg_suffix = arg
        elif opt in ("-u", "--from_up"):
            arg_from_up = True
        elif opt in ("-n", "--noreset"):
            arg_noreset = True
        elif opt in ("-v", "--verbose"):
            arg_verbose = True
        
    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('db name:', arg_db_name)
    print('radius:', arg_radius)
    print('border country:', arg_bcc)
    print('boundary type:', arg_bt)
    print('suffix:', arg_suffix)
    print('from_up:', arg_from_up)
    print('codes:', args)
    print('reset:', (not arg_noreset))
    print('verbose:', arg_verbose)

    if arg_bt is not None and arg_bt not in boundary_types:
        print("The B (boundary_type) parameter must be chosen among the following values: " + ",".join(boundary_types))
        sys.exit(1)

    if arg_radius is None:
        print("Mandatory parameter --radius (-r) is missing")
        sys.exit(1)

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

        border_extract_.run(
            conf,
            mcd,
            arg_theme,
            arg_tables,
            arg_radius,
            args,
            arg_bcc,
            arg_bt,
            "_"+arg_suffix,
            arg_from_up,
            (not arg_noreset),
            arg_verbose
        )

    except Exception as e:
        print(e)
        sys.exit(1)

    print("[END EXTRACTION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)