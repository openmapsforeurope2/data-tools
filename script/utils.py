import json
import re
import sys


def getConf(confFile):
    """
    Fonction utilitaire pour la conversion du fichier de configuration json en objet python.

    Paramètres:
    confFile (path) : fichier de configuration

    Retourne:
    objet : configuration
    """
    with open(confFile) as f:
        confString = f.read()
        conf = json.loads(confString)

        #realisation des templates
        match = re.search('\$\{[a-zA-Z_][a-zA-Z_.0-9]*\}', confString)
        while match:
            matchValue = match.group()[2:-1]
            matchValueParts = matchValue.split(".")

            value=conf
            for part in matchValueParts:
                value = value[part]
            
            confString = confString.replace(match.group(), value)

            match = re.search('\$\{[a-zA-Z_][a-zA-Z_.0-9]*\}', confString)

        return json.loads(confString)
    return None


def getDbConfFromEnv():
    """
    Fonction utilitaire pour récupérer la configuration de la connection à la BDD depuis les variables d'environnement

    Retourne:
    objet : configuration de la BDD
    """
    conf = {"db":{}}
    conf["db"]["host"]=os.environ["PGHOST"]
    conf["db"]["port"]=os.environ["PGPORT"]
    conf["db"]["name"]=os.environ["PGDATABASE_NAT"]
    conf["db"]["user"]=os.environ["PGUSER"]
    conf["db"]["pwd"]=os.environ["PGPASSWORD"]
    return conf