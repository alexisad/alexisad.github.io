import math

proc getCoord*(level, tileX, tileY: int): (float, float) =
    let tileSize = 180 / (2 ^ level)
    (tileY.float * tileSize - 90, tileX.float * tileSize - 180)


proc getTileXY*(level: int, lat, lng: float): (int, int) =
    let tileSize = 180 / (2 ^ level)
    (trunc( (lng + 180) / tileSize ).int, trunc( (lat + 90) / tileSize ).int)


proc toTileXY*(fromLevel, fromTileX, fromTileY, toLevel: int): seq[(int, int)] =
    let c = getCoord(fromLevel, fromTileX, fromTileY)
    let tileXY = getTileXY(toLevel, c[0], c[1])
    if fromLevel < toLevel:
        for x in 0..((toLevel - fromLevel) * 2 - 1):
            for y in 0..((toLevel - fromLevel) * 2 - 1):
                result.add (tileXY[0] + x, tileXY[1] + y)
    else:
        result.add tileXY
