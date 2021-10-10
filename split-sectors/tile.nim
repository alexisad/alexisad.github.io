import math
import types, utils

proc getCoord*(level, tileX, tileY: int): (float, float) =
    let tileSize = 180 / (2 ^ level)
    (tileY.float * tileSize - 90, tileX.float * tileSize - 180)


proc getTileXY*(level: int, lat, lng: float): (int, int) =
    let tileSize = 180 / (2 ^ level)
    (trunc( (lng + 180) / tileSize ).int, trunc( (lat + 90) / tileSize ).int)

#convert TileId(TileXY) to another level
proc toTileXY*(fromLevel, fromTileX, fromTileY, toLevel: int): seq[(int, int)] =
    let c = getCoord(fromLevel, fromTileX, fromTileY)
    let tileXY = getTileXY(toLevel, c[0], c[1])
    if fromLevel < toLevel:
        for x in 0..((toLevel - fromLevel) * 2 - 1):
            for y in 0..((toLevel - fromLevel) * 2 - 1):
                result.add (tileXY[0] + x, tileXY[1] + y)
    else:
        result.add tileXY


#calculate TileXYs which cover polygon
proc tilesByPolygon*(level: int, points: seq[Point]): seq[TileId] =
    var
        maxTileX, maxTileY = int.low
        minTileX, minTileY = int.high
    for p in points:
        let txy = getTileXY(level, p.y, p.x)
        if txy[0] < minTileX:
            minTileX = txy[0]
        if txy[0] > maxTileX:
            maxTileX = txy[0]
        if txy[1] < minTileY:
            minTileY = txy[1]
        if txy[1] > maxTileY:
            maxTileY = txy[1]
    for tx in minTileX..maxTileX:
        for ty in minTileY..maxTileY:
            result.add TileId(x: tx, y: ty)
