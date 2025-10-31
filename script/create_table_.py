import psycopg2


def createTableAndIndexes(conf, mcd, theme, tables):
    """
    Fonction utilitaire pour la création des tables.

    Paramètres:
    conf (objet) : configuration
    mcd (objet) : description du modèle de données
    theme (str) : thème dont on souhaite créer les tables
    tables (array) : tables à créer (si le tableau est vide ce sont toutes les tables du thème qui seront créées)
    """

    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])
    cursor = conn.cursor()

    print("CREATING TABLES...", flush=True)

    if not tables :
        tables = mcd['themes'][theme]['tables'].keys()
    
    for tableName in tables:
        # table
        print(u'table: {}'.format(tableName), flush=True)
        query = getCreateTableStatement(conf, mcd, theme, tableName)
        query += getCreateIndexesStatement(conf, mcd, theme, tableName)
        query += getCreateTrigger(conf, theme, tableName)

        print(u'query: {}'.format(query), flush=True)
        try:
            cursor.execute(query)
        except psycopg2.Error as e:
            print(e)
            raise
        conn.commit()

        # up
        query_u = getCreateUpdateTableStatement(conf, mcd, theme, tableName)
        query_u += getCreateUpdateIndexesStatement(conf, mcd, theme, tableName)
        query_u += getCreateUpdateTrigger(conf, theme, tableName)

        print(u'query: {}'.format(query_u), flush=True)
        try:
            cursor.execute(query_u)
        except psycopg2.Error as e:
            print(e)
            raise
        conn.commit()

        # ref
        query_r = getCreateRefTableStatement(conf, mcd, theme, tableName)
        query_r += getCreateRefIndexesStatement(conf, mcd, theme, tableName)
        query_r += getCreateRefTrigger(conf, theme, tableName)

        print(u'query: {}'.format(query_r), flush=True)
        try:
            cursor.execute(query_r)
        except psycopg2.Error as e:
            print(e)
            raise
        conn.commit()
        
    cursor.close()
    conn.close()

def getWorkingTablename(conf, theme, tableName, suffix):
    return getTableName(conf['data']['themes'][theme]['w_schema'], tableName)+conf['data']['working']['suffix']+suffix

def getWorkingIdsTablename(conf, theme, tableName, suffix):
    return getTableName(conf['data']['themes'][theme]['w_schema'], tableName)+conf['data']['working']['ids_suffix']+suffix

def createWorkingTable(conf, mcd, theme, tableName, suffix):
    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])
    cursor = conn.cursor()

    print("CREATING WORKING TABLE...", flush=True)

    fullTableName = getWorkingTablename(conf, theme, tableName, suffix)
    query_w = getCreateWorkingTableStatement(conf, mcd, theme, tableName, suffix)
    query_w += getCreateWorkingIndexesStatement(conf, mcd, theme, tableName, suffix)
    query_w += getCreateWorkingTrigger(conf, theme, tableName, suffix)

    print(u'query: {}'.format(query_w), flush=True)
    try:
        cursor.execute(query_w)
    except psycopg2.Error as e:
        print(e)
        raise
    conn.commit()

    cursor.close()
    conn.close()

    return fullTableName

def createWorkingIdsTable(conf, mcd, theme, tableName, suffix):
    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])
    cursor = conn.cursor()

    print("CREATING WORKING IDS TABLE...", flush=True)

    fullTableName = getWorkingIdsTablename(conf, theme, tableName, suffix)
    query_ids = getCreateWorkingIdsTableStatement(conf, mcd, theme, tableName, suffix)
    query_ids += getCreateWorkingIdsIndexesStatement(conf, mcd, theme, tableName, suffix)

    print(u'query: {}'.format(query_ids), flush=True)
    try:
        cursor.execute(query_ids)
    except psycopg2.Error as e:
        print(e)
        raise
    conn.commit()

    cursor.close()
    conn.close()

    return fullTableName

def getCreateTrigger(conf, theme, tableName):
    fullTableName = getTableName(conf['data']['themes'][theme]['schema'], tableName)
    return _getCreateTrigger(conf, theme, fullTableName)

def getCreateWorkingTrigger(conf, theme, tableName, suffix):
    fullTableName = getWorkingTablename(conf, theme, tableName, suffix)
    return _getCreateTrigger(conf, theme, fullTableName)

def getCreateUpdateTrigger(conf, theme, tableName):
    fullTableName = getTableName(conf['data']['themes'][theme]['u_schema'], tableName)+conf['data']['update']['suffix']
    return _getCreateTrigger(conf, theme, fullTableName)

def getCreateRefTrigger(conf, theme, tableName):
    fullTableName = getTableName(conf['data']['themes'][theme]['r_schema'], tableName)+conf['data']['reference']['suffix']
    return _getCreateTrigger(conf, theme, fullTableName)

