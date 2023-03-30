import sys
from subprocess import call
import psycopg2


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName

def run(
    step, conf, theme, tables, verbose
):
    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])
    cursor = conn.cursor()

    print("REVERTING...", flush=True)

    # On revert tout un theme si pas d argument sinon on revert les tables passees en argument
    if not tables :
        tables = conf['border-extraction']['data']['themes'][theme]

    theme_schema = conf['data']['themes'][theme]['schema']
    step_field = conf['data']['step_field']
    for tb in tables:

        # on supprime tous les objet du step present dans la table
        # TODO supprimer tout ce qui est superieur ou egal au step
        q = "DELETE FROM "+getTableName(theme_schema, tb)+" WHERE "+step_field+"='"+step+"'"
        print(u'query: {}'.format(q), flush=True)
        cursor.execute(q)
        conn.commit()

        # on transfert tous les objets du step qui sont dans la table historique vers la table
        # on recupère tous les noms de champs de la table
        q1 = "SELECT string_agg(column_name,',') FROM information_schema.columns WHERE table_name = '"+tb+"' "+ ("AND table_schema = '"+theme_schema+"'") if theme_schema else ""
        cursor.execute(q1)
        fields = cursor.fetchone()[0]

        # TODO transferer tout ce qui est superieur ou egal au step
        # Si plusieurs versions d'un meme objet transferer le plus ancien
        # TODO ajouter un champ w_step_h dans la table historique
        q2 = "INSERT INTO "+getTableName(theme_schema, tb)+" ("+fields+") SELECT "+fields+" FROM "+getTableName(theme_schema, tb)+"_wh"
        q2 += " WHERE "+step_field+"='"+step+"'"
        print(u'query: {}'.format(q2), flush=True)
        cursor.execute(q2)
        conn.commit()

        # on supprime tous les objets du step de la table historique
        # TODO supprimer tout ce qui est superieur ou egal au step
        # TODO ajouter un champ w_step_h dans la table historique
        q3 = "DELETE FROM "+getTableName(theme_schema, tb)+"_wh WHERE "+step_field+"='"+step+"'"
        print(u'query: {}'.format(q3), flush=True)
        cursor.execute(q3)
        conn.commit()

    cursor.close()
    conn.close()