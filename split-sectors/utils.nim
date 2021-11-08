import sugar, sequtils, strutils, strformat, math, parseutils

type
    Point* = object
        x*: float
        y*: float

proc isPointInPolygon*(testPoint: Point, polygPoints: openArray[Point]): bool =
    result = false
    var j = polygPoints.high
    for i,p in pairs(polygPoints):
        let lP = polygPoints[j]
        if p.y < testPoint.y and lP.y >= testPoint.y or lP.y < testPoint.y and p.y >= testPoint.y:
            if ( p.x.float + (testPoint.y - p.y) / (lP.y - p.y) * (lP.x - p.x).float ) < testPoint.x.float:
                result = not result
        j = i


proc distance*(p1, p2: Point): float =
    sqrt ((p2.x - p1.x).pow(2) + (p2.y - p1.y).pow(2))

proc parseCoords*(lats, lngs: string): seq[Point] {.inline.} =
    let
        seqLats = (lats.split ",")
            .map((x) => (if x == "": 0 else: x.parseInt))
        seqLngs = (lngs.split ",")
            .map((x) => (if x == "": 0 else: x.parseInt))
    var
        fLat, fLng: int
    for i,lat in seqLats:
        let lng = seqLngs[i]
        fLat += lat
        fLng += lng
        result.add Point(y: fLat / 100_000, x: fLng / 100_000)


proc getBorderPoints*(hrCoord: string): seq[Point] =
    let hrArrArea =
        (hrCoord.split " ").map(
            proc(item: string): string =
                result = (item.split ",").map(
                    proc(item: string): string =
                        result = item.strip
                ).join(",")
        ).join(",").split ","
    var
        iLat = 1
        iLng = 0
    for i in countup(0, hrArrArea.high-3, 3):
        #consLog("geoArea: hr ", i, hrArrArea.high)
        result.add Point(y: hrArrArea[i + iLng].parseFloat, x: hrArrArea[i + iLat].parseFloat)
    result.add Point(y: hrArrArea[iLng].parseFloat, x: hrArrArea[iLat].parseFloat)


proc getFcs*(): seq[(string, string)] =
    for i in 1..5:
        result.add (fmt"_FC{i}", "")

proc getIndex*(xs: seq[string], s: string): int =
    for i,x in xs:
        if x == s:
            return i
    result = -1


proc parseAdmins*(x: string, ignoreLeftRight = true): seq[string] {.inline.} =
    if ignoreLeftRight and x.split(";").len > 1:
        return newSeq[string]()
    let admIds = x
        .split(",")
        .map(item => (
                let arrLrD = item.split ";"
                arrLrD[0].strip # take only left
            )
        )
    let cityId = admIds[3].parseInt
    result = collect(newSeq):
        for i, admId in admIds:
            if admId != "":
                if i != 3: #not city
                    $(cityId + admId.parseInt)
                else:
                    admId
            else:
                ""



proc isNumber*(value: string): bool {.inline.} =
    var ignoreMe = 0.0
    result = parseFloat(value, ignoreMe) == value.len
