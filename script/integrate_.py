import psycopg2
import create_table_

def getTableName(schema , tableName):
    return (schema+"." if schema else "") + tableName


def array_equal(arr1, arr2):
    if len(arr1) != len(arr2):
        return False

    for i in range(len(arr1)):
        if arr1[i] != arr2[i]:
            return False

    return True


def getIdRank(cursor, idField):
    colnames = [desc[0] for desc in cursor.description]
    rank = 0
    for col in colnames:
        if col == idField:
            return rank
        rank += 1
    return -1

def getNumRec(cursor, numRec):
    if len(numRec) == 0:
        # On récupère le numéro de réconciliation
        q = "SELECT nextval('seqnumrec');"
        try:
            cursor.execute(q)
        except psycopg2.Error as e:
            print(e)
            raise
        numRec.append(str(cursor.fetchall()[0][0]))
    return numRec

def integrate_table_(conf, cursor, currentNumrec, theme, table, wTableName, wIdsTableName, toUp, noHistory):
    #--
    id_field = conf['data']['common_fields']['id']
    # numrec_field = conf['data']['common_fields']['num_rec']
    theme_schema = conf['data']['themes'][theme]['schema']
    update_schema = conf['data']['themes'][theme]['u_schema']
    
    #--
    deleted = []
    integrated = []
    modified = []
    targetSchema = update_schema if toUp else theme_schema
    if toUp :
        table += conf['data']['update']['suffix']
    targetTableName = getTableName(targetSchema, table)

    # on recupere les noms des champs
    q0 = "SELECT string_agg(column_name,',') FROM information_schema.columns WHERE column_name not like '%gcms%' and table_name = '"+table+"' "+ ("AND table_schema = '"+targetSchema+"'") if targetSchema else ""
    try:
        cursor.execute(q0)
    except psycopg2.Error as e:
        print(e)
        raise
    _fields = cursor.fetchone()[0]

    # on parcourt les identifiants des objets extraits
    q1 = "SELECT "+id_field+" FROM "+wIdsTableName
    try:
        cursor.execute(q1)
    except psycopg2.Error as e:
        print(e)
        raise
    tuples = cursor.fetchall()
    ids_ = [ "'"+t[0]+"'" for t in tuples ]
    ids = [ t[0] for t in tuples ]

    bunch_size = 10000
    start = 0
    end = min(start+bunch_size,len(ids))
    count_d = 0
    count_m = 0

    if ids:
        while True:
            sub_ids_ = ids_[start : end]
            sub_ids = ids[start : end]

            # on recupere les objets dans la table de travail
            q2 = "SELECT "+_fields+" FROM "+wTableName
            q2 += " WHERE "+id_field+" IN ("+",".join(sub_ids_)+")"
            print("GETTING WORKING TABLE ITEMS :")
            print(q2[:500])
            try:
                cursor.execute(q2)
            except psycopg2.Error as e:
                print(e)
                raise

            w_tuples = cursor.fetchall()
            w_idRank = getIdRank(cursor, id_field)

            # on place les objets dans un dictionnaire
            w_objects = {}
            for w_t in w_tuples:
                # print(w_t)
                w_objects[w_t[w_idRank]] = w_t

            # on recupere les objets dans la table principale
            q2_bis = "SELECT "+_fields+" FROM "+targetTableName
            q2_bis += " WHERE "+id_field+" IN ("+",".join(sub_ids_)+")"
            print("GETTING MAIN TABLE ITEMS :")
            print(q2_bis[:500])
            try:
                cursor.execute(q2_bis)
            except psycopg2.Error as e:
                print(e)
                raise
            o_tuples = cursor.fetchall()
            o_idRank = getIdRank(cursor, id_field)

            # on place les objets dans un dictionnaire
            o_objects = {}
            for o_t in o_tuples:
                o_objects[o_t[o_idRank]] = o_t
            
            for i in range(len(sub_ids)):
                # objet supprime
                if sub_ids[i] not in w_objects:
                    count_d += 1
                    deleted.append(sub_ids_[i])

                # objet modifie
                elif not array_equal(w_objects[sub_ids[i]], o_objects[sub_ids[i]]):
                    count_m += 1
                    modified.append(sub_ids_[i])
                    if noHistory:
                        deleted.append(sub_ids_[i])
                        integrated.append(sub_ids_[i])

            if end == len(ids):
                break
            else:
                start = end
                end = min(start+bunch_size,len(ids))

    print("Nombre d'objets supprimés: "+str(count_d))
    print("Nombre d'objets modifiés: "+str(count_m))

    # on identifie les objets crees
    q3 = "SELECT a."+id_field+" FROM "+wTableName+" AS a"
    q3 += " LEFT JOIN "+wIdsTableName+" AS b ON a."+id_field+"=b."+id_field
    q3 += " WHERE b."+id_field+" IS NULL"
    try:
        cursor.execute(q3)
    except psycopg2.Error as e:
        print(e)
        raise
    new_tuples = cursor.fetchall()

    for nt in new_tuples:
        integrated.append("'" + nt[0] + "'")
    
    print("Nombre d'objets créés: "+str(len(new_tuples)))

    table_nb_obj = count_d+count_m+len(new_tuples)

    if table_nb_obj == 0 :
        return 0

    # pour éviter de d'incrémenter la séquence de numrec si la réconciliation est finalement abandonnée (pour cause de pas de modifs)
    getNumRec(cursor, currentNumrec)

    # on supprime les objets de la table
    if deleted:
        if noHistory:
            q7 = "DELETE FROM "+targetTableName
        else:
            # déplacement dans la table historique des objets avant mise à jour
            deleted_escaped = [ "'"+d+"'" for d in deleted ]
            deteled_id_list = "'("+",".join(deleted_escaped)+")'"

            # q6 = "SELECT ign_add_to_history_table('"+targetTableName+"', "+deteled_id_list+", "+currentNumrec+")"
            # print(q6[:500])
            # try:
            #     cursor.execute(q6)
            # except psycopg2.Error as e:
            #     print(e)
            #     raise

            #Preparation pour historisation
            # q7 = "UPDATE "+targetTableName+" SET gcms_detruit = true, "+numrec_field+" = "+currentNumrec+", end_lifespan_version = NOW(), gcms_date_destruction = NOW()"
            q7 = "UPDATE "+targetTableName+" SET gcms_detruit = true"
        
        q7 += " WHERE "+id_field+" IN ("+",".join(deleted)+")"
        print("ITEMS DELETION:")
        print(q7[:500])
        try:
            cursor.execute(q7)
        except psycopg2.Error as e:
            print(e)
            raise

    # on transfère les nouveaux objets de la table de travail vers la table
    if integrated:
        # _values = _fields.replace("begin_lifespan_version", "now()")
        # q8 = "INSERT INTO "+targetTableName+" ("+_fields+", "+numrec_field+", gcms_date_creation ) SELECT "+_values+","+currentNumrec+", NOW() FROM "+wTableName
        # q8 = "INSERT INTO "+targetTableName+" ("+_fields+") SELECT "+_values+" FROM "+wTableName
        q8 = "INSERT INTO "+targetTableName+" ("+_fields+") SELECT "+_fields+" FROM "+wTableName
        q8 += " WHERE "+id_field+" IN ("+",".join(integrated)+")"
        print("ITEMS INTEGRATION:")
        print(q8[:500])
        try:
            cursor.execute(q8)
        except psycopg2.Error as e:
            print(e)
            raise
    
    # on transfère les objets modifiés de la table de travail vers la table
    if modified and not(noHistory):
        # déplacement dans la table historique des objets avant mise à jour
        modified_escaped = [ "'"+m+"'" for m in modified ]
        id_list = "'("+",".join(modified_escaped)+")'"


        # q9 = "SELECT ign_add_to_history_table('"+targetTableName+"', "+id_list+", "+currentNumrec+")"
        # print(q9[:500])
        # try:
        #     cursor.execute(q9)
        # except psycopg2.Error as e:
        #     print(e)
        #     raise

        # mise à jour
        q10 = "UPDATE "+targetTableName+" SET "
        for field in _fields.split(","):
            value = wTableName+"."+field
            if field == id_field:
                continue
            # if field ==  "end_lifespan_version":
            #     value = "NULL"
            # elif field ==  "begin_lifespan_version":
            #     value = "NOW()"

            q10 += field+" = "+value+","

        # q10 += numrec_field+" = "+currentNumrec+","
        # q10 += "gcms_date_modification = NOW(),"
        # q10 += "gcms_date_destruction = NULL "
        q10 = q10[:-1] + " FROM "+wTableName+" WHERE "+targetTableName+"."+id_field+" = "+wTableName+"."+id_field+" AND "+targetTableName+"."+id_field+" IN ("+",".join(modified)+")"
        print("ITEMS MODIFICATION:")
        print(q10[:500])
        try:
            cursor.execute(q10)
        except psycopg2.Error as e:
            print(e)
            raise

    return table_nb_obj


