import httpclient
import tile, utils, types, strutils, sequtils, uri, strformat

proc getRoadLinks*(layers: seq[string], sectorBorderPonts: seq[Point], apikey: string, fromFc, toFc: int, saveTo: string) =
    var
        client = newHttpClient()
        arrTileXYs, arrLevels, arrLayers: seq[string]
    for fc in fromFc..toFc:
        let lvl = fc + 8
        for layer in layers:
            let tXYs = tilesByPolygon(lvl, sectorBorderPonts)
            for t in tXYs:
                arrTileXYs.add [t.x, t.y].join(",")
                arrLevels.add $lvl
                arrLayers.add layer & $fc
    let numPart = (arrTileXYs.len div 64) + 1
    let dTileXYs = arrTileXYs.distribute numPart
    let dLevels = arrLevels.distribute numPart
    let dLayers = arrLayers.distribute numPart
    echo "dTileXYs.len:", dTileXYs.len
    writeFile(saveTo, "")
    var data: seq[string]
    for i in 0..dTileXYs.high:
        let
            allTileXYs = encodeUrl(dTileXYs[i].join ",")
            levels = encodeUrl(dLevels[i].join ",")
            layers = encodeUrl(dLayers[i].join ",")
            urlRoadLink = fmt"https://fleet.ls.hereapi.com/1/tiles.txt?apikey={apikey}&meta=1&tilexy={allTileXYs}&layers={layers}&levels={levels}"
        data.add (client.getContent urlRoadLink)
        echo "i:", i
    var roadLinksFile: File
    discard roadLinksFile.open(saveTo, fmAppend)
    roadLinksFile.write data.join("\n")
    roadLinksFile.close()

