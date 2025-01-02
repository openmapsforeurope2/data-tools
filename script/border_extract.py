import psycopg2


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName

def run(
    conf,
    theme,
    tables,
    output,
    distance,
    countryCodes,
    borderCountryCode,
    boundaryType,
    inUpArea,
    # inUpAreaW,
    fromUp,
    # fromArea,
    # extractAllCountries,
    reset,
    verbose
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
        where_statement_boundary += (" AND " if where_statement_boundary else "") + conf['data']['common_fields']['country'] + (" = '"+country+"'" if borderCountryCode == False else " LIKE '%"+country+"%'")
        if country != "#":
            where_statement_data += (" OR " if where_statement_data else "") + conf['data']['common_fields']['country'] + (" = '"+country+"'" if borderCountryCode == False else " LIKE '%"+country+"%'")
    if borderCountryCode :
        where_statement_boundary += (" AND " if where_statement_boundary else "") + conf['data']['common_fields']['country'] + " LIKE '%"+borderCountryCode+"%'"

    if boundaryType == "international":
        where_statement_boundary += (" AND " if where_statement_boundary else "") + conf['boundary']['fields']['type'] + " = '" + conf['boundary']['boundary_type_values']['international'] + "'"
    
    
    boundary_statement = "ST_Union(ARRAY((SELECT "+conf['boundary']['fields']['geometry']+" FROM "+getTableName(conf['boundary']['schema'], conf['boundary']['table'])+" WHERE "+where_statement_boundary+")))"
    boundary_buffer_statement = "SELECT ST_Buffer(("+boundary_statement+"),"+ str(distance)+")"

    
    theme_schema = conf['data']['themes'][theme]['schema']
    working_schema = conf['data']['themes'][theme]['w_schema']
    update_schema = conf['data']['themes'][theme]['u_schema']
    
    if not tables:
        tables = conf['data']['themes'][theme]['tables']
        
    for tb in tables:
        wTableName = getTableName(working_schema, tb)+conf['data']['working']['suffix']
        wIdsTableName = getTableName(working_schema, tb)+conf['data']['working']['ids_suffix']
        sourceSchema = update_schema if fromUp else theme_schema
        if fromUp :
            tb += conf['data']['update']['suffix']
        tableName = getTableName(sourceSchema, tb)

        # where_geom_statement = ""
        if inUpArea:
            inUpArea_statement = "ST_Union(ARRAY((SELECT "+conf['data']['common_fields']['geometry']+" FROM "+getTableName(update_schema, tb)+conf['data']['update']['area_suffix']
            inUpArea_statement += " WHERE ST_Intersects("+conf['data']['common_fields']['geometry']+", ("+boundary_buffer_statement+"))"
            inUpArea_statement +=")))"
            where_statement_data += (" AND " if where_statement_data else "") + "ST_Intersects("+conf['data']['common_fields']['geometry']+", ("+inUpArea_statement+"))"

        # on recupère tous les noms de champs de la table
        q = "SELECT string_agg(column_name,',') FROM information_schema.columns WHERE column_name not like '%gcms%' and table_name = '"+tb+"' "+ ("AND table_schema = '"+sourceSchema+"'") if sourceSchema else ""
        print(u'query: {}'.format(q[:500]), flush=True)
        try:
            cursor.execute(q)
        except Exception as e:
            print(e)
            raise
        fields = cursor.fetchone()[0]

        ids = None
        if not reset :
            # on recupere tout les ids deja extraits pour ne pas les extraires a nouveau
            q3 = "SELECT string_agg("+conf['data']['common_fields']['id']+"::character varying,',') FROM "+wIdsTableName
            print(u'query: {}'.format(q3[:500]), flush=True)
            try:
                cursor.execute(q3)
            except Exception as e:
                print(e)
                raise
            ids = cursor.fetchone()[0]
            if ids is not None:
                ids = ids.split(',')
                ids = "','".join(ids)

        query = ""
        if reset : query += "DELETE FROM "+wTableName+";"
        query += "INSERT INTO "+wTableName+" ("+fields+") SELECT "+fields+" FROM "+tableName
        query += " WHERE "+where_statement_data
        # query += " AND NOT gcms_detruit"
        query += " AND ST_Intersects("+conf['data']['common_fields']['geometry']+",("+boundary_buffer_statement+"))"
        if 'where' in conf['border_extraction'] and conf['border_extraction']['where']:
            query += " AND "+conf['border_extraction']['where']
        if not reset and ids is not None:
            query += " AND "+conf['data']['common_fields']['id']+" NOT IN ('"+ids+"')"

        print(u'query: {}'.format(query[:500]), flush=True)
        print(u'query: {}'.format(query), flush=True)
        try:
            cursor.execute(query)
        except Exception as e:
            print(e)
            raise
        conn.commit()

        # on enregistre tous les identifiants des objects extraits
        q2 = "DELETE FROM "+wIdsTableName+";"
        q2 += "INSERT INTO "+wIdsTableName+" ("+conf['data']['common_fields']['id']+") SELECT "+conf['data']['common_fields']['id']+" FROM "+wTableName
        print(u'query: {}'.format(q2[:500]), flush=True)
        try:
            cursor.execute(q2)
        except Exception as e:
            print(e)
            raise
        conn.commit()

    cursor.close()
    conn.close()