def integrate_operation(
    conf,
    theme,
    tables,
    countryCodes,
    operation,
    suffix,
    toUp,
    noHistory,
    verbose
):
    """
    Ré-intègre les données depuis les tables de travail vers les tables sources correspondantes.

    Paramètres:
    conf (objet) : configuration
    theme (str) : thème à intégrer
    tables (array) : tables à ré-intégrer (si le tableau est vide ce sont toutes les tables du thème qui seront ré-intégrées)
    toUp (bool) : indique si les données doivent être intégrées dans la table de mise à jour et non dans la table source
    noHistory (bool) : indique si la table cible gère l'historique (dans une table historisée les objets supprimés sont tagués et non supprimés de la table)
    verbose (bool) : mode verbeux
    """
    
    if operation == 'au_matching':
        theme = 'au'
        if len(countryCodes) != 1:
            raise Exception('One and only one country allowed for operation: '+operation)
        tables = [ conf['data']['operation'][operation]['table_name_prefix'] + str(conf['data']['operation'][operation]['lowest_level'][countryCodes[0]]) ]
    elif operation == 'net_point_matching':
        #TODO a supprimer gestion des tables si tables=empty
        debug_pouet=True
    else:
        operation_ = 'matching' if operation == 'net_matching_validation' else operation
        if not tables:
            tables = conf['data']['operation'][operation_]['themes'][theme]['tables'].keys()

    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])
    conn.set_session(isolation_level='REPEATABLE READ')
    cursor = conn.cursor()

    if toUp :
        noHistory = True

    print("INTEGRATING...", flush=True)

    currentNumrec = []

    # On revert tout un theme si pas d argument sinon on revert les tables passees en argument
    if not tables :
        tables = conf['data']['themes'][theme]["tables"]

    # On integre tout un theme si pas d argument sinon on integre les tables passees en argument
    # on recupère tous les objet supprimes ou modifies
        # query = "SELECT id, w_modification_type"
    # on supprime les anciennes versions de ces objets de la table
    # on transfert les nouvelles versions des bjets supprimes, modifies ou créés de la table de travail vers la table

    validation_schema = conf['data']['themes'][theme]['v_schema']
    countryStr = "_".join(sorted(countryCodes)) + "_"
    suffix = "_" + countryStr + suffix
    rec_nb_obj = 0
    
    for tb in tables:
        wIdsTableName = ""
        wTableName = ""
        
        if operation == "net_matching_validation":
            wIdsTableName = getTableName(validation_schema, countryStr + tb) + conf['data']['validation']['suffix']['init']
            wTableName = getTableName(validation_schema, countryStr + tb) + conf['data']['validation']['suffix']['correct']
        else:
            wIdsTableName = create_table_.getWorkingIdsTablename(conf, theme, tb, suffix)
            wTableName = create_table_.getWorkingTablename(conf, theme, tb, suffix)

            if operation == "net_point_matching":
                prefix = "_" + conf['data']['operation']['net_matching']['themes'][theme]['tables'][tb]['final_step'] + "_"
                wTableName = prefix + wTableName
            
        table_nb_obj = integrate_table_(conf, cursor, currentNumrec, theme, tb, wTableName, wIdsTableName, toUp, noHistory)
        rec_nb_obj += table_nb_obj

    if rec_nb_obj == 0 :
        print("Aucune modification, abandon de la réconciliation", flush=True)
        return

    print("Enregistrement de la réconciliation "+currentNumrec[0] , flush=True)

    # python3 script/integrate.py -c config/conf_v6.json -T tn -t railway_link
    # python3 script/border_extract.py -c config/conf_v6.json -T tn -t railway_link -b ch -d 400 de
    # psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_hvlsp_v6_20250521 -f ./sql/db_init/hvlsp_init/HVLSP_3_GCMS_3_HISTORIQUE.sql
    # psql -h SMLPOPENMAPS2 -p 5432 -U postgres -d ome2_hvlsp_v6_20250521 -f ./sql/db_init/hvlsp_init/HVLSP_4_GCMS_4_OME2_ADD_HISTORY.sql
    # python3 script/revert.py -c config/conf_v6.json -T tn -t railway_link -n 114665892
    # ALTER TABLE tn.railway_link ENABLE TRIGGER ign_gcms_history_trigger;

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
            +currentNumrec[0]+',' \
            "-1," \
            "'"+",".join(tables)+"'," \
            "NULL," \
            "NULL," \
            "'MAJ'," \
            "NULL," \
            "ST_GeomFromText('MultiPolygon(((9 9, 9 9, 9 9, 9 9)))')," \
            +str(rec_nb_obj)+"," \
            "NULL," \
            "NULL" \
        ")"

    try:
        cursor.execute(q10)
    except psycopg2.Error as e:
        print(e)
        raise

    conn.commit()
    cursor.close()
    conn.close()

