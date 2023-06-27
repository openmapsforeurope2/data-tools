import psycopg2


def copyTable(conf, tables):
    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])
    cursor = conn.cursor()

    print("COPYING TABLES...", flush=True)
    
    for tableName in tables:

        targetTableName = tableName.replace(".", "_")

        if targetTableName == tableName :
            print(u'Nothing to do, the table '+tableName+' is already in the schema "public"', flush=True)
            continue

        query = "DROP TABLE IF EXISTS "+targetTableName+"; CREATE TABLE "+targetTableName+" AS TABLE "+tableName+";"

        print(u'query: {}'.format(query), flush=True)
        cursor.execute(query)
        conn.commit()