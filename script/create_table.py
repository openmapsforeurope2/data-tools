import os
import sys
import getopt
from datetime import datetime
import utils
import create_table_


def run(argv):

    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    arg_db_name = None
    args = ""
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:T:t:d:", [
        "conf=", "theme=", "table=", "dbname="])
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

    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)

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


    print("[START TABLE CREATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        create_table_.createTableAndIndexes(conf, mcd, arg_theme, arg_tables)
    except:
        sys.exit(1)

    print("[END TABLE CREATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)