# def copy_data_in_working_tables(
#     conf,
#     theme,
#     tables,
#     countryCodes,
#     operation,
#     suffix,
#     verbose
# ):
#     conn = psycopg2.connect(    user = conf['db']['user'],
#                                 password = conf['db']['pwd'],
#                                 host = conf['db']['host'],
#                                 port = conf['db']['port'],
#                                 database = conf['db']['name'])
#     cursor = conn.cursor()

#     validation_schema = conf['data']['themes'][theme]['v_schema']
#     working_schema = conf['data']['themes'][theme]['w_schema']

#     countryStr = "_".join(sorted(countryCodes)) + "_"

#     for tableName in tables:
#         initTableName = ""
#         finalTableName = ""

#         if operation in ["area_matching", "au_matching", "net_point_matching"]:
#             finalStep = conf['data']['operation'][operation]["final_step"] if "final_step" in conf['data']['operation'][operation] else conf['data']['operation'][operation]['themes'][theme]['tables'][tableName]["final_step"]
#             initTableName = getTableName(working_schema, tableName) + conf['data']['working']['suffix'] + "_" + countryStr + suffix
#             finalTableName = "_" + str(finalStep) + "_" + initTableName

#         elif operation == "net_matching_validation":
#             finalTableName = getTableName(validation_schema, countryStr + tableName) + conf['data']['validation']['suffix']['correct']
#             initTableName = getTableName(validation_schema, countryStr + tableName) + conf['data']['validation']['suffix']['init']

#         else:
#             print("unknown operation '"+operation+"'")
#             raise

#         wTableName = getTableName(working_schema, tableName) + conf['data']['working']['suffix']
#         wIdsTableName = getTableName(working_schema, tableName) + conf['data']['working']['ids_suffix']

#         #--
#         q1 = "DELETE FROM " + wTableName + ";"
#         q1 += "INSERT INTO " + wTableName + " SELECT * FROM " + finalTableName + ";"
        
#         print(u'query: {}'.format(q1), flush=True)
#         try:
#             cursor.execute(q1)
#         except psycopg2.Error as e:
#             print(e)
#             raise
#         conn.commit()

#         #--
#         q2 = "DELETE FROM " + wIdsTableName + ";"
#         q2 += "INSERT INTO " + wIdsTableName + " SELECT " + conf['data']['common_fields']['id'] + " FROM " + initTableName + ";"
        
#         print(u'query: {}'.format(q2), flush=True)
#         try:
#             cursor.execute(q2)
#         except psycopg2.Error as e:
#             print(e)
#             raise
#         conn.commit()