def _getCreateTrigger(conf, theme, fullTableName):
        if theme == "au" or theme == "ib" or fullTableName.endswith('drainage_basin'):
            return "CREATE TRIGGER ome2_reduce_precision_2d_trigger BEFORE INSERT OR UPDATE ON "+fullTableName+" FOR EACH ROW EXECUTE PROCEDURE public.ome2_reduce_precision_2d_trigger_function();"
        else:    
            return "CREATE TRIGGER ome2_reduce_precision_3d_trigger BEFORE INSERT OR UPDATE ON "+fullTableName+" FOR EACH ROW EXECUTE PROCEDURE public.ome2_reduce_precision_3d_trigger_function();"

def getOrderedFields(fields, fieldsToCreate):  
    nbFields = len(fields)
    orderedFields= [u""] * nbFields
    for fieldTarget, fieldProps in fields.items():
        orderedFields[fieldProps['rank']-1] = fieldTarget
    for field in orderedFields:
        if 'sql_type' in fields[field]:
            fieldsToCreate += ("," if fieldsToCreate else "") + field + " " + fields[field]['sql_type']

    return fieldsToCreate

def getFields(fields, fieldsToCreate):
    for field in fields:
        if 'sql_type' in fields[field]:
            fieldsToCreate += ("," if fieldsToCreate else "") + field + " " + fields[field]['sql_type']

    return fieldsToCreate

