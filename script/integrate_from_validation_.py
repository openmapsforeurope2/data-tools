import psycopg2
import integrate_


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName


def run(
    conf,
    theme,
    tables,
    countryCodes,
    verbose
):
    """
    intégre les données de validation dans la base de production

    Paramètres:
    conf (objet) : configuration
    theme (str) : thème à intégrer
    tables (array) : tables à intégrer (si le tableau est vide ce sont toutes les tables du thème qui seront préparées)
    countryCodes (array) : codes des pays à traiter
    verbose (bool) : mode verbeux
    """
    print("INTEGRATING...", flush=True)

    if not tables:
        tables = conf['data']['operation']['matching']['themes'][theme]['tables'].keys()

    copy_data_in_working_tables(conf, theme, tables, countryCodes, verbose)
    integrate(conf, theme, tables, verbose)


def integrate(
    conf,
    theme,
    tables,
    verbose
):
    toUp = False
    noHistory = False
    step = "20" #a mettre dans fichier de conf ?

    integrate_.run(step, conf, theme, tables, toUp, noHistory, verbose)


def copy_data_in_working_tables(
    conf,
    theme,
    tables,
    countryCodes,
    verbose
):
    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])
    cursor = conn.cursor()

    validation_schema = conf['data']['themes'][theme]['v_schema']
    working_schema = conf['data']['themes'][theme]['w_schema']

    prefix = "_".join(sorted(countryCodes)) + "_"

    for tableName in tables:
        correctTableName = getTableName(validation_schema, prefix + tableName + conf['data']['working']['suffix']) + conf['data']['validation']['suffix']['correct']
        initTableName = getTableName(validation_schema, prefix + tableName + conf['data']['working']['suffix']) + conf['data']['validation']['suffix']['init']
        wTableName = getTableName(working_schema, tableName)+conf['data']['working']['suffix']
        wIdsTableName = getTableName(working_schema, tableName)+conf['data']['working']['ids_suffix']

        #--
        q1 = "DELETE FROM " + wTableName + ";"
        q1 += "INSERT INTO " + wTableName + " SELECT * FROM " + correctTableName + ";"
        
        print(u'query: {}'.format(q1), flush=True)
        try:
            cursor.execute(q1)
        except Exception as e:
            print(e)
            raise
        conn.commit()

        #--
        q2 = "DELETE FROM " + wIdsTableName + ";"
        q2 += "INSERT INTO " + wIdsTableName + " SELECT " + conf['data']['common_fields']['id'] + " FROM " + initTableName + ";"
        
        print(u'query: {}'.format(q2), flush=True)
        try:
            cursor.execute(q2)
        except Exception as e:
            print(e)
            raise
        conn.commit()

