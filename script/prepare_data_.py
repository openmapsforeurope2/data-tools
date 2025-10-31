import psycopg2
import border_extract_
import border_extract_with_neighbors_


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName


def getPkeyConstraintStatement(fields, targetTableName):
    q = ""
    for field in fields:
        if 'pkey' in fields[field] and fields[field]['pkey']:
            q += "ALTER TABLE " + targetTableName + " ADD CONSTRAINT "+ targetTableName.replace(".", "_") + field +"_pkey PRIMARY KEY ("+ field +");"
            q += "ALTER TABLE " + targetTableName + " ALTER COLUMN " + field + " SET NOT NULL;"
            if "default" in fields[field]['sql_type'].lower() :
                parts = fields[field]['sql_type'].lower().split('default')
                q += "ALTER TABLE " + targetTableName + " ALTER COLUMN " + field + " SET DEFAULT "+ parts[-1] +";"
    return q


def getAllPkeyConstraintStatement(mcd, theme, tableName, targetTableName, isWorkingTable):
    q = getPkeyConstraintStatement(mcd['common']['id_field'], targetTableName)
    q += getPkeyConstraintStatement(mcd['common']['working_fields'], targetTableName)
    q += getPkeyConstraintStatement(mcd['common']['fields'], targetTableName)
    q += getPkeyConstraintStatement(mcd['themes'][theme]['tables'][tableName]['fields'], targetTableName)
    if isWorkingTable :
        q += getPkeyConstraintStatement(mcd['work']['working_fields'], targetTableName)
    return q


def getCreateIndexStatement(fields, targetTableName):
    q = ""
    for field in fields:
        if 'index' in fields[field]:
            q += "CREATE INDEX IF NOT EXISTS " + targetTableName.replace(".", "_")+"_"+field+"_idx ON " + targetTableName
            if fields[field]['index'] == "gist":
                q += " USING gist ("+field+");"
            elif fields[field]['index'] == "gin":
                q += " USING gin ("+field+");"
            elif fields[field]['index'] == "default":
                q += " USING btree ("+field+" ASC NULLS LAST);"
            else:
                raise Exception('Unknown index: '+fields[field]['index'])
    return q


def getAllCreateIndexStatement(mcd, theme, tableName, targetTableName, isWorkingTable):
    q = getCreateIndexStatement(mcd['common']['id_field'], targetTableName)
    q += getCreateIndexStatement(mcd['common']['working_fields'], targetTableName)
    q += getCreateIndexStatement(mcd['common']['fields'], targetTableName)
    q += getCreateIndexStatement(mcd['themes'][theme]['tables'][tableName]['fields'], targetTableName)
    if isWorkingTable :
        q += getCreateIndexStatement(mcd['work']['working_fields'], targetTableName)
    return q


def getGrantStatement(tableFullName, user):
    return "GRANT ALL ON " + tableFullName + " TO " + user + ";"


def getInitTableStatement( mcd, theme, tableName, sourceTableName, targetTableName, isWorkingTable, user = None ):
    q = "DROP TABLE IF EXISTS " + targetTableName + ";"
    q += "CREATE TABLE " + targetTableName + " AS SELECT * FROM " + sourceTableName + ";"
    q += getAllPkeyConstraintStatement(mcd, theme, tableName, targetTableName, isWorkingTable)
    q += getAllCreateIndexStatement(mcd, theme, tableName, targetTableName, isWorkingTable)
    if user :
        q += getGrantStatement(targetTableName, user)
    return q


def run(
    conf,
    mcd,
    theme,
    tables,
    suffix,
    countryCodes,
    neighbors,
    operation,
    verbose
):
    """
    prépare les tables de travail préalablement à une étape de traitement

    Paramètres:
    conf (objet) : configuration
    mcd (objet) : description du modèle de données
    theme (str) : thème à préparer
    tables (array) : tables à préparer (si le tableau est vide ce sont toutes les tables du thème qui seront préparées)
    suffix (str) : suffix appliqué aux tables préparées
    countryCodes (array) : codes des pays à traiter
    operation (str) : indique la nature de l'operation à réaliser
    verbose (bool) : mode verbeux
    """

    if operation == "au_matching":
        tables = [conf['data']['operation'][operation]["table_name_prefix"]+str(conf['data']['operation'][operation]["lowest_level"][c]) for c in countryCodes]
        theme = conf['data']["themes"]["au"]["schema"]

    if not tables:
        tables = conf['data']['operation'][operation]['themes'][theme]['tables'].keys()
    
    extract_data(conf, theme, tables, countryCodes, neighbors, operation, verbose)
    init_working_tables(conf, mcd, theme, tables, suffix, countryCodes, operation, verbose)


