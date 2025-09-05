import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import create_view_


def run(argv):

    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    args = ""
    
    try:
        opts, args = getopt.getopt(argv[1:], "hc:T:t:", ["help",
        "conf=", "theme=", "table="])
    except getopt.GetoptError as err:
        print(err)
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

    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)

    #conf
    if not os.path.isfile(workspace+"conf/"+arg_conf):
        print("The configuration file "+ arg_conf + " does not exist.")
        sys.exit(1)
    arg_conf = workspace+"conf/"+arg_conf

    conf = utils.getConf(arg_conf)

    #mcd
    if not os.path.isfile(conf["mcd_conf_file"]):
        print("The mcd configuration file "+ conf["mcd_conf_file"] + " does not exist.")
        sys.exit(1)

    mcd = utils.getConf(conf["mcd_conf_file"])

    #bd conf
    if not os.path.isfile(conf["db_conf_file"]):
        print("The db configuration file "+ conf["db_conf_file"] + " does not exist.")
        sys.exit(1)

    db_conf = utils.getConf(conf["db_conf_file"])

    #merge confs
    conf.update(db_conf)


    print("[START VIEW CREATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        create_view_.createViews(conf, mcd, arg_theme, arg_tables)
    except:
        sys.exit(1)

    print("[END VIEW CREATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)