import sys
from subprocess import call
import utils
import psycopg2
import border_extract_
import integrate_


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName

def getWorkingTableName(schema, tableName, w_suffix):
    return (schema+"." if schema else "") + tableName + w_suffix

def clean(
    conf, theme, tables, countryCodes, verbose
):  
    """
    Supprime les objets distants de leur pays.

    Paramètres:
    conf (objet) : configuration
    theme (str) : thème à nettoyer
    tables (array) : tables à nettoyer (si le tableau est vide ce sont toutes les tables du thème qui seront nettoyées
    countryCodes (array) : codes des pays à nettoyer
    verbose (bool) : mode verbeux
    """

    conn = psycopg2.connect(  user = conf['db']['user'],
                                    password = conf['db']['pwd'],
                                    host = conf['db']['host'],
                                    port = conf['db']['port'],
                                    database = conf['db']['name'])
    cursor = conn.cursor()

    print("CLEANING...", flush=True)

    distance = conf['data']['operation']['cleaning']['distance'] 

    for c in countryCodes:
        landmask_statement = "SELECT ST_Union(ARRAY(SELECT geom FROM "+ getTableName(conf['landmask']['schema'], conf['landmask']['table']) +" WHERE "+conf['landmask']["fields"]["country"]+"='"+c+"'))"

        w_schema = conf['data']['themes'][theme]['w_schema']
        w_suffix = conf['data']['working']['suffix']
        if not tables:
            tables = conf['data']['themes'][theme]['tables']

        for tb in tables:
            query = "DELETE FROM "+getWorkingTableName(w_schema, tb, w_suffix)
            query += " WHERE "+conf['data']['common_fields']['country']+"='"+c+"'"
            query += " AND ST_Distance(("+landmask_statement+"), geom) > "+str(distance)

            print(u'query: {}'.format(query), flush=True)
            try:
                cursor.execute(query)
            except Exception as e:
                print(e)
                raise
            conn.commit()

    cursor.close()
    conn.close()


def extract_data(
    conf,
    theme,
    tables,
    countryCodes,
    borders,
    inDispute,
    all,
    verbose
):    
    fromUp = False
    reset = True

    for country in countryCodes:
        if all :
            inDispute = True;
            if country in conf['data']['operation']['cleaning']['neighbors']:
                borders = conf['data']['operation']['cleaning']['neighbors'][country]
            else :
                print("[extract_data] Error : neighbors not defined for country : "+ country)
                raise

        distance = conf['data']['operation']['cleaning']['themes'][theme]['extraction_distance']['default']
        if country in conf['data']['operation']['cleaning']['themes'][theme]['extraction_distance']:
            distance = conf['data']['operation']['cleaning']['themes'][theme]['extraction_distance'][country]

        if inDispute:
            boundaryType = 'international'
            border = False
            border_extract_.run(conf, theme, tables, distance, country, border, boundaryType, fromUp, reset, verbose)
            reset = False

        boundaryType = None
        if country in conf['data']['operation']['cleaning']['neighbors']:
            allNeighbors = conf['data']['operation']['cleaning']['neighbors'][country]
            orderedBorders = [b for b in allNeighbors if b in borders]
            borders = orderedBorders

        for border in borders:
            border_extract_.run(conf, theme, tables, distance, country, border, boundaryType, fromUp, reset, verbose)
            reset = False


def integrate(
    conf,
    theme,
    tables,
    verbose
):
    toUp = False
    noHistory = False
    step = "10" #a mettre dans fichier de conf ?

    integrate_.run(step, conf, theme, tables, toUp, noHistory, verbose)


def run(
    conf, 
    theme, 
    tables, 
    countryCodes, 
    borders, 
    inDispute, 
    all, 
    verbose
):
    """
    Supprime les objets distants de leur pays.

    Paramètres:
    conf (objet) : configuration
    theme (str) : thème à traiter
    tables (array) : tables à traiter (si le tableau est vide ce sont toutes les tables du thème qui seront traitées)
    countryCodes (array) : codes des pays à traiter
    borders (array) : codes des pays frontaliers (à préciser dans le cas où l'on ne souhaite pas nettoyer l'ensemble des frontières du pays à traiter)
    inDispute (bool) : indique si l'on traite les zones 'in dipute'
    verbose (bool) : mode verbeux
    """
    print("CLEANING...", flush=True)

    if not tables:
        tables = conf['data']['themes'][theme]['tables']

    #--
    extract_data(conf, theme, tables, countryCodes, borders, inDispute, all, verbose)

    #-- 
    clean(conf, theme, tables, countryCodes, verbose)

    #--
    integrate(conf, theme, tables, verbose)





