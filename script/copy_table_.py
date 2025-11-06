import psycopg2


def run(conf, tables, withHistory):
    """
    Fonction utilitaire pour la copy de table.

    Paramètres:
    conf (objet) : configuration
    tables (array) : tables à copier
    """

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

        query = "DROP TABLE IF EXISTS "+targetTableName+"; CREATE TABLE "+targetTableName+" AS SELECT * FROM "+tableName
        if withHistory:
            query += " WHERE NOT gcms_detruit"
        query += ";"

        print(u'query: {}'.format(query), flush=True)
        try:
            cursor.execute(query)
        except psycopg2.Error as e:
            print(e)
            raise
        conn.commit()
    
    cursor.close()
    conn.close()