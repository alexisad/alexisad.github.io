import sugar, sequtils, strutils, strformat

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


proc parseCoords*(lats, lngs: string): seq[Point] =
    let
        seqLats = (lats.split ",")
            .map((x) => (if x == "": "0" else: x))
        seqLngs = (lngs.split ",")
            .map((x) => (if x == "": "0" else: x))
    var
        fLat, fLng: int
    for i,lat in seqLats:
        let lng = seqLngs[i]
        fLat += lat.parseInt
        fLng += lng.parseInt
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


proc parseAdmins*(x: string, ignoreLeftRight = true): seq[string] =
    #let chkCity = x.split(",")[3]
    #if chkCity.split(";").len > 1:
        #echo ">1 city:", chkCity
    let adminsTmp =
        if ignoreLeftRight:
            x.split(",")
                .filter(item => (
                        (item.split ";").len == 1
                    )
                )
        else:
            x.split(",")
    if x.split(",").len != adminsTmp.len:
        return newSeq[string]()
    let districtIds0 = adminsTmp
        .map(item => (
                let arrLrD = item.split ";"
                let lrD = arrLrD[0].strip
                lrD
                #[if lrD == "":
                    "0"
                else:
                    lrD]#
            )
        )
    let cityId = districtIds0[3].parseInt
    result = collect(newSeq):
        for i,d in districtIds0:
            if d.toLowerAscii == "null":
                ""
            else:
                if i != 3: #not city
                    if d != "":
                        $(cityId + d.parseInt)
                    else:
                        d
                else:
                    d


