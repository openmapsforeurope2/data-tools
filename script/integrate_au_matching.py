import os
import sys
import getopt
from datetime import datetime
import utils
import integrate_


def run(argv):

    arg_conf = ""
    arg_suffix = ""
    arg_level = None
    arg_verbose = False
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:s:v", [
            "conf=",
            "suffix=",
            "verbose"
        ])
    except:
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-s", "--suffix"):
            arg_suffix = arg
        elif opt in ("-l", "--level"):
            arg_level = arg
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    print('conf:', arg_conf)
    print('suffix:', arg_suffix)
    print('country codes:', args)
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

    #bd conf
    db_conf = {}
    if not os.path.isfile(conf["db_conf_file"]):
        print("The configuration file "+ conf["db_conf_file"] + " does not exist, loading DB conf from environment variables...")
        db_conf = utils.getDbConfFromEnv()
    else:
        db_conf = utils.getConf(conf["db_conf_file"])

    #merge confs
    conf.update(db_conf)

    print("[START INTEGRATE AU MATCHING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        arg_suffix = "_" + "_".join(sorted(args)) + "_" + arg_suffix

        lowest_level = str(conf['data']['operation']['au_matching']['lowest_level'][args[0]])
        arg_level = lowest_level if arg_level is None else arg_level
        table = [ conf['data']['operation']['au_matching']['table_name_prefix'] + arg_level ]

        # a revoir si besoin de faire du matching sur un niveau autre que lowest_level
        operation = "au_matching" if arg_level == lowest_level else "au_merging"

        integrate_.integrate_operation(
            conf,
            'au',
            table,
            args,
            operation,
            arg_suffix,
            False,
            False,
            arg_verbose
        )

    except Exception as e:
        print(e)
        sys.exit(1)

    print("[END INTEGRATE AU MATCHING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)