import sys
from subprocess import call
import utils
import psycopg2
import border_extract_with_neighbors_
import integrate_
import create_table_


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName

def clean(
    conf,
    theme,
    tables,
    countryCodes,
    suffix,
    verbose
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
        landmask_statement = "SELECT ST_Union(ARRAY(SELECT geom FROM "+ getTableName(conf['landmask']['schema'], conf['landmask']['table']) +" WHERE "+conf['landmask']["fields"]["country"]+"='"+c+"' AND NOT gcms_detruit))"

        if not tables:
            tables = conf['data']['themes'][theme]['tables']

        for tb in tables:
            query = "DELETE FROM "+create_table_.getWorkingTablename(conf, theme, tb, suffix)
            query += " WHERE "+conf['data']['common_fields']['country']+"='"+c+"'"
            query += " AND ST_Distance(("+landmask_statement+"), geom) > "+str(distance)

            print(u'query: {}'.format(query), flush=True)
            try:
                cursor.execute(query)
            except psycopg2.Error as e:
                print(e)
                raise
            conn.commit()

    cursor.close()
    conn.close()


def extract_data(
    conf,
    mcd,
    theme,
    tables,
    country,
    borders,
    inDispute,
    all,
    suffix,
    verbose
):    
    distance = conf['data']['operation']['cleaning']['themes'][theme]['extraction_distance']['default']
    if country in conf['data']['operation']['cleaning']['themes'][theme]['extraction_distance']:
        distance = conf['data']['operation']['cleaning']['themes'][theme]['extraction_distance'][country]

    border_extract_with_neighbors_.run(conf, mcd, theme, tables, distance, country, borders, inDispute, all, suffix, verbose)

def run(
    conf,
    mcd,
    theme, 
    tables, 
    country, 
    borders, 
    inDispute, 
    all,
    suffix,
    verbose
):
    """
    Supprime les objets distants de leur pays.

    Paramètres:
    conf (objet) : configuration
    theme (str) : thème à traiter
    tables (array) : tables à traiter (si le tableau est vide ce sont toutes les tables du thème qui seront traitées)
    country (str) : code du pays à traiter
    borders (array) : codes des pays frontaliers (à préciser dans le cas où l'on ne souhaite pas nettoyer l'ensemble des frontières du pays à traiter)
    inDispute (bool) : indique si l'on traite les zones 'in dipute'
    verbose (bool) : mode verbeux
    """
    print("CLEANING...", flush=True)

    if not tables:
        tables = conf['data']['themes'][theme]['tables']

    suffix = "_" + country + "_" + suffix

    #--
    extract_data(conf, mcd, theme, tables, country, borders, inDispute, all, suffix, verbose)

    #-- 
    clean(conf, theme, tables, country, suffix, verbose)

    #--
    toUp = False
    noHistory = False
    integrate_.integrate_operation(conf, theme, tables, [country], "cleaning", suffix, toUp, noHistory, verbose)


