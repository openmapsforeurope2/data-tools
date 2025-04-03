import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import border_extract_


def run(argv):

    currentDir = os.path.dirname(os.path.abspath(__file__))

    boundary_types = ["international","maritime","land_maritime","coastline","inland_water"]

    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    arg_dist = None
    arg_bcc = None
    arg_bt = None
    arg_from_up = False
    arg_noreset = False
    arg_verbose = False
    arg_help = "{0} -c <conf> -o <output> -v".format(argv[0])
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:T:t:o:d:b:B:auAnvh", [
            "conf=", 
            "theme=", 
            "table=", 
            "output=", 
            "distance=", 
            "border_country=", 
            "boundary_type=", 
            "in_up_area",
            "from_up",
            "noreset", 
            "verbose",
            "help"
        ])
    except:
        print(arg_help)
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(arg_help)  # print the help message
            sys.exit(1)
        elif opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-T", "--theme"):
            arg_theme = arg
        elif opt in ("-t", "--table"):
            arg_tables.append(arg)
        elif opt in ("-d", "--distance"):
            arg_dist = arg
        elif opt in ("-b", "--border_country"):
            arg_bcc = arg
            if arg_bcc == "false":
                arg_bcc = False
        elif opt in ("-B", "--boundary_type"):
            arg_bt = arg
        elif opt in ("-u", "--from_up"):
            arg_from_up = True
        elif opt in ("-A", "--all_objects"):
            arg_all_objects = True
        elif opt in ("-n", "--noreset"):
            arg_noreset = True
        elif opt in ("-v", "--verbose"):
            arg_verbose = True
        
    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('distance:', arg_dist)
    print('border country:', arg_bcc)
    print('boundary type:', arg_bt)
    print('from_up:', arg_from_up)
    print('reset:', (not arg_noreset))
    print('verbose:', arg_verbose)

    if arg_bt is not None and arg_bt not in boundary_types:
        print("The B (boundary_type) parameter must be chosen among the following values: " + ",".join(boundary_types))
        sys.exit(1)

    if arg_dist is None:
        print("Mandatory parameter --distance (-d) is missing")
        sys.exit(1)
        
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

    print("[START EXTRACTION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        border_extract_.run(
            conf,
            arg_theme,
            arg_tables,
<<<<<<< HEAD
=======
            #arg_output,
>>>>>>> ca4ff754c7999b86608445d5c3064be975750b29
            arg_dist,
            args,
            arg_bcc,
            arg_bt,
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