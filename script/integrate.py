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
    step, conf, theme, tables, verbose
):
    conn = psycopg2.connect(    user = conf['db']['user'],
                                password = conf['db']['pwd'],
                                host = conf['db']['host'],
                                port = conf['db']['port'],
                                database = conf['db']['name'])
    cursor = conn.cursor()

    print("INTEGRATING...", flush=True)

    # On revert tout un theme si pas d argument sinon on revert les tables passees en argument
    if not tables :
        tables = conf['border-extraction']['data']['themes'][theme]

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
    id_field = conf['data']['id_field']
    working_schema = conf['data']['themes'][theme]['w_schema']
    theme_schema = conf['data']['themes'][theme]['schema']
    modification_type_field = conf['data']['modification_type_field']
    step_field = conf['data']['step_field']
    for tb in tables:
        # on recupere les noms des champs
        q0 = "SELECT string_agg(column_name,',') FROM information_schema.columns WHERE table_name = '"+tb+"' "+ ("AND table_schema = '"+theme_schema+"'") if theme_schema else ""
        cursor.execute(q0)
        _fields = cursor.fetchone()[0]

        # on parcourt les identifiants des objets extraits
        q1 = "SELECT "+id_field+" FROM "+getTableName(working_schema, tb)+"_w_ids"
        cursor.execute(q1)
        tuples = cursor.fetchall()
        ids_ = [ "'"+t[0]+"'" for t in tuples ]
        ids = [ t[0] for t in tuples ]

        bunch_size = 10000
        start = 0
        end = min(start+bunch_size,len(ids))
        count_d = 0
        count_m = 0

        while True:
            sub_ids_ = ids_[start : end]
            sub_ids = ids[start : end]

            # on recupere les objets dans la table de travail
            q2 = "SELECT "+_fields+" FROM "+getTableName(working_schema, tb)+"_w"
            q2 += " WHERE "+id_field+" IN ("+",".join(sub_ids_)+")"
            print(q2[:500])
            cursor.execute(q2)
            w_tuples = cursor.fetchall()
            w_idRank = getIdRank(cursor, id_field)

            # on place les objets dans un dictionnaire
            w_objects = {}
            for w_t in w_tuples:
                # print(w_t)
                w_objects[w_t[w_idRank]] = w_t

            # on recupere les objets dans la table principale
            q2_bis = "SELECT "+_fields+" FROM "+getTableName(theme_schema, tb)
            q2_bis += " WHERE "+id_field+" IN ("+",".join(sub_ids_)+")"
            print(q2_bis[:500])
            cursor.execute(q2_bis)
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
                    deleted.append(sub_ids_[i])
                    integrated.append(sub_ids_[i])

            if end == len(ids):
                break
            else:
                start = end
                end = max(start+bunch_size,len(ids))
    
        print("Nombre d'objets supprimés: "+str(count_d))
        print("Nombre d'objets modifiés: "+str(count_m))


        # on identifie les objets crees
        q3 = "SELECT a."+id_field+" FROM "+getTableName(working_schema, tb)+"_w AS a"
        q3 += " LEFT JOIN "+getTableName(working_schema, tb)+"_w_ids AS b ON a."+id_field+"=b."+id_field
        q3 += " WHERE b."+id_field+" IS NULL"
        cursor.execute(q3)
        new_tuples = cursor.fetchall()

        for nt in new_tuples:
            integrated.append(nt[0])
        
        print("Nombre d'objets créés: "+str(len(integrated)))

        
        # on transfert les objets dans la table historique
        # TODO ajouter un champ w_step_h dans la table historique
        fields = _fields+","+modification_type_field

        if historized_d:
            values_d = fields.replace(step_field, "'"+step+"'").replace(modification_type_field, "'D'")
            q4 = "INSERT INTO "+getTableName(theme_schema, tb)+"_wh ("+fields+") SELECT "+values_d+" FROM "+getTableName(theme_schema, tb)
            q4 += " WHERE "+id_field+" IN ("+",".join(historized_d)+")"
            print(q4[:500])
            cursor.execute(q4)
            conn.commit()
        
        if historized_m:
            values_m = fields.replace(step_field, "'"+step+"'").replace(modification_type_field, "'M'")
            q5 = "INSERT INTO "+getTableName(theme_schema, tb)+"_wh ("+fields+") SELECT "+values_m+" FROM "+getTableName(theme_schema, tb)
            q5 += " WHERE "+id_field+" IN ("+",".join(historized_m)+")"
            print(q5[:500])
            cursor.execute(q5)
            conn.commit()

        # on supprime les objets de la table
        if deleted:
            q6 = "DELETE FROM "+getTableName(theme_schema, tb)
            q6 += " WHERE "+id_field+" IN ("+",".join(deleted)+")"
            print(q6[:500])
            cursor.execute(q6)
            conn.commit()

        # on transfert les objets de la table de travail vers la table
        if integrated:
            values = _fields.replace(step_field, "'"+step+"'")
            q7 = "INSERT INTO "+getTableName(theme_schema, tb)+" ("+_fields+") SELECT "+values+" FROM "+getTableName(working_schema, tb)+"_w"
            q7 += " WHERE "+id_field+" IN ("+",".join(integrated)+")"
            print(q7[:500])
            cursor.execute(q7)
            conn.commit()
        

    cursor.close()
    conn.close()