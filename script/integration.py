import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import integrate

def run(argv):

    currentDir = os.path.dirname(os.path.abspath(__file__))

    arg_conf = ""
    arg_step = ""
    arg_theme = ""
    arg_tables = []
    arg_nohistory = False # life-cycle management is enabled as default
    arg_verbose = False
    arg_help = "{0} -c <conf> -o <output> -v".format(argv[0])
    args = ""
    
    try:
        opts, args = getopt.getopt(argv[1:], "hc:s:T:t:v", ["help",
        "conf=", "step=", "theme=", "table=", "no_history", "verbose"])
    except:
        print(arg_help)
        sys.exit(2)
    
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(arg_help)  # print the help message
            sys.exit(2)
        elif opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-s", "--step"):
            arg_step = arg
        elif opt in ("-T", "--theme"):
            arg_theme = arg
        elif opt in ("-t", "--table"):
            arg_tables.append(arg)
        elif opt in ("-n", "--no_history"):
            arg_nohistory = True
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    print('step:', arg_step)
    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('no_history:', arg_nohistory)
    print('verbose:', arg_verbose)

    workspace = os.path.dirname(currentDir)+"/"

    if not os.path.isfile(workspace+"conf/"+arg_conf):
        print("le fichier de configuration "+ arg_conf + " n'existe pas.")
        sys.exit(2)
    arg_conf = workspace+"conf/"+arg_conf


    print("[START INTEGRATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    conf = utils.getConf(arg_conf)

    integrate.run(arg_step, conf, arg_theme, arg_tables, arg_nohistory, arg_verbose)

    print("[END INTEGRATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

if __name__ == "__main__":
    run(sys.argv)