import psycopg2


def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName

def getNumRec(cursor, numRec):
    if numRec < 0:
        # On récupère le numéro de réconciliation
        q = "SELECT nextval('seqnumrec');"
        try:
            cursor.execute(q)
        except psycopg2.Error as e:
            print(e)
            raise
        numRec = str(cursor.fetchall()[0][0])
    return numRec


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
    only = isinstance(only, bool) and only

    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])

    conn.set_session(isolation_level='REPEATABLE READ')
    cursor = conn.cursor()

    print("REVERTING...", flush=True)

    # On revert tout un theme si pas d argument sinon on revert les tables passees en argument
    if not tables :
        tables = conf['border-extraction']['data']['themes'][theme]

    id_field = conf['data']['common_fields']['id']
    numrec_field = conf['data']['common_fields']['num_rec']
    theme_schema = conf['data']['themes'][theme]['schema']
    history_schema = conf['data']['themes'][theme]['h_schema']
    numrec_field = conf['data']['common_fields']['num_rec']
    numrec_field_rec = conf['data']['reconciliation']['fields']['num_rec']
    numrecmodif_field = conf['data']['history']['fields']['num_rec_modif']
    ordrefinevol_field = conf['data']['reconciliation']['fields']['ordre_fin_evol']
    recTableName = getTableName(conf['data']['reconciliation']['schema'], conf['data']['reconciliation']['table'])

    # recuperation des reconciliation à traiter
    orderedNumrecs = None
    if only :
        orderedNumrecs = [ numrecToUndo ]
    else:
        # on recupère toutes les reconciliations dont l'ordre_fin_evol est supérieure à l'ordre_fin_evol du numrec cible
        ordrefinevolStatement = "(SELECT "+ordrefinevol_field+" FROM "+recTableName+" WHERE "+numrec_field_rec+"="+numrecToUndo+")"
        
        q0 = "SELECT "+numrec_field_rec+", "+ordrefinevol_field+" FROM "+recTableName+" WHERE "+ordrefinevol_field+">="+ordrefinevolStatement+" ORDER BY "+ordrefinevol_field+" DESC"
        print(u'q0: {}'.format(q0[:500]), flush=True)
        try:
            cursor.execute(q0)
        except Exception as e:
            print(e)
            raise
        orderedNumrecs = [ t[0] for t in cursor.fetchall() ]

    #--
    for numrec in orderedNumrecs:

        currentNumrec = -1
        rec_nb_obj = 0

        for tb in tables:

            tableName = getTableName(theme_schema, tb)
            hTableName = getTableName(history_schema, tb)+conf['data']['history']['suffix']
            
            # on fait la mise à jour inverse pour les objets présent dans l'historique
            ## on liste les objets modifiés (mises à jour et suppressions)
            # q2 = "SELECT "+id_field+" FROM "+hTableName+" WHERE "+numrecmodif_field+" = "+str(numrec)+" AND gcms_detruit = false"
            q2 = "SELECT "+id_field+" FROM "+hTableName+" WHERE "+numrecmodif_field+" = "+str(numrec)
            print(u'q2: {}'.format(q2[:500]), flush=True)
            try:
                cursor.execute(q2)
            except psycopg2.Error as e:
                print(e)
                raise
            tuples_m = cursor.fetchall()
            ids_m_quoted = [ "'"+t[0]+"'" for t in tuples_m ]

            ## on liste les objets ressuscités
            # q3 = "SELECT "+id_field+" FROM "+hTableName+" WHERE "+numrecmodif_field+" = "+str(numrec)+" AND gcms_detruit = true"
            # print(u'q2: {}'.format(q3[:500]), flush=True)
            # try:
            #     cursor.execute(q3)
            # except psycopg2.Error as e:
            #     print(e)
            #     raise
            # tuples_r = cursor.fetchall()
            # ids_r_quoted = [ "'"+t[0]+"'" for t in tuples_r ]

            ## on liste les objets créés
            q4 = "SELECT "+id_field+" FROM "+tableName+" WHERE gcms_detruit = false AND gcms_date_modification is NULL AND "+numrec_field+" = "+str(numrec)
            q4 += " UNION SELECT "+id_field+" FROM "+hTableName+" WHERE gcms_detruit = false AND gcms_date_modification is NULL AND "+numrec_field+" = "+str(numrec)
            print(u'q4: {}'.format(q4[:500]), flush=True)
            try:
                cursor.execute(q4)
            except psycopg2.Error as e:
                print(e)
                raise
            tuples_c = cursor.fetchall()
            ids_c_quoted = [ "'"+t[0]+"'" for t in tuples_c ]


            # déplacement dans la table historique des objets avant mise à jour
            # ids_mrc_quoted = ids_m_quoted + ids_r_quoted + ids_c_quoted
            ids_mrc_quoted = ids_m_quoted + ids_c_quoted

            if not ids_mrc_quoted :
                continue

            currentNumrec = getNumRec(cursor, currentNumrec)

            ids_mrc_quoted_escaped = [ "'"+t+"'" for t in ids_mrc_quoted ]
            ids_mrc_sql_list = "'("+",".join(ids_mrc_quoted_escaped)+")'"

            # q5 = "SELECT ign_add_to_history_table('"+tableName+"', "+ids_mrc_sql_list+", "+currentNumrec+")"
            # print(u'q5: {}'.format(q5[:500]), flush=True)
            # try:
            #     cursor.execute(q5)
            # except psycopg2.Error as e:
            #     print(e)
            #     raise

            # mise à jour
            ## on recupere les noms des champs
            q6 = "SELECT string_agg(column_name,',') FROM information_schema.columns WHERE table_name = '"+tb+"' "+ ("AND table_schema = '"+theme_schema+"'") if theme_schema else ""
            print(u'q6: {}'.format(q6[:500]), flush=True)
            try:
                cursor.execute(q6)
            except psycopg2.Error as e:
                print(e)
                raise
            _fields = cursor.fetchone()[0]

            ## mise à jour des objets modifié
            if ids_m_quoted :
                q7 = "UPDATE "+tableName+" SET "
                for field in _fields.split(","):
                    value = hTableName+"."+field
                    if field == id_field:
                        continue
                    if field == numrec_field:
                        continue
                    if field ==  "begin_lifespan_version":
                        continue
                    if field ==  "end_lifespan_version":
                        continue
                    if "gcms_date" in field :
                        continue
                    # if field ==  "begin_lifespan_version":
                    #     value = "NOW()"
                    # elif field ==  "gcms_date_modification":
                    #     value = "NOW()"
                    # ## normalement les champs suivants sont forcement nuls
                    # # elif field ==  "end_lifespan_version":
                    # #     value = "NULL"
                    # # elif field ==  "gcms_date_destruction":
                    # #     value = "NULL"
                    
                    q7 += field+" = "+value+","

                # q7 += numrec_field+" = "+currentNumrec
                # q7 += " FROM "+hTableName+" WHERE "+tableName+"."+id_field+" = "+hTableName+"."+id_field+" AND "+tableName+"."+id_field+" IN ("+",".join(ids_m_quoted)+") AND "+numrecmodif_field+" = "+str(numrec)
                q7 = q7[:-1] + " FROM "+hTableName+" WHERE "+tableName+"."+id_field+" = "+hTableName+"."+id_field+" AND "+tableName+"."+id_field+" IN ("+",".join(ids_m_quoted)+") AND "+numrecmodif_field+" = "+str(numrec)
                print(u'q7: {}'.format(q7[:500]), flush=True)
                try:
                    cursor.execute(q7)
                except psycopg2.Error as e:
                    print(e)
                    raise

            ## mise à jour des objets ressuscités à tuer
            # if ids_r_quoted :
            #     q8 = "UPDATE "+tableName+" SET "
            #     for field in _fields.split(","):
            #         value = hTableName+"."+field
            #         if field == id_field:
            #             continue
            #         if field == numrec_field:
            #             continue
            #         if field ==  "end_lifespan_version":
            #             value = "NOW()"
            #         elif field ==  "gcms_date_destruction":
            #             value = "NOW()"
            #         elif field ==  "begin_lifespan_version":
            #             continue
            #         elif field ==  "gcms_date_modification":
            #             continue
                    
            #         q8 += field+" = "+value+","

            #     q8 += numrec_field+" = "+currentNumrec
            #     q8 += " FROM "+hTableName+" WHERE "+tableName+"."+id_field+" = "+hTableName+"."+id_field+" AND "+tableName+"."+id_field+" IN ("+",".join(ids_r_quoted)+") AND "+hTableName+"."+numrecmodif_field+" = "+str(numrec)
            #     print(u'q8: {}'.format(q8[:500]), flush=True)
            #     try:
            #         cursor.execute(q8)
            #     except psycopg2.Error as e:
            #         print(e)
                    # raise

            ## mise à jour des objets créés à tuer
            if ids_c_quoted :
                # q9 = "UPDATE "+tableName+" SET gcms_detruit = true, "+numrec_field+" = "+currentNumrec+", end_lifespan_version = NOW(), gcms_date_destruction = NOW()"
                q9 = "UPDATE "+tableName+" SET gcms_detruit = true"
                q9 += " WHERE "+id_field+" IN ("+",".join(ids_c_quoted)+")"
                print(u'q9: {}'.format(q9[:500]), flush=True)
                try:
                    cursor.execute(q9)
                except psycopg2.Error as e:
                    print(e)
                    raise

            rec_nb_obj += len(ids_mrc_quoted)

        if rec_nb_obj == 0 :
            print("Aucune modification, abandon de la réconciliation inverse", flush=True)
            return
        
        print("Enregistrement de la réconciliation inverse "+currentNumrec , flush=True)

        # python3 script/integrate.py -c config/conf_v6.json -T tn -t railway_link
        # python3 script/border_extract.py -c config/conf_v6.json -T tn -t railway_link -b ch -d 400 de
        # psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_hvlsp_v6_20250521 -f ./sql/db_init/hvlsp_init/HVLSP_3_GCMS_3_HISTORIQUE.sql
        # psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_hvlsp_v6_20250521 -f ./sql/db_init/hvlsp_init/HVLSP_4_GCMS_4_OME2_ADD_HISTORY.sql
        # python3 script/revert.py -c config/conf_v6.json -T tn -t railway_link -n 114665892

        # on enregistre l'objet reconciliation
            #numéro de réconciliation
            #numéro de client
            #classes impactées
            #nom de la zone de reconciliation (ex: be#fr ?)
            #changement zr
            #nature de l'operation
            #commentaire
            #géométried de la zone de réconciliation
            #nombre d'objets
            #operateur zr (user)
            #groupe/profil
            #source --> DEFAULT NULL
        q10 = "SELECT ign_gcms_finalize_transaction(" \
                +currentNumrec+',' \
                "-1," \
                "'"+",".join(tables)+"'," \
                "NULL," \
                "NULL," \
                "'UNDO'," \
                "'revert reconciliation "+str(numrec)+"'," \
                "ST_GeomFromText('MultiPolygon(((9 9, 9 9, 9 9, 9 9)))')," \
                +str(rec_nb_obj)+"," \
                "NULL," \
                "NULL" \
            ")"
        print(u'q10: {}'.format(q10[:500]), flush=True)
        try:
            cursor.execute(q10)
        except psycopg2.Error as e:
            print(e)
            raise

        conn.commit()
    cursor.close()
    conn.close()
