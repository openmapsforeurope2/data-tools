import psycopg2


def createTableAndIndexes(conf, mcd, theme, tables):
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
        query = getCreateTableStatement(conf, mcd, theme, tableName)
        query += getCreateIndexesStatement(conf, mcd, theme, tableName)

        print(u'query: {}'.format(query), flush=True)
        cursor.execute(query)
        conn.commit()

        # working
        query_w = getCreateWorkingTableStatement(conf, mcd, theme, tableName)
        query_w += getCreateWorkingIndexesStatement(conf, mcd, theme, tableName)

        print(u'query: {}'.format(query_w), flush=True)
        cursor.execute(query_w)
        conn.commit()

        # ids
        query_ids = getCreateWorkingIdsTableStatement(conf, mcd, theme, tableName)
        query_ids += getCreateWorkingIdsIndexesStatement(conf, mcd, theme, tableName)

        print(u'query: {}'.format(query_ids), flush=True)
        cursor.execute(query_ids)
        conn.commit()

        # history
        query_h = getCreateHistoryTableStatement(conf, mcd, theme, tableName)
        query_h += getCreateHistoryIndexesStatement(conf, mcd, theme, tableName)

        print(u'query: {}'.format(query_h), flush=True)
        cursor.execute(query_h)
        conn.commit()

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
    return getTableFields(mcd, theme, tableName)

def getWorkingIdsTableFields(mcd, theme, tableName):
    fieldsToCreate = ""
    fieldsToCreate = getFields(mcd['working_ids']['id_field'], fieldsToCreate)
    return fieldsToCreate

def getHistoryTableFields(mcd, theme, tableName):
    fieldsToCreate = ""
    fieldsToCreate = getFields(mcd['history']['id_field'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(mcd['common']['fields'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(mcd['themes'][theme]['tables'][tableName]['fields'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(mcd['common']['working_fields'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(mcd['history']['fields'], fieldsToCreate)
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

def getCreateWorkingTableStatement( conf, mcd, theme, tableName ):
    fullTableName = getTableName(conf['data']['themes'][theme]['w_schema'], tableName)+conf['data']['working']['suffix']
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getWorkingTableFields( mcd, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO "+conf['db']['user']+";"
    statement += getWorkingPkeyConstraintStatement( conf, mcd, theme, tableName )
    return statement

def getCreateWorkingIdsTableStatement( conf, mcd, theme, tableName ):
    fullTableName = getTableName(conf['data']['themes'][theme]['w_schema'], tableName)+conf['data']['working']['ids_suffix']
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getWorkingIdsTableFields( mcd, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO "+conf['db']['user']+";"
    statement += getWorkingIdsPkeyConstraintStatement( conf, mcd, theme, tableName )
    return statement

def getCreateHistoryTableStatement( conf, mcd, theme, tableName ):
    fullTableName = getTableName(conf['data']['themes'][theme]['h_schema'], tableName)+conf['data']['history']['suffix']
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getHistoryTableFields( mcd, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO "+conf['db']['user']+";"
    statement += getHistoryPkeyConstraintStatement( conf, mcd, theme, tableName )
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

def getCreateWorkingIndexesStatement(conf, mcd, theme, tableName):
    tableCompleteName = tableName + conf['data']['working']['suffix']
    schema = conf['data']['themes'][theme]['w_schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(mcd['common']['id_field'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['working_fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['themes'][theme]['tables'][tableName]['fields'], schema, tableCompleteName, indexesToCreate)
    return indexesToCreate

def getCreateWorkingIdsIndexesStatement(conf, mcd, theme, tableName):
    tableCompleteName = tableName + conf['data']['working']['ids_suffix']
    schema = conf['data']['themes'][theme]['w_schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(mcd['working_ids']['id_field'], schema, tableCompleteName, indexesToCreate)
    return indexesToCreate

def getCreateHistoryIndexesStatement(conf, mcd, theme, tableName):
    tableCompleteName = tableName + conf['data']['history']['suffix']
    schema = conf['data']['themes'][theme]['h_schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(mcd['history']['id_field'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['working_fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['common']['fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['themes'][theme]['tables'][tableName]['fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(mcd['history']['fields'], schema, tableCompleteName, indexesToCreate)
    return indexesToCreate

def getPkeyConstraintStatement(conf, mcd, theme, tableName):
    schema = conf['data']['themes'][theme]['schema']

    pkeyFields = []
    getPkeyFields(mcd['common']['id_field'], pkeyFields)
    getPkeyFields(mcd['common']['working_fields'], pkeyFields)
    getPkeyFields(mcd['common']['fields'], pkeyFields)
    getPkeyFields(mcd['themes'][theme]['tables'][tableName]['fields'], pkeyFields)

    return _getPkeyConstraintStatement(getTableName(schema, tableName), pkeyFields)

def getWorkingPkeyConstraintStatement(conf, mcd, theme, tableName):
    tableCompleteName = tableName + conf['data']['working']['suffix']
    schema = conf['data']['themes'][theme]['w_schema']

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

def getHistoryPkeyConstraintStatement(conf, mcd, theme, tableName):
    tableCompleteName = tableName + conf['data']['history']['suffix']
    schema = conf['data']['themes'][theme]['h_schema']

    pkeyFields = []
    getPkeyFields(mcd['history']['id_field'], pkeyFields)
    getPkeyFields(mcd['common']['working_fields'], pkeyFields)
    getPkeyFields(mcd['common']['fields'], pkeyFields)
    getPkeyFields(mcd['themes'][theme]['tables'][tableName]['fields'], pkeyFields)
    getPkeyFields(mcd['history']['fields'], pkeyFields)

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