import psycopg2


def createViews(conf, mcd, theme, tables):
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

    print("CREATING VIEWS...", flush=True)

    list_tables_not_released = ["administrative_boundary","residence_of_authority","international_boundary_node","landmask"]

    if not tables :
        tables = mcd['themes'][theme]['tables'].keys()
    
    for tableName in tables:
        # table
        print(u'table: {}'.format(tableName), flush=True)
        if tableName in list_tables_not_released:
            continue
        query = getCreateViewStatement(conf, mcd, theme, tableName)
        #query += getCreateIndexesStatement(conf, mcd, theme, tableName)
        #query += getCreateTrigger(conf, theme, tableName)

        print(u'query: {}'.format(query), flush=True)
        # print(u'{}'.format(query), flush=True)
        try:
            cursor.execute(query)
        except Exception as e:
            print(e)
            raise
        conn.commit()

    cursor.close()
    conn.close()


def getOrderedFields(fields, fieldsToCreate):  
    nbFields = len(fields)
    orderedFields= [u""] * nbFields
    for fieldTarget, fieldProps in fields.items():
        orderedFields[fieldProps['rank']-1] = fieldTarget
    for field in orderedFields:
        if 'sql_type' in fields[field]:
            fieldsToCreate += ("," if fieldsToCreate else "") + "a." + field

    return fieldsToCreate

def getFields(fields, fieldsToCreate):
    for field in fields:
        if 'sql_type' in fields[field]:
            fieldsToCreate += ("," if fieldsToCreate else "") + "a." + field

    return fieldsToCreate

def getViewFields(mcd, theme, tableName):
    fieldsToCreate = ""
    fieldsToCreate = getFields(mcd['common']['id_field'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(mcd['common']['fields'], fieldsToCreate)
    fieldsToCreate = getOrderedFields(mcd['themes'][theme]['tables'][tableName]['fields'], fieldsToCreate)
    #fieldsToCreate = getOrderedFields(mcd['common']['working_fields'], fieldsToCreate)
    return fieldsToCreate

def getViewName(schema , tableName):
    return ("release." + schema + "_" if schema else "") + tableName

def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName

def getCreateViewStatement( conf, mcd, theme, tableName ):
    viewName = getViewName(conf['data']['themes'][theme]['schema'], tableName)
    print ("viewName = " + viewName)
    fullTableName = getTableName(conf['data']['themes'][theme]['schema'], tableName)
    print ("fullTableName = " + fullTableName)
    fields = getViewFields( mcd, theme, tableName )

    statement = "CREATE OR REPLACE VIEW " + viewName + " AS SELECT "
    statement += " "+getViewFields( mcd, theme, tableName )
    statement += " FROM "+fullTableName+" a "
    
    if str.find(fields, "geom") != -1: # Tables with life-cycle management system
        statement += " WHERE NOT a.gcms_detruit;"
    
    statement += " AND w_release = 1;"
    return statement
