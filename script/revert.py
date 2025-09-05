import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import revert_


def run(argv):

    arg_conf = ""
    arg_step = ""
    arg_theme = ""
    arg_tables = []
    arg_verbose = False
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:s:T:t:v", [
        "conf=", "step=", "theme=", "table=", "verbose"])
    except getopt.GetoptError as err:
        print(err)
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-s", "--step"):
            arg_step = arg
        elif opt in ("-T", "--theme"):
            arg_theme = arg
        elif opt in ("-t", "--table"):
            arg_tables.append(arg)
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    print('step:', arg_step)
    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('verbose:', arg_verbose)
    
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
        revert.run(arg_step, conf, arg_theme, arg_tables, arg_verbose)
    except:
        sys.exit(1)
    
    print("[END REVERSION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)