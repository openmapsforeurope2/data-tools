import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import border_extract

def run(argv):

    currentDir = os.path.dirname(os.path.abspath(__file__))

    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    arg_dist = None
    arg_bcc = None
    arg_noreset = False
    arg_verbose = False
    arg_help = "{0} -c <conf> -o <output> -v".format(argv[0])
    
    try:
        opts, args = getopt.getopt(argv[1:], "hc:T:t:d:b:nv", ["help",
        "conf=", "theme=", "table=", "distance=", "border_country=", "noreset", "verbose"])
    except:
        print(arg_help)
        sys.exit(2)
    
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(arg_help)  # print the help message
            sys.exit(2)
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
        elif opt in ("-n", "--noreset"):
            arg_noreset = True
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('distance:', arg_dist)
    print('border country:', arg_bcc)
    print('reset:', (not arg_noreset))
    print('verbose:', arg_verbose)

    if arg_dist is None:
        print("le paramètre obligatoire --distance (-d) est manquant")
        sys.exit(2)

    workspace = os.path.dirname(currentDir)+"/"

    if not os.path.isfile(workspace+"conf/"+arg_conf):
        print("le fichier de configuration "+ arg_conf + " n'existe pas.")
        sys.exit(2)
    arg_conf = workspace+"conf/"+arg_conf


    print("[START EXTRACTION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    conf = utils.getConf(arg_conf)

    border_extract.run(conf, arg_theme, arg_tables, arg_dist, args, arg_bcc, (not arg_noreset), arg_verbose)

    print("[END EXTRACTION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

if __name__ == "__main__":
    run(sys.argv)