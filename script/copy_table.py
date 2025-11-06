import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import copy_table_


def run(argv):
    
    arg_conf = ""
    args = ""
    arg_with_history = True
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:n", ["conf="])
    except getopt.GetoptError as err:
        print(err)
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-c", "--conf"):
            arg_conf = arg
        if opt in ("-n", "--nohistory"):
            arg_with_history = False

    print('conf:', arg_conf)
    print('with history:', str(args))
    print('tables:', args)

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


    print("[START TABLE COPY] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        copy_table_.run(conf, args, arg_with_history)
    except:
        sys.exit(1)

    print("[END TABLE COPY] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)