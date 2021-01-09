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
