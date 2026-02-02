import os
import sys
import getopt
from datetime import datetime
import utils
import psycopg2


def run(argv):

    arg_conf = None
    arg_sql_file = ""
    arg_db_host = None
    arg_db_port = None
    arg_db_name = None
    arg_db_user = None
    arg_db_password = None
    
    try:
        opts, args = getopt.getopt(argv[1:], "c:f:h:p:d:U:x:", [
            "conf=",
            "file=",
            "host=",
            "port=",
            "dbname=",
            "user=",
            "password=",
        ])
    except:
        sys.exit(1)
    
    for opt, arg in opts:
        if opt in ("-c", "--conf"):
            arg_conf = arg
        elif opt in ("-f", "--file"):
            arg_sql_file = arg
        elif opt in ("-h", "--host"):
            arg_db_host = arg
        elif opt in ("-p", "--port"):
            arg_db_port = arg
        elif opt in ("-d", "--dbname"):
            arg_db_name = arg
        elif opt in ("-U", "--user"):
            arg_db_user = arg
        elif opt in ("-x", "--password"):
            arg_db_password = arg

    #sql param
    if arg_sql_file is None:
        print("Missing mandatory parameter -f / --file")
        sys.exit(1)

    if not os.path.isfile(arg_sql_file):
        print("The sql file "+ arg_sql_file + " does not exist.")
        sys.exit(1)

    #conf initialization
    conf = {"db":{}}
    if arg_conf is not None:
        conf = utils.getConf(arg_conf)
    #--
    if arg_db_host is None:
        if "host" in conf["db"] and conf["db"]["host"]:
            arg_db_host = conf["db"]["host"]
        else:
            arg_db_host = os.environ["PGHOST"]
    #--
    if arg_db_port is None:
        if "port" in conf["db"] and conf["db"]["port"]:
            arg_db_port = conf["db"]["port"]
        else:
            arg_db_port = os.environ["PGPORT"]
    #--
    if arg_db_name is None:
        if "name" in conf["db"] and conf["db"]["name"]:
            arg_db_name = conf["db"]["name"]
        else:
            arg_db_name = os.environ["PGDATABASE2CREATE"]
    #--
    if arg_db_user is None:
        if "user" in conf["db"] and conf["db"]["user"]:
            arg_db_user = conf["db"]["user"]
        else:
            arg_db_user = os.environ["PGUSER"]
    #--
    if arg_db_password is None:
        if "pwd" in conf["db"] and conf["db"]["pwd"]:
            arg_db_password = conf["db"]["pwd"]
        else:
            arg_db_password = os.environ["PGPASSWORD"]

    print('conf file:', arg_conf)
    print('sql file:', arg_sql_file)
    print('host:', arg_db_host)
    print('port:', arg_db_port)
    print('db name:', arg_db_name)
    print('user:', arg_db_user)

    print("[START SQL RUN] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

    try:
        conn = psycopg2.connect( 
            user = arg_db_user,
            password = arg_db_password,
            host = arg_db_host,
            port = arg_db_port,
            database = arg_db_name)

        with conn:
            with conn.cursor() as cur:
                with open(arg_sql_file, "r", encoding="utf-8") as f:
                    sql = f.read()
                    cur.execute(sql)

        conn.close()

    except Exception as e:
        print(e)
        sys.exit(1)

    print("[END SQL RUN] "+datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


if __name__ == "__main__":
    run(sys.argv)