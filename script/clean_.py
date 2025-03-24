import sys
from subprocess import call
import utils
import psycopg2


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName


def run(
    conf, dist, theme, tables, countryCodes, verbose
):  
    """
    Supprime les objets distants de leur pays.

    Paramètres:
    conf (objet) : configuration
    dist (int) : distance d'éloignement au delà de laquelle les objets sont supprimés
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

    for c in countryCodes:
        landmask_statement = "SELECT ST_Union(ARRAY(SELECT geom FROM "+ getTableName(conf['landmask']['schema'], conf['landmask']['table']) +" WHERE "+conf['landmask']["fields"]["country"]+"='"+c+"'))"

        w_schema = conf['data']['themes'][theme]['w_schema']
        if not tables:
            tables = conf['data']['themes'][theme]['tables']

        for tb in tables:
            query = "DELETE FROM "+getTableName(w_schema, tb)
            query += " WHERE "+conf['data']['common_fields']['country']+"='"+c+"'"
            # query += " AND NOT ST_intersects(("+landmask_statement+"), geom)"
            query += " AND ST_Distance(("+landmask_statement+"), geom) > "+dist

            print(u'query: {}'.format(query), flush=True)
            try:
                cursor.execute(query)
            except Exception as e:
                print(e)
                raise
            conn.commit()

    cursor.close()
    conn.close()