def init_working_tables(
    conf,
    mcd,
    theme,
    tables,
    suffix,
    countryCodes,
    operation,
    verbose
):
    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])
    cursor = conn.cursor()

    countryCodes = sorted(countryCodes)

    if operation in ["net_matching", "area_matching", "au_matching"] :
        
        suffix = "_" + "_".join(countryCodes) + "_" + suffix

        borderCode = "#".join(countryCodes)

        where_statement = ""
        for country in countryCodes:
            where_statement += (" OR " if where_statement else "") + conf['data']['common_fields']['country'] + " LIKE '%" + country + "%'"
        where_statement = "("+where_statement+")"
        
        working_schema = conf['data']['themes'][theme]['w_schema']
            
        for tableName in tables:
            wTableName = getTableName(working_schema, tableName)+conf['data']['working']['suffix']
            targetTableName = wTableName + suffix

            q = getInitTableStatement( mcd, theme, tableName, wTableName, targetTableName, True )

            # print(u'query: {}'.format(q[:500]), flush=True)
            print(u'query: {}'.format(q), flush=True)
            try:
                cursor.execute(q)
            except Exception as e:
                print(e)
                raise
            conn.commit()

    elif operation == "net_matching_validation" :
        prefix = "_".join(countryCodes) + "_"
        suffix = "_" + "_".join(countryCodes) + "_" + suffix


        target_schema = conf['data']['themes'][theme]['v_schema']
        source_schema = conf['data']['themes'][theme]['w_schema']

        for tableName in tables:
            final_step = conf['data']['operation']['net_matching']['themes'][theme]['tables'][tableName]['final_step']

            sourceInitTableName = getTableName(source_schema, tableName) + conf['data']['working']['suffix'] + suffix
            sourceFinalTableName = "_" + final_step + "_" + sourceInitTableName

            targetInitTableName = getTableName(target_schema, prefix + tableName) + conf['data']['validation']['suffix']['init']
            targetRefTableName = getTableName(target_schema, prefix + tableName) + conf['data']['validation']['suffix']['ref']
            targetCorrectTableName = getTableName(target_schema, prefix + tableName) + conf['data']['validation']['suffix']['correct']

            q = getInitTableStatement( mcd, theme, tableName, sourceInitTableName, targetInitTableName, False, conf['data']['validation']['user'] )
            q += getInitTableStatement( mcd, theme, tableName, sourceFinalTableName, targetCorrectTableName, False, conf['data']['validation']['user'] )
            q += getInitTableStatement( mcd, theme, tableName, sourceFinalTableName, targetRefTableName, False )

            # print(u'query: {}'.format(q[:500]), flush=True)
            print(u'query: {}'.format(q), flush=True)
            try:
                cursor.execute(q)
            except Exception as e:
                print(e)
                raise
            conn.commit()

    cursor.close()
    conn.close()

def get_extraction_distance(
    conf,
    operation,
    countryCodes,
    theme = None
):
    operation_conf = None
    if theme is None :
        operation_conf = conf['data']['operation'][operation]
    else :
        operation_conf = conf['data']['operation'][operation]['themes'][theme]

    distance = operation_conf['extraction_distance']['default']
    for country in  countryCodes:
        if country in operation_conf['extraction_distance'] :
            countryDist = operation_conf['extraction_distance'][country]
            if countryDist > distance:
                distance = countryDist
    return distance

def extract_data(
    conf,
    theme,
    tables,
    countryCodes,
    neighbors,
    operation,
    verbose
):
    if operation in ["net_matching", "area_matching"] :
        borderCountryCode = None
        boundaryType = None
        fromUp = False
        reset = True
        distance = get_extraction_distance(conf, operation, countryCodes, theme)

        border_extract_.run(conf, theme, tables, distance, countryCodes, borderCountryCode, boundaryType, fromUp, reset, verbose)

    elif operation == "au_matching" :
        inDispute = None
        all = True if len(neighbors) == 0 else False
        distance = get_extraction_distance(conf, operation, countryCodes)

        border_extract_with_neighbors_.run(conf, theme, tables, distance, countryCodes, neighbors, inDispute, all, verbose)

    elif operation == "net_matching_validation" :
        return

    else :
        raise Exception('Unknown operation: '+operation)

