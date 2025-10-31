import psycopg2


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName


def run(
    numrecToUndo, conf, theme, tables, only, verbose
):
    """
    Effectue un roll-bak jusqu'au numéro d'étape voulu.

    Paramètres:
    numrecToUndo (int) : réconciliation à "dé-jouer"
    conf (objet) : configuration
    theme (str) : thème sur lequel réaliser le roll-back
    tables (array) : tables sur lesquelles le roll-back doit être réalisé
    only (bool) : indique si seule la réconciliation indiquée doit être annulée ou si toutes les réconciliations postérieures doivent l'être également
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
    numrec_field = conf['data']['common_fields']['num_rec']
    numrec_field_rec = conf['data']['reconciliation']['fields']['num_rec']
    numrecmodif_field = conf['data']['history']['fields']['num_rec_modif']
    ordrefinevol_field = conf['data']['reconciliation']['fields']['ordre_fin_evol']
    recTableName = getTableName(conf['data']['reconciliation']['schema'], conf['data']['reconciliation']['table'])

    # recuperation des reconciliation à traiter
    orderedNumrecs = None
    if isinstance(only, bool) and only :
        orderedNumrecs = [ numrecToUndo ]
    else:
        # on recupère toutes les reconciliations dont l'ordre_fin_evol est supérieure à l'ordre_fin_evol du numrec cible
        ordrefinevolStatement = "(SELECT "+ordrefinevol_field+" FROM "+recTableName+" WHERE "+numrec_field_rec+"="+numrecToUndo+")"

        q0 = "SELECT "+numrec_field_rec+", "+ordrefinevol_field+" FROM "+recTableName+" WHERE "+ordrefinevol_field+">="+ordrefinevolStatement+" ORDER BY "+ordrefinevol_field+" DESC"
        print(u'query: {}'.format(q0), flush=True)
        try:
            cursor.execute(q0)
        except Exception as e:
            print(e)
            raise
        orderedNumrecs = [ t[0] for t in cursor.fetchall() ]

    #--
    for numrec in orderedNumrecs:
        for tb in tables:
            tableName = getTableName(theme_schema, tb)
            hTableName = getTableName(history_schema, tb)+conf['data']['history']['suffix']

            # desactivation de l'historique
            try:
                cursor.execute("SELECT ign_gcms_disable_history_triggers('"+tableName+"', true)")
            except Exception as e:
                print(e)
                raise

            # on supprime tous les objets du numrec present dans la table
            q0 = "DELETE FROM "+tableName+" WHERE "+numrec_field+"="+str(numrec)
            print(u'q0: {}'.format(q0), flush=True)
            try:
                cursor.execute(q0)
            except Exception as e:
                print(e)
                raise

            # on transfert tous les objets du numrec qui sont dans la table historique vers la table
            # on recupère tous les noms de champs de la table
            q1 = "SELECT string_agg(column_name,',') FROM information_schema.columns WHERE table_name = '"+tb+"' "+ ("AND table_schema = '"+theme_schema+"'") if theme_schema else ""
            print(u'q1: {}'.format(q1), flush=True)
            try:
                cursor.execute(q1)
            except Exception as e:
                print(e)
                raise
            fields = cursor.fetchone()[0]

            q2 = "INSERT INTO "+tableName+" ("+fields+") SELECT "+fields+" FROM "+hTableName
            q2 += " WHERE "+numrecmodif_field+"="+str(numrec)
            print(u'q2: {}'.format(q2), flush=True)
            try:
                cursor.execute(q2)
            except Exception as e:
                print(e)
                raise

            # on supprime tous les objets du numrec de la table historique
            q3 = "DELETE FROM "+hTableName+" WHERE "+numrecmodif_field+"="+str(numrec)
            print(u'q3: {}'.format(q3), flush=True)
            try:
                cursor.execute(q3)
            except Exception as e:
                print(e)
                raise

            # on supprime la réconciliation
            q4 = "DELETE FROM "+recTableName+" WHERE "+numrec_field_rec+"="+str(numrec)
            print(u'q4: {}'.format(q4), flush=True)
            try:
                cursor.execute(q4)
            except Exception as e:
                print(e)
                raise

            # re-activation de l'historique
            try:
                cursor.execute("SELECT ign_gcms_disable_history_triggers('"+tableName+"', false)")
            except Exception as e:
                print(e)
                raise
            
    conn.commit()
    cursor.close()
    conn.close()