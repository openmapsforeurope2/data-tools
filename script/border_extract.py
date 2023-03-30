import psycopg2


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName

def run(
    conf, theme, tables, distance, countryCodes, verbose
):
    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])
    cursor = conn.cursor()

    print("EXTRACTING...", flush=True)

    where_statement_boundary = ""
    where_statement_data = ""
    for country in  countryCodes:
        where_statement_boundary += (" AND " if where_statement_boundary else "") +conf['data']['country_field']+" LIKE '%"+country+"%'"
        where_statement_data += ("," if where_statement_data else "") + "'"+country+"'"
    where_statement_data = conf['data']['country_field']+" IN ("+where_statement_data+")"

    boundary_statement =  "ST_Union(ARRAY((SELECT "+conf['boundary']['geometry_field']+" FROM "+getTableName(conf['boundary']['schema'], conf['boundary']['table'])+" WHERE "+where_statement_boundary+")))"
    
    theme_schema = conf['data']['themes'][theme]['schema']
    working_schema = conf['data']['themes'][theme]['w_schema']
    if not tables:
        tables = conf['data']['themes'][theme]['tables']
        
    for tb in tables:
        # on recupère tous les noms de champs de la table
        q = "SELECT string_agg(column_name,',') FROM information_schema.columns WHERE table_name = '"+tb+"' "+ ("AND table_schema = '"+theme_schema+"'") if theme_schema else ""
        print(u'query: {}'.format(q), flush=True)
        cursor.execute(q)
        fields = cursor.fetchone()[0]

        query = "DELETE FROM "+getTableName(working_schema, tb)+"_w;"
        query += "INSERT INTO "+getTableName(working_schema, tb)+"_w ("+fields+") SELECT "+fields+" FROM "+getTableName(theme_schema, tb)
        query += " WHERE "+where_statement_data
        query += " AND ST_intersects("+conf['data']['geometry_field']+",(SELECT ST_Buffer("+boundary_statement+","+ str(distance)+")))"
        if conf['border_extraction']['where']:
            query += " AND "+conf['border_extraction']['where']

        print(u'query: {}'.format(query), flush=True)
        cursor.execute(query)
        conn.commit()

        # on enregistre tous les identifiants des objects extraits
        q2 = "DELETE FROM "+getTableName(working_schema, tb)+"_w_ids; INSERT INTO "+getTableName(working_schema, tb)+"_w_ids ("+conf['data']['id_field']+") SELECT "+conf['data']['id_field']+" FROM "+getTableName(working_schema, tb)+"_w"
        print(u'query: {}'.format(q2), flush=True)
        cursor.execute(q2)
        conn.commit()

    cursor.close()
    conn.close()