def getTableFields(mcd, theme, tableName):
    fieldsToCreate = ""
    fieldsToCreate = getFields(mcd['common']['id_field'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(mcd['common']['fields'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(mcd['themes'][theme]['tables'][tableName]['fields'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(mcd['common']['working_fields'], fieldsToCreate)
    return fieldsToCreate

def getWorkingTableFields(mcd, theme, tableName):
    fieldsToCreate = getTableFields(mcd, theme, tableName)
    fieldsToCreate = getOrderedFields(mcd['work']['working_fields'], fieldsToCreate)
    return fieldsToCreate

def getWorkingIdsTableFields(mcd, theme, tableName):
    fieldsToCreate = ""
    fieldsToCreate = getFields(mcd['working_ids']['id_field'], fieldsToCreate)
    return fieldsToCreate

def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName

def getCreateTableStatement( conf, mcd, theme, tableName ):
    fullTableName = getTableName(conf['data']['themes'][theme]['schema'], tableName)
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getTableFields( mcd, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO "+conf['db']['user']+";"
    statement += getPkeyConstraintStatement( conf, mcd, theme, tableName )
    return statement

def getCreateWorkingTableStatement( conf, mcd, theme, tableName, suffix ):
    fullTableName = getWorkingTablename(conf, theme, tableName, suffix )
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getWorkingTableFields( mcd, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO "+conf['db']['user']+";"
    statement += getWorkingPkeyConstraintStatement( conf, mcd, theme, tableName )
    return statement

def getCreateUpdateTableStatement( conf, mcd, theme, tableName ):
    fullTableName = getTableName(conf['data']['themes'][theme]['u_schema'], tableName)+conf['data']['update']['suffix']
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getTableFields( mcd, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO "+conf['db']['user']+";"
    statement += getUpdatePkeyConstraintStatement( conf, mcd, theme, tableName )
    return statement

def getCreateRefTableStatement( conf, mcd, theme, tableName ):
    fullTableName = getTableName(conf['data']['themes'][theme]['r_schema'], tableName)+conf['data']['reference']['suffix']
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getTableFields( mcd, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO "+conf['db']['user']+";"
    statement += getRefPkeyConstraintStatement( conf, mcd, theme, tableName )
    return statement

def getCreateWorkingIdsTableStatement( conf, mcd, theme, tableName, suffix ):
    fullTableName = getWorkingIdsTablename(conf, theme, tableName, suffix)
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getWorkingIdsTableFields( mcd, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO "+conf['db']['user']+";"
    statement += getWorkingIdsPkeyConstraintStatement( conf, mcd, theme, tableName )
    return statement

def getIndexes(fields, schema, tableName, indexesToCreate):
    indexPrefix = (schema+"_" if schema else "") + tableName
    for field in fields:
        if 'index' in fields[field]:
            indexesToCreate += (";" if indexesToCreate else "") + "CREATE INDEX "+indexPrefix+"_"+field+"_idx ON "+getTableName(schema, tableName)
            if fields[field]['index'] == "gist":
                indexesToCreate += " USING gist"
            elif fields[field]['index'] == "gin":
                indexesToCreate += " USING gin"
            elif fields[field]['index'] == "default":
                indexesToCreate += ""
            else:
                raise Exception('Unknown index: '+fields[field]['index'])

            indexesToCreate += " ("+field+");"
    return indexesToCreate

def getCreateIndexesStatement(conf, mcd, theme, tableName):
    schema = conf['data']['themes'][theme]['schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(mcd['common']['id_field'], schema, tableName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['working_fields'], schema, tableName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['fields'], schema, tableName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['themes'][theme]['tables'][tableName]['fields'], schema, tableName, indexesToCreate)
    return indexesToCreate

def getCreateRefIndexesStatement(conf, mcd, theme, tableName):
    tableCompleteName = tableName + conf['data']['reference']['suffix']
    schema = conf['data']['themes'][theme]['r_schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(mcd['common']['id_field'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['working_fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['themes'][theme]['tables'][tableName]['fields'], schema, tableCompleteName, indexesToCreate)
    return indexesToCreate

def getCreateWorkingIndexesStatement(conf, mcd, theme, tableName, suffix):
    tableCompleteName = tableName + conf['data']['working']['suffix']+suffix
    schema = conf['data']['themes'][theme]['w_schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(mcd['common']['id_field'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['working_fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['themes'][theme]['tables'][tableName]['fields'], schema, tableCompleteName, indexesToCreate)
    return indexesToCreate

def getCreateUpdateIndexesStatement(conf, mcd, theme, tableName):
    tableCompleteName = tableName + conf['data']['update']['suffix']
    schema = conf['data']['themes'][theme]['u_schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(mcd['common']['id_field'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['working_fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['themes'][theme]['tables'][tableName]['fields'], schema, tableCompleteName, indexesToCreate)
    return indexesToCreate

def getCreateWorkingIdsIndexesStatement(conf, mcd, theme, tableName, suffix):
    tableCompleteName = tableName + conf['data']['working']['ids_suffix']+suffix
    schema = conf['data']['themes'][theme]['w_schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(mcd['working_ids']['id_field'], schema, tableCompleteName, indexesToCreate)
    return indexesToCreate

def getPkeyConstraintStatement(conf, mcd, theme, tableName):
    schema = conf['data']['themes'][theme]['schema']

    pkeyFields = []
    getPkeyFields(mcd['common']['id_field'], pkeyFields)
    getPkeyFields(mcd['common']['working_fields'], pkeyFields)
    getPkeyFields(mcd['common']['fields'], pkeyFields)
    getPkeyFields(mcd['themes'][theme]['tables'][tableName]['fields'], pkeyFields)

    return _getPkeyConstraintStatement(getTableName(schema, tableName), pkeyFields)

def getRefPkeyConstraintStatement(conf, mcd, theme, tableName):
    tableCompleteName = tableName + conf['data']['reference']['suffix']
    schema = conf['data']['themes'][theme]['r_schema']

    pkeyFields = []
    getPkeyFields(mcd['common']['id_field'], pkeyFields)
    getPkeyFields(mcd['common']['working_fields'], pkeyFields)
    getPkeyFields(mcd['common']['fields'], pkeyFields)
    getPkeyFields(mcd['themes'][theme]['tables'][tableName]['fields'], pkeyFields)

    return _getPkeyConstraintStatement(getTableName(schema, tableCompleteName), pkeyFields)

def getWorkingPkeyConstraintStatement(conf, mcd, theme, tableName):
    tableCompleteName = tableName + conf['data']['working']['suffix']
    schema = conf['data']['themes'][theme]['w_schema']

    pkeyFields = []
    getPkeyFields(mcd['common']['id_field'], pkeyFields)
    getPkeyFields(mcd['common']['working_fields'], pkeyFields)
    getPkeyFields(mcd['common']['fields'], pkeyFields)
    getPkeyFields(mcd['themes'][theme]['tables'][tableName]['fields'], pkeyFields)

    return _getPkeyConstraintStatement(getTableName(schema, tableCompleteName), pkeyFields)

def getUpdatePkeyConstraintStatement(conf, mcd, theme, tableName):
    tableCompleteName = tableName + conf['data']['update']['suffix']
    schema = conf['data']['themes'][theme]['u_schema']

    pkeyFields = []
    getPkeyFields(mcd['common']['id_field'], pkeyFields)
    getPkeyFields(mcd['common']['working_fields'], pkeyFields)
    getPkeyFields(mcd['common']['fields'], pkeyFields)
    getPkeyFields(mcd['themes'][theme]['tables'][tableName]['fields'], pkeyFields)

    return _getPkeyConstraintStatement(getTableName(schema, tableCompleteName), pkeyFields)

def getWorkingIdsPkeyConstraintStatement(conf, mcd, theme, tableName):
    tableCompleteName = tableName + conf['data']['working']['ids_suffix']
    schema = conf['data']['themes'][theme]['w_schema']

    pkeyFields = []
    getPkeyFields(mcd['working_ids']['id_field'], pkeyFields)

    return _getPkeyConstraintStatement(getTableName(schema, tableCompleteName), pkeyFields)

def _getPkeyConstraintStatement(fullTableName, pkeyFields):
    if not pkeyFields:
        return ""
    return "ALTER TABLE "+fullTableName+" ADD PRIMARY KEY ("+",".join(pkeyFields)+");"

def getPkeyFields(fields, pkeyFields):
    for field in fields:
        if 'pkey' in fields[field] and fields[field]['pkey']:
            pkeyFields.append(field)
    return pkeyFields