import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import revert_
import revert_historized

def run(argv):

    arg_conf = ""
    arg_numrec = ""
    arg_theme = ""
    arg_tables = []
    arg_historize = "true"
    arg_only = "false"
    arg_verbose = False
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:n:T:t:h:o:v", [
        "conf=", "numrec=", "theme=", "table=", "historize=", "only=", "verbose"])
    except getopt.GetoptError as err:
        print(err)
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-n", "--numrec"):
            arg_numrec = arg
        elif opt in ("-T", "--theme"):
            arg_theme = arg
        elif opt in ("-t", "--table"):
            arg_tables.append(arg)
        elif opt in ("-h", "--historize"):
            arg_historize = arg
        elif opt in ("-o", "--only"):
            arg_only = arg
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    print('numrec:', arg_numrec)
    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('historize:', arg_historize)
    print('only:', arg_only)
    print('verbose:', arg_verbose)

    #check parameters
    if arg_historize not in ["true", "false"] :
        print("historize (-h) parameter value should be 'true' or 'false'")
        sys.exit(1)

    if arg_only not in ["true", "false"] :
        print("only (-o) parameter value should be 'true' or 'false'")
        sys.exit(1)
    
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


    print("[START REVERSION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        if arg_historize == "false" :
            revert_.run(arg_numrec, conf, arg_theme, arg_tables, arg_only=="true", arg_verbose)
        else :
            revert_historized.run(arg_numrec, conf, arg_theme, arg_tables, arg_only=="true", arg_verbose)
        
    except Exception as e:
        print(e)
        sys.exit(1)
    
    print("[END REVERSION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)