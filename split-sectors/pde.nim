import httpclient
import tile, utils, types, strutils, sequtils, uri, strformat

proc getTileLayerSet*(layers: seq[string], sectorBorderPonts: seq[Point], fromFc, toFc: int): TileLayerSet =
    result = TileLayerSet()
    for fc in fromFc..toFc:
        let
            lvl = fc + 8
            tXYs = tilesByPolygon(lvl, sectorBorderPonts) #get TileXYs which cover polygon sector
        for layer in layers:
            for t in tXYs:
                result.tileXys.add [t.x, t.y].join(",")
                result.levels.add lvl
                result.layers.add [layer, "_FC", $fc].join("")

proc distribTilesBy*(tSet: TileLayerSet, by: int): TileLayerSetDistribBy =
    result = TileLayerSetDistribBy()
    let numParts = (tSet.tileXys.len div by) + 1
    result.tileXys = tSet.tileXys.distribute numParts
    result.levels = tSet.levels.distribute numParts
    result.layrs = tSet.layers.distribute numParts

proc getRoadLinks*(layers: seq[string], sectorBorderPonts: seq[Point], apikey: string, fromFc, toFc: int, saveTo: string) =
    var
        client = newHttpClient()
        arrTileXYs, arrLevels, arrLayers: seq[string]
    for fc in fromFc..toFc:
        let lvl = fc + 8
        for layer in layers:
            let tXYs = tilesByPolygon(lvl, sectorBorderPonts) #get TileXYs which cover polygon sector
            for t in tXYs:
                arrTileXYs.add [t.x, t.y].join(",")
                arrLevels.add $lvl
                arrLayers.add [layer, "_FC", $fc].join("")
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

