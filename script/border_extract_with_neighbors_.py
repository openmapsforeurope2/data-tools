import border_extract_

def run(
    conf,
    mcd,
    theme,
    tables,
    distance,
    country,
    borders,
    inDispute,
    all,
    suffix,
    verbose
):    
    fromUp = False
    reset = True

    if all :
        inDispute = True;
        if country in conf['data']['operation']['common']['neighbors']:
            borders = conf['data']['operation']['common']['neighbors'][country]
        else :
            print("[border_extract_with_neighbors_] Error : neighbors not defined for country : "+ country)
            raise

    if inDispute:
        boundaryType = 'international'
        border = False
        border_extract_.run(conf, mcd, theme, tables, distance, [country], border, boundaryType, suffix, fromUp, reset, verbose)
        reset = False

    boundaryType = None
    if country in conf['data']['operation']['common']['neighbors']:
        allNeighbors = conf['data']['operation']['common']['neighbors'][country]
        orderedBorders = [b for b in allNeighbors if b in borders]
        borders = orderedBorders

    for border in borders:
        border_extract_.run(conf, mcd, theme, tables, distance, [country], border, boundaryType, suffix, fromUp, reset, verbose)
        reset = False
