import psycopg2


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName


def run(
    step, conf, theme, tables, verbose
):
    """
    Effectue un roll-bak jusqu'au numéro d'étape voulu.

    Paramètres:
    step (int) : numéro d'étape jusqu'à laquelle on veut réaliser le roll-back (cette étape est inclue)
    conf (objet) : configuration
    theme (str) : thème sur lequel réaliser le roll-back
    tables (array) : tables sur lesquelles le roll-back doit être réalisé
    verbose (bool) : mode verbeux
    """

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
    history_schema = conf['data']['themes'][theme]['h_schema']
    step_field = conf['data']['common_fields']['step']
    modif_step_field = conf['data']['history']['fields']['modification_step']

    for tb in tables:
        tableName = getTableName(theme_schema, tb)
        hTableName = getTableName(history_schema, tb)+conf['data']['history']['suffix']

        # on recupère tous les steps supérieur ou égal au step cible
        q0 = "SELECT DISTINCT("+step_field+") FROM "+tableName+" WHERE "+step_field+">="+step
        try:
            cursor.execute(q0)
        except Exception as e:
            print(e)
            raise
        steps0 = [ t[0] for t in cursor.fetchall() ]

        q0_bis = "SELECT DISTINCT("+modif_step_field+") FROM "+hTableName+" WHERE "+modif_step_field+">="+step
        try:
            cursor.execute(q0_bis)
        except Exception as e:
            print(e)
            raise
        steps0_bis = [ t[0] for t in cursor.fetchall() ]

        orderedSteps = sorted(set(steps0+steps0_bis), reverse=True)

        for step in orderedSteps:
            # on supprime tous les objets du step present dans la table
            q = "DELETE FROM "+tableName+" WHERE "+step_field+"="+str(step)
            print(u'query: {}'.format(q), flush=True)
            try:
                cursor.execute(q)
            except Exception as e:
                print(e)
                raise
            conn.commit()

            # on transfert tous les objets du step qui sont dans la table historique vers la table
            # on recupère tous les noms de champs de la table
            q1 = "SELECT string_agg(column_name,',') FROM information_schema.columns WHERE table_name = '"+tb+"' "+ ("AND table_schema = '"+theme_schema+"'") if theme_schema else ""
            try:
                cursor.execute(q1)
            except Exception as e:
                print(e)
                raise
            fields = cursor.fetchone()[0]

            q2 = "INSERT INTO "+tableName+" ("+fields+") SELECT "+fields+" FROM "+hTableName
            q2 += " WHERE "+modif_step_field+"="+str(step)
            print(u'query: {}'.format(q2), flush=True)
            try:
                cursor.execute(q2)
            except Exception as e:
                print(e)
                raise
            conn.commit()

            # on supprime tous les objets du step de la table historique
            q3 = "DELETE FROM "+hTableName+" WHERE "+modif_step_field+"="+str(step)
            print(u'query: {}'.format(q3), flush=True)
            try:
                cursor.execute(q3)
            except Exception as e:
                print(e)
                raise
            conn.commit()

    cursor.close()
    conn.close()