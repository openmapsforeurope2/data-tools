import os
import sys
import getopt
from datetime import datetime
import shutil
import utils
import integrate_


def run(argv):

    arg_conf = ""
    arg_suffix = ""
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
        elif opt in ("-v", "--verbose"):
            arg_verbose = True

    print('conf:', arg_conf)
    print('suffix:', arg_suffix)
    print('country codes:', args)
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

    print("[START INTEGRATE AU MATCHING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        integrate_.integrate_operation(
            conf,
            None,
            None,
            args,
            "au_matching",
            arg_suffix,
            arg_verbose
        )

    except Exception as e:
        print(e)
        sys.exit(1)

    print("[END INTEGRATE AU MATCHING] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)