import psycopg2
import integrate_


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName


def run(
    step,
    conf,
    theme,
    tables,
    suffix,
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
    step,
    conf,
    theme,
    tables,
    verbose
):
    to_up = False
    nohistory = False
    step = "20" #a mettre dans fichier de conf ?

    integrate_.run(conf, theme, tables, to_up, nohistory, verbose)


def copy_data_in_working_tables(
    conf,
    theme,
    tables,
    countryCodes,
    verbose
):
    validation_schema = conf['data']['operation']['validation']['schema']
    working_schema = conf['data']['themes'][theme]['w_schema']

    prefix = "_".join(sorted(countryCodes)) + "_"

    for tableName in tables:
        correctTableName = getTableName(target_schema, prefix + tableName) + conf['data']['operation'][operation]['suffix']['correct']
        initTableName = getTableName(target_schema, prefix + tableName) + conf['data']['operation'][operation]['suffix']['init']
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
        q2 += "INSERT INTO " + wIdsTableName + " SELECT " + conf['data']['common']['id'] + " FROM " + initTableName + ";"
        
        print(u'query: {}'.format(q2), flush=True)
        try:
            cursor.execute(q2)
        except Exception as e:
            print(e)
            raise
        conn.commit()

