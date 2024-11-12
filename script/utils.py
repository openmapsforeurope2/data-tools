import json
import re
import sys

def getConf(confFile):
    with open(confFile) as f:
        confString = f.read()
        conf = json.loads(confString)

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