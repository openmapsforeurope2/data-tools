import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import clean_


def run(argv):

    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    arg_borders = []
    arg_in_dispute = False
    arg_all = False
    arg_verbose = False
    args = ""
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:T:t:b:iav", [
        "conf=", "theme=", "table=", "border=", "in_dispute", "all", "verbose"])
    except:
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-T", "--theme"):
            arg_theme = arg
        elif opt in ("-t", "--table"):
            arg_tables.append(arg)
        elif opt in ("-b", "--border"):
            arg_borders.append(arg)
        elif opt in ("-i", "--in_dispute"):
            arg_in_dispute = True
        elif opt in ("-a", "--all"):
            arg_all = True
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    if arg_all and arg_borders:
        print("les paramètres -a et -b ne peuvent pas être utilisés simultanément")
        sys.exit(1)

    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('borders:', arg_borders)
    print('in dispute:', arg_in_dispute)
    print('all:', arg_all)
    print('verbose:', arg_verbose)
    print('country codes:', args)

    #conf
    if not os.path.isfile(arg_conf):
        print("The configuration file "+ arg_conf + " does not exist.")
        sys.exit(1)

    conf = utils.getConf(arg_conf)

    #bd conf
    if not os.path.isfile(conf["db_conf_file"]):
        print("The db configuration file "+ conf["db_conf_file"] + " does not exist.")
        sys.exit(1)

    db_conf = utils.getConf(conf["db_conf_file"])

    #merge confs
    conf.update(db_conf)

    print("[START CLEANING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        clean_.run(conf, arg_theme, arg_tables, args, arg_borders, arg_in_dispute, arg_all, arg_verbose)
    except:
        sys.exit(1)
    
    print("[END CLEANING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)
