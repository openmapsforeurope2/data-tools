import os
import sys
import getopt
from datetime import datetime
import utils
import integrate_


def run(argv):
    arg_conf = ""
    arg_theme = ""
    arg_tables = []
    arg_db_name = None
    arg_verbose = False
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:T:t:d:v", [
            "conf=",
            "theme=",
            "table=",
            "dbname=",
            "verbose"
        ])
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
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    print('conf:', arg_conf)
    print('theme:', arg_theme)
    print('tables:', arg_tables)
    print('db name:', arg_db_name)
    print('country codes:', args)
    print('verbose:', arg_verbose)

    #country
    if len(args) != 2:
        print("Two and only two country must be specified in arguments")
        sys.exit(1)

    #conf
    if not os.path.isfile(arg_conf):
        print("The configuration file "+ arg_conf + " does not exist.")
        sys.exit(1)

    conf = utils.getConf(arg_conf)

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

    print("[START INTEGRATE NET MATCHING VALIDATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        if not arg_tables:
            tables = conf['data']['operation']['net_matching']['themes'][arg_theme]['tables']

            arg_tables = [
                name
                for name, prop in tables.items()
                if 'validation' in prop and prop['validation']
            ]

        integrate_.integrate_operation(
            conf,
            arg_theme,
            arg_tables,
            args,
            "net_matching_validation",
            None,
            False,
            False,
            arg_verbose
        )

    except Exception as e:
        print(e)
        sys.exit(1)

    print("[END INTEGRATE NET MATCHING VALIDATION] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)