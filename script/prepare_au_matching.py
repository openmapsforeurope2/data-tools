import os
import sys
import getopt
from datetime import datetime
import utils
import prepare_data_


def run(argv):

    arg_conf = ""
    arg_borders = []
    arg_suffix = ""
    arg_verbose = False
    arg_level = None
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:b:s:l:v", [
            "conf=",
            "border=",
            "suffix=",
            "level="
            "verbose"
        ])
    except getopt.GetoptError as err:
        print(err)
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-b", "--border"):
            arg_borders.append(arg)
        elif opt in ("-s", "--suffix"):
            arg_suffix = arg
        elif opt in ("-l", "--level"):
            arg_level = arg
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    if len(args) != 1 :
        print("un et un seul code pays doit être renseigné en argument")
        sys.exit(1)
        
    print('conf:', arg_conf)
    print('borders:', arg_borders)
    print('suffix:', arg_suffix)
    print('level:', arg_level)
    print('country code:', args)
    print('verbose:', arg_verbose)

    #country
    if len(args) != 1:
        print("One and only one country must be specified in arguments")
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

    #merge confs
    conf.update(db_conf)


    print("[START PREPARE AU MATCHING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        # theme
        theme = conf['data']["themes"]["au"]["schema"]
        
        # tables
        tables = set([])
        for country in args:
            if country not in conf['data']['operation']['au_matching']["lowest_level"]:
                raise "lowest_level not defined in conf file for country '"+country+"'"
            
            levels = [arg_level] if arg_level is not None else list(range(1, conf['data']['operation']['au_matching']["lowest_level"][country] + 1))

            for level in levels:
                tables.add(conf['data']['operation']['au_matching']["table_name_prefix"]+str(level))
        tables = list(tables)
    
        # prepare
        prepare_data_.run(
            conf,
            mcd,
            theme,
            tables,
            arg_suffix,
            args,
            arg_borders,
            "au_matching",
            arg_verbose
        )

    except Exception as e:
        print(e)
        sys.exit(1)

    print("[END PREPARE AU MATCHING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)