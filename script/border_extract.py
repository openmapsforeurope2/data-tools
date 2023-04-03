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
        where_statement_boundary += (" AND " if where_statement_boundary else "") +conf['data']['common_fields']['country']+" LIKE '%"+country+"%'"
        where_statement_data += ("," if where_statement_data else "") + "'"+country+"'"
    where_statement_data = conf['data']['common_fields']['country']+" IN ("+where_statement_data+")"

    boundary_statement =  "ST_Union(ARRAY((SELECT "+conf['boundary']['fields']['geometry']+" FROM "+getTableName(conf['boundary']['schema'], conf['boundary']['table'])+" WHERE "+where_statement_boundary+")))"
    
    
    theme_schema = conf['data']['themes'][theme]['schema']
    working_schema = conf['data']['themes'][theme]['w_schema']
    if not tables:
        tables = conf['data']['themes'][theme]['tables']
        
    for tb in tables:
        tableName = getTableName(theme_schema, tb)
        wTableName = getTableName(working_schema, tb)+conf['data']['working']['suffix']
        wIdsTableName = getTableName(working_schema, tb)+conf['data']['working']['ids_suffix']

        # on recupère tous les noms de champs de la table
        q = "SELECT string_agg(column_name,',') FROM information_schema.columns WHERE table_name = '"+tb+"' "+ ("AND table_schema = '"+theme_schema+"'") if theme_schema else ""
        print(u'query: {}'.format(q), flush=True)
        cursor.execute(q)
        fields = cursor.fetchone()[0]

        query = "DELETE FROM "+workingTableName+";"
        query += "INSERT INTO "+workingTableName+" ("+fields+") SELECT "+fields+" FROM "+tableName
        query += " WHERE "+where_statement_data
        query += " AND ST_intersects("+conf['data']['common_fields']['geometry']+",(SELECT ST_Buffer("+boundary_statement+","+ str(distance)+")))"
        if 'where' in conf['border_extraction'] and conf['border_extraction']['where']:
            query += " AND "+conf['border_extraction']['where']

        print(u'query: {}'.format(query), flush=True)
        cursor.execute(query)
        conn.commit()

        # on enregistre tous les identifiants des objects extraits
        q2 = "DELETE FROM "+wIdsTableName+";"
        q2 += "INSERT INTO "+wIdsTableName+" ("+conf['data']['common_fields']['id']+") SELECT "+conf['data']['common_fields']['id']+" FROM "+wTableName
        print(u'query: {}'.format(q2), flush=True)
        cursor.execute(q2)
        conn.commit()

    cursor.close()
    conn.close()