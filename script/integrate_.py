import psycopg2


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


def run(
    step, conf, theme, tables, to_up, nohistory, verbose
):
    """
    Ré-intègre les données depuis les tables de travail vers les tables sources correspondantes.

    Paramètres:
    step (int) : numéro d'étape
    conf (objet) : configuration
    theme (str) : thème à intégrer
    tables (array) : tables à ré-intégrer (si le tableau est vide ce sont toutes les tables du thème qui seront ré-intégrées)
    to_up (bool) : indique si les données doivent être intégrées dans la table de mise à jour et non dans la table source
    nohistory (bool) : indique si la table cible gère l'historique (dans une table historisée les objets supprimés sont tagués et non supprimés de la table)
    verbose (bool) : mode verbeux
    """

    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])
    cursor = conn.cursor()

    if to_up :
        nohistory = True

    print("INTEGRATING...", flush=True)

    # On revert tout un theme si pas d argument sinon on revert les tables passees en argument
    if not tables :
        tables = conf['data']['themes'][theme]["tables"]

    # On integre tout un theme si pas d argument sinon on integre les tables passees en argument
    # on recupère tous les objet supprimes ou modifies
        # query = "SELECT id, w_modification_type"
    # on transfert les anciennes versions de ces objets vers la table historique (+numero de step)
        # if w_modification_type == "D"
        # if w_modification_type == "M"
    # on supprime les anciennes versions de ces objets de la table
    # on transfert les nouvelles versions des bjets supprimes, modifies ou créés de la table de travail vers la table (+numero de step)

    deleted = []
    historized_d = []
    historized_m = []
    integrated = []
    modified = []
    id_field = conf['data']['common_fields']['id']
    working_schema = conf['data']['themes'][theme]['w_schema']
    theme_schema = conf['data']['themes'][theme]['schema']
    update_schema = conf['data']['themes'][theme]['u_schema']
    history_schema = conf['data']['themes'][theme]['h_schema']
    modification_type_field = conf['data']['history']['fields']['modification_type']
    modification_step_field = conf['data']['history']['fields']['modification_step']
    step_field = conf['data']['common_fields']['step']

    for tb in tables:
        wIdsTableName = getTableName(working_schema, tb)+conf['data']['working']['ids_suffix']
        wTableName = getTableName(working_schema, tb)+conf['data']['working']['suffix']
        hTableName = getTableName(history_schema, tb)+conf['data']['history']['suffix']
        targetSchema = update_schema if to_up else theme_schema
        if to_up :
            tb += conf['data']['update']['suffix']
        tableName = getTableName(targetSchema, tb)

        # on recupere les noms des champs
        q0 = "SELECT string_agg(column_name,',') FROM information_schema.columns WHERE column_name not like '%gcms%' and table_name = '"+tb+"' "+ ("AND table_schema = '"+targetSchema+"'") if targetSchema else ""
        try:
            cursor.execute(q0)
        except Exception as e:
            print(e)
            raise
        _fields = cursor.fetchone()[0]

        # on parcourt les identifiants des objets extraits
        q1 = "SELECT "+id_field+" FROM "+wIdsTableName
        try:
            cursor.execute(q1)
        except Exception as e:
            print(e)
            raise
        tuples = cursor.fetchall()
        ids_ = [ "'"+t[0]+"'" for t in tuples ]
        ids_1 = [ "''"+t[0]+"''" for t in tuples ]
        ids = [ t[0] for t in tuples ]

        bunch_size = 10000
        start = 0
        end = min(start+bunch_size,len(ids))
        count_d = 0
        count_m = 0

        if ids:
            while True:
                sub_ids_ = ids_[start : end]
                sub_ids_1 = ids_1[start : end]
                sub_ids = ids[start : end]

                # on recupere les objets dans la table de travail
                q2 = "SELECT "+_fields+" FROM "+wTableName
                q2 += " WHERE "+id_field+" IN ("+",".join(sub_ids_)+")"
                print("GETTING WORKING TABLE ITEMS :")
                print(q2[:500])
                try:
                    cursor.execute(q2)
                except Exception as e:
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
                q2_bis = "SELECT "+_fields+" FROM "+tableName
                q2_bis += " WHERE "+id_field+" IN ("+",".join(sub_ids_)+")"
                print("GETTING MAIN TABLE ITEMS :")
                print(q2_bis[:500])
                try:
                    cursor.execute(q2_bis)
                except Exception as e:
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
                        historized_d.append(sub_ids_[i])
                        deleted.append(sub_ids_[i])

                    # objet modifie
                    elif not array_equal(w_objects[sub_ids[i]], o_objects[sub_ids[i]]):
                        count_m += 1
                        historized_m.append(sub_ids_[i])
                        modified.append(sub_ids_1[i])
                        if nohistory:
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
        except Exception as e:
            print(e)
            raise
        new_tuples = cursor.fetchall()

        for nt in new_tuples:
            integrated.append("'" + nt[0] + "'")
        
        print("Nombre d'objets créés: "+str(len(new_tuples)))

        if not to_up :
            # on transfère les objets dans la table historique
            fields = _fields+","+modification_type_field+","+modification_step_field

            if historized_d:
                values_d = fields.replace(modification_step_field, "'"+step+"'").replace(modification_type_field, "'D'")
                q4 = "INSERT INTO "+hTableName+" ("+fields+") SELECT "+values_d+" FROM "+tableName
                q4 += " WHERE "+id_field+" IN ("+",".join(historized_d)+")"
                print("DELETED ITEMS HISTORIZATION :")
                print(q4[:500])
                try:
                    cursor.execute(q4)
                except Exception as e:
                    print(e)
                    raise
                conn.commit()
            
            if historized_m:
                values_m = fields.replace(modification_step_field, "'"+step+"'").replace(modification_type_field, "'M'")
                q5 = "INSERT INTO "+hTableName+" ("+fields+") SELECT "+values_m+" FROM "+tableName
                q5 += " WHERE "+id_field+" IN ("+",".join(historized_m)+")"
                print("MODIFIED ITEMS HISTORIZATION :")
                print(q5[:500])
                try:
                    cursor.execute(q5)
                except Exception as e:
                    print(e)
                    raise
                conn.commit()

        # on supprime les objets de la table
        if deleted:
            if nohistory:
                q6 = "DELETE FROM "+tableName
            else:
                #Preparation pour historisation
                q6 = "UPDATE "+tableName+" SET gcms_detruit = true "
            q6 += " WHERE "+id_field+" IN ("+",".join(deleted)+")"
            print("ITEMS DELETION:")
            print(q6[:500])
            try:
                cursor.execute(q6)
            except Exception as e:
                print(e)
                raise
            conn.commit()

        # on transfère les nouveaux objets de la table de travail vers la table
        if integrated:
            values = _fields.replace(step_field, "NULL" if to_up else "'"+step+"'")
            q7 = "INSERT INTO "+tableName+" ("+_fields+") SELECT "+values+" FROM "+wTableName
            q7 += " WHERE "+id_field+" IN ("+",".join(integrated)+")"
            print("ITEMS INTEGRATION:")
            print(q7[:500])
            try:
                cursor.execute(q7)
            except Exception as e:
                print(e)
                raise
            conn.commit()
        
        # on transfère les objets modifiés de la table de travail vers la table
        if modified and not(nohistory):
            sc_name = tableName[0:tableName.find(".")]
            tb_name = tableName[tableName.find(".")+1:]
            id_list = "'("+",".join(modified)+")'" 
            q8 = "SELECT ign_update_from_working_table('"+ tb_name +"', '" + sc_name + "', '" + id_field + "', " + id_list + ", '" + step + "' );"
            print(q8[:500])
            try:
                cursor.execute(q8)
            except Exception as e:
                print(e)
                raise
            conn.commit()

    cursor.close()
    conn.close()