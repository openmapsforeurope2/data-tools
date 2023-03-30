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
        query = getCreateTableStatement(mcd, theme, tableName)
        query += getCreateIndexesStatement(mcd, theme, tableName)

        print(u'query: {}'.format(query), flush=True)
        cursor.execute(query)
        conn.commit()

        # working
        query_w = getCreateWorkingTableStatement(mcd, theme, tableName)
        query_w += getCreateWorkingIndexesStatement(mcd, theme, tableName)

        print(u'query: {}'.format(query_w), flush=True)
        cursor.execute(query_w)
        conn.commit()

        # ids
        query_ids = getCreateWorkingIdsTableStatement(mcd, theme, tableName)
        query_ids += getCreateWorkingIdsIndexesStatement(mcd, theme, tableName)

        print(u'query: {}'.format(query_ids), flush=True)
        cursor.execute(query_ids)
        conn.commit()

        # history
        query_h = getCreateHistoryTableStatement(mcd, theme, tableName)
        query_h += getCreateHistoryIndexesStatement(mcd, theme, tableName)

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

def getTableFields(conf, theme, tableName):
    fieldsToCreate = ""
    fieldsToCreate = getFields(conf['common']['id_field'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(conf['common']['fields'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(conf['themes'][theme]['tables'][tableName]['fields'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(conf['common']['working_fields'], fieldsToCreate)
    return fieldsToCreate

def getWorkingTableFields(conf, theme, tableName):
    return getTableFields(conf, theme, tableName)

def getWorkingIdsTableFields(conf, theme, tableName):
    fieldsToCreate = ""
    fieldsToCreate = getFields(conf['working_ids']['id_field'], fieldsToCreate)
    return fieldsToCreate

def getHistoryTableFields(conf, theme, tableName):
    fieldsToCreate = ""
    fieldsToCreate = getFields(conf['history']['id_field'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(conf['common']['fields'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(conf['themes'][theme]['tables'][tableName]['fields'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(conf['common']['working_fields'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(conf['history']['fields'], fieldsToCreate)
    return fieldsToCreate

def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName

def getCreateTableStatement( conf, theme, tableName ):
    fullTableName = getTableName(conf['themes'][theme]['schema'], tableName)
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getTableFields( conf, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO postgres;"
    statement += getPkeyConstraintStatement( conf, theme, tableName )
    return statement

def getCreateWorkingTableStatement( conf, theme, tableName ):
    fullTableName = getTableName(conf['working']['schema'], tableName)+conf['working']['suffix']
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getWorkingTableFields( conf, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO postgres;"
    statement += getWorkingPkeyConstraintStatement( conf, theme, tableName )
    return statement

def getCreateWorkingIdsTableStatement( conf, theme, tableName ):
    fullTableName = getTableName(conf['working_ids']['schema'], tableName)+conf['working_ids']['suffix']
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getWorkingIdsTableFields( conf, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO postgres;"
    statement += getWorkingIdsPkeyConstraintStatement( conf, theme, tableName )
    return statement

def getCreateHistoryTableStatement( conf, theme, tableName ):
    fullTableName = getTableName(conf['themes'][theme]['schema'], tableName)+conf['history']['suffix']
    statement = "DROP TABLE IF EXISTS "+fullTableName+"; CREATE TABLE "+fullTableName
    statement += " ("+getHistoryTableFields( conf, theme, tableName )+") WITH (OIDS=FALSE);"
    statement += "ALTER TABLE "+fullTableName+" OWNER TO postgres;"
    statement += getHistoryPkeyConstraintStatement( conf, theme, tableName )
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

def getCreateIndexesStatement(conf, theme, tableName):
    schema = conf['themes'][theme]['schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(conf['common']['id_field'], schema, tableName, indexesToCreate)
    indexesToCreate = getIndexes(conf['common']['working_fields'], schema, tableName, indexesToCreate)
    indexesToCreate = getIndexes(conf['common']['fields'], schema, tableName, indexesToCreate)
    indexesToCreate = getIndexes(conf['themes'][theme]['tables'][tableName]['fields'], schema, tableName, indexesToCreate)
    return indexesToCreate

def getCreateWorkingIndexesStatement(conf, theme, tableName):
    tableCompleteName = tableName + conf['working']['suffix']
    schema = conf['working']['schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(conf['common']['id_field'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(conf['common']['working_fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(conf['common']['fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(conf['themes'][theme]['tables'][tableName]['fields'], schema, tableCompleteName, indexesToCreate)
    return indexesToCreate

def getCreateWorkingIdsIndexesStatement(conf, theme, tableName):
    tableCompleteName = tableName + conf['working_ids']['suffix']
    schema = conf['working']['schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(conf['working_ids']['id_field'], schema, tableCompleteName, indexesToCreate)
    return indexesToCreate

def getCreateHistoryIndexesStatement(conf, theme, tableName):
    tableCompleteName = tableName + conf['history']['suffix']
    schema = conf['themes'][theme]['schema']
    indexesToCreate = ""
    indexesToCreate = getIndexes(conf['history']['id_field'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(conf['common']['working_fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(conf['common']['fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(conf['themes'][theme]['tables'][tableName]['fields'], schema, tableCompleteName, indexesToCreate)
    indexesToCreate = getIndexes(conf['history']['fields'], schema, tableCompleteName, indexesToCreate)
    return indexesToCreate

def getPkeyConstraintStatement(conf, theme, tableName):
    schema = conf['themes'][theme]['schema']

    pkeyFields = []
    getPkeyFields(conf['common']['id_field'], pkeyFields)
    getPkeyFields(conf['common']['working_fields'], pkeyFields)
    getPkeyFields(conf['common']['fields'], pkeyFields)
    getPkeyFields(conf['themes'][theme]['tables'][tableName]['fields'], pkeyFields)

    return _getPkeyConstraintStatement(getTableName(schema, tableName), pkeyFields)

def getWorkingPkeyConstraintStatement(conf, theme, tableName):
    tableCompleteName = tableName + conf['working']['suffix']
    schema = conf['working']['schema']

    pkeyFields = []
    getPkeyFields(conf['common']['id_field'], pkeyFields)
    getPkeyFields(conf['common']['working_fields'], pkeyFields)
    getPkeyFields(conf['common']['fields'], pkeyFields)
    getPkeyFields(conf['themes'][theme]['tables'][tableName]['fields'], pkeyFields)

    return _getPkeyConstraintStatement(getTableName(schema, tableCompleteName), pkeyFields)

def getWorkingIdsPkeyConstraintStatement(conf, theme, tableName):
    tableCompleteName = tableName + conf['working_ids']['suffix']
    schema = conf['working_ids']['schema']

    pkeyFields = []
    getPkeyFields(conf['working_ids']['id_field'], pkeyFields)

    return _getPkeyConstraintStatement(getTableName(schema, tableCompleteName), pkeyFields)

def getHistoryPkeyConstraintStatement(conf, theme, tableName):
    tableCompleteName = tableName + conf['history']['suffix']
    schema = conf['themes'][theme]['schema']

    pkeyFields = []
    getPkeyFields(conf['history']['id_field'], pkeyFields)
    getPkeyFields(conf['common']['working_fields'], pkeyFields)
    getPkeyFields(conf['common']['fields'], pkeyFields)
    getPkeyFields(conf['themes'][theme]['tables'][tableName]['fields'], pkeyFields)
    getPkeyFields(conf['history']['fields'], pkeyFields)

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