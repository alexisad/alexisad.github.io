# nim -o:js/hmapjs_gebiet.js js --oldgensym:on --opt:speed -d:release hmapjs_gebiet.nim
# nim -o:js/hmapjs_gebiet.js js --debuginfo:on --oldgensym:on hmapjs_gebiet.nim
# nim -o:js/hmapjs_gebiet.js js --debuginfo:on -d:conslog hmapjs_gebiet.nim
# browser-sync start --proxy "http://127.0.0.1:8083/index_gebiet.html?ai=UHuJLJrJznje69zJ2HB7&ac=HdAoJ-BlDvmvb0eksDYqyg" --files "js/*.js"
import macros, typetraits, algorithm, unicode
import jsbind, dom, jsconsole
import jsffi
import utils/[jstypes, tile]
from strutils import repeat, join, find, replace, split, NewLines, Digits
import tables, sequtils, json, hashes, times, strformat
#import serializetools/[serializebin, serialstring]
import jstin

include karax / prelude
import karax / kdom
#from sugar import `=>`
#import sugar

import H
import H/service
import H/service/extension/customLocation
import H/service/extension/customLocation/Table
import H/service/extension/platformData/Service/EntryPoint
import H/service/extension/platformData/Service/EntryPointType
import H/service/extension/platformData
import H/mapevents
import H/ui
import H/ui/Control
import H/math
import H/geo
import H/util
import H/util/wkt


var window {.importjs, nodecl.}: JsObject

type
    Coord = ref object
        lat: Latitude
        lng: Longitude
    Link = ref object
        linkId: int
        name: string
        cityId: int
        districtId: int
        postalCode: string
        neighborLinks: seq[int]
        geometry: seq[Coord]
        readOnly: bool
        addedToMap: bool
        addedToSector: bool
    Street = ref object
        name: string
        links: seq[Link]
        sector: Sector
        totalFamilies: Natural
    Sector = ref object
        postalCode, district, folkDistrict, city: string
        pFix: int
        streets: OrderedTable[string, seq[Link]]
        shownOnMap: bool
        exclude: bool
    MinistryArea = ref object
        name: string
        cities: OrderedTable[string, MinistryCity]
    MinistryCity = ref object
        allLinks: tables.Table[int, Link]
        allStreets: tables.OrderedTable[string, Street]
        cachedTiles: tables.Table[string, JsObject]
        allSectors: OrderedTable[string, Sector]
        lastPostfix: tables.Table[string, int]

proc hash(x: Street): Hash =
    ## Piggyback on the already available string hash proc.
    ##
    ## Without this proc nothing works!
    #proc uHash(s: string): Hash =
        #result = unicode.toLower(unicode.strip s).hash
    template uHash(s: string): untyped =
        unicode.toLower(unicode.strip s).hash
    result = x.name.uHash !& x.sector.postalCode.uHash !&
        x.sector.city.uHash !& x.sector.district.uHash
    result = !$result

const resAllStreets = staticRead"resAllStreets.csv"
var
    platform: Platform
    allLinks = initTable[int, Link](8)
    allStreets = initOrderedTable[string, Street](8)
    cachedTiles = initTable[string, JsObject](8)
    allSectors = initOrderedTable[string, Sector](8)
    lastPostfix = initTable[string, int](8)
    mvStreetGrp = newGroup()
    ministryArea: MinistryArea
    nameArea = "Hanau-Russisch"
    sectorGrp = initTable[Sector, Group](8)

var
    cityId: int
    districtId: int
    addrDistr, addrCity: string
    clckLinkId: int
    postalCode: string
    sectName: string
    borderDistr: seq[string]
    map {.exportc.}: Map  



template dbg(x: untyped): untyped =
    when not defined(release):
        x


template consLog(args: varargs[untyped]): untyped =
    when defined(conslog):
        console.log(args)


template insSect(clrStreets = false): untyped =
    newv = cast[Sector](jsonParse jsonStringify(v))
    if clrStreets:
        newv.streets = initOrderedTable[string, seq[Link]]()
    inc newv.pFix
    for nst,st in newv.streets.pairs:
        allStreets[nst].sector = newv
    dbg:
        consLog("insSect:", [k.split"-"[0], $newv.pFix].join"-", v, newv)
        consLog("lastPostfix:", lastPostfix)
    [k.split"-"[0], $newv.pFix].join"-"


proc initTblTotFamByStreet(): tables.Table[Hash, Natural] =
    result = initTable[Hash, Natural]()
    #var
        #parser: CsvParser
        #fn = "resAllStreets.csv"
        #strm = newFileStream(fn, fmRead)
    #parser.open(strm, fn, '|', '0')
    let streets = resAllStreets.split(Newlines)
    let headerSeq = streets[0].split"|"
    var headerTbl = initTable[string, Natural]()
    for i,h in headerSeq:
        headerTbl[h] = i
    #dbg:
        #echo "headerTbl:", headerTbl
        #echo "row1:", streets[1].split"|"
    template rowEntry(res: typed, rs: seq[string], nf: string): untyped =
        var res = rs[headerTbl[nf]]
    for i in 1..streets.high:
        let rowSeq = streets[i].split"|"
        #let strN = rowSeq[headerTbl["Street"]]
        var
            strN: string
            city: string
            dstr: string
            plz: string
            totalFam: string
        strN.rowEntry(rowSeq, "Street")
        if strN == "": continue
        city.rowEntry(rowSeq, "City")
        dstr.rowEntry(rowSeq, "District")
        let district =
            if dstr == city:
                ""
            else:
                dstr
        plz.rowEntry(rowSeq, "Plz")
        let sector = Sector(postalCode: plz, city: city, district: district)
        let street = Street(name: strN, sector: sector)
        totalFam.rowEntry(rowSeq, "TotalFamilies")
        #dbg:
            #echo "hash:", street.hash, " ", totalFam
        result[street.hash] = totalFam.parseInt


var tblTotalFam = initTblTotFamByStreet()

proc sortStreetTbl[A,B](x, y: (A, B)): int =
    let kX = x[0]
    let kY = y[0]
    if kX > kY or kX == kY:
        1
    else:
        -1

proc sortSectorTbl[A,B](x, y: (A, B)): int =
    let akX = x[0].split("-")
    let akY = y[0].split("-")
    let kX = akX[0] & "-" & "0".repeat(4-akX[akX.high].len) & akX[akX.high]
    let kY = akY[0] & "-" & "0".repeat(4-akY[akY.high].len) & akY[akY.high]                
    #consLog("sortSectorTbl:: ", "x: ", x[0], "y: ", y[0])
    if kX > kY or kX == kY:
        1
    else:
        -1


proc loadLinks(e: kdom.Event)


proc name(s: Sector): string =
    @[s.postalCode & "-" & $s.pFix,
            s.city, if s.folkDistrict != "": s.folkDistrict else: s.district].join(" ").strip
proc id(s: Sector): string =
    s.postalCode & "-" & $s.pFix
proc nextId(s: Sector): string =
    if s.exclude:
        ""
    else:
        s.postalCode & "-" & $(lastPostfix[s.postalCode] + 1)

proc hash(x: Sector): Hash =
    ## Piggyback on the already available string hash proc.
    ##
    ## Without this proc nothing works!
    result = x.id.hash !& x.name.hash
    result = !$result

proc removeAllSectorFromMap() =
    for s in allSectors.mvalues:
        s.shownOnMap = false
        try:
            sectorGrp[s].removeAll()
        except:
            discard
    redraw()


proc load(d: MinistryArea) =
    try:
        let city = d.cities[addrCity]
        allLinks = city.allLinks
        allStreets = city.allStreets
        cachedTiles = city.cachedTiles
        for k,v in city.allSectors:
            allSectors[k] = cast[Sector](v)
            try:
                allSectors[k].folkDistrict = v.folkDistrict
            except:
                allSectors[k].folkDistrict = ""
            consLog("export: ", allSectors[k])
        #allSectors = cast[OrderedTable[string, Sector]](city.allSectors)
        lastPostfix = city.lastPostfix
        
        redraw()            
    except:
        window.alert("Сначала кликнуть по городу на карте\n с каким надо работать.")
    removeAllSectorFromMap()


proc saveFunc(jStr: cstring, fname: string) =
    let blb = newBlob(jStr, JsObject{ type: "application/json" })
    let bUrl = createObjectURL(blb)
    let elA = kdom.document.createElement("a")
    elA.setAttribute("href", cast[cstring](bUrl))
    elA.setAttribute("download", fname)
    kdom.document.body.appendChild(elA)
    elA.click()
    kdom.document.body.removeChild(elA)
    revokeObjectURL(bUrl)
    

proc toJson(x: Latitude): JsonNode =
    # Encode the timestamp as string
    result = newJFloat(x)

proc toJson(x: Longitude): JsonNode =
    # Encode the timestamp as string
    result = newJFloat(x)

proc toJson(x: seq[Coord]): JsonNode =
    # Encode the timestamp as string
    #[result = newJObject()
    result.add("lat", toJson(x.lat))
    result.add("lng", toJson(x.lng))]#
    var aC = newSeq[string]()
    for c in x:
        aC.add @[$c.lat, $c.lng].join(",")
    result = newJString aC.join(",")

proc toJson(x: tables.Table[int, Link]): JsonNode =
    # Encode the timestamp as string
    result = newJObject()
    var cnt = 0
    let lenObj = x.len
    for k,v in pairs(x):
        result.add($k, toJson(v))
        consLog("toJson: ", $cnt, " from ", lenObj)
        inc cnt
        #if cnt > 100:
            #break
    for k,v in pairs(result):
        consLog("jsnObj: ", k)
        for kO,vO in pairs(v):
            var val: string
            #[case v.kind
            of JString:
                val = vO.getStr]#
        
            consLog("jsnOOO: ", kO, vO)

when false:
    proc links2Json[T: ref](x: tables.Table[int, T]): string =
        # Encode the timestamp as string
        result = ""
        var cnt = 0
        let lenObj = x.len
        var aL = newSeq[string]()
        for k,v in pairs(x):
            var rLink = ""
            rLink.addQuoted $k
            rLink.add ":{"
            var aF = newSeq[string]()
            var rf = ""
            rf.add("linkId" & ":")
            rf.addQuoted(v.linkId)
            aF.add rf
            rf = ""
            rf.add("name" & ":")
            rf.addQuoted(v.name)
            aF.add rf
            rf = ""
            rf.add("cityId" & ":")
            rf.addQuoted(v.cityId)
            aF.add rf
            rf = ""
            rf.add("districtId" & ":")
            rf.addQuoted(v.districtId)
            aF.add rf
            rf = ""
            rf.add("postalCode" & ":")
            rf.addQuoted(v.postalCode)
            aF.add rf
            rf = ""
            rf.add("neighborLinks" & ":")
            rf.addQuoted(v.neighborLinks.join(","))
            aF.add rf
            rf = ""
            rf.add("geometry" & ":")
            var gs = newSeq[string]()
            for g in v.geometry:
                gs.add( @[$g.lat, $g.lng].join(",") )
            rf.addQuoted(gs.join(","))
            aF.add rf
            rLink.add(aF.join(",") & "}")
            aL.add rLink
        result = aL.join(",")


when false:
    proc links2Json[T: ref](x: tables.Table[int, T]): string =
        # Encode the timestamp as string
        result = ""
        var cnt = 0
        let lenObj = x.len
        for k,v in pairs(x):
            result.addQuoted $k
            result.add ":{"
            var aF = newSeq[string]()
            for fK, fV in v[].fieldPairs:
                when fV is bool or fV is int:
                    var rf = ""
                    rf.addQuoted(fK)
                    aF.add(rf & ":" & $fV)
                    #result.add $fV
                else:
                    discard
            result.add(aF.join(",") & "}")

proc sectors2Json(x: tables.OrderedTable[string, Sector]): JsObject =
    # Encode the timestamp as string
    var cnt = 0
    let lenObj = x.len
    result = newJsObject()
    for k,v in pairs(x):
        var oS = newJsObject()
        for fK, fV in v[].fieldPairs:
            when fV is bool or fV is int or
                    fV is string:
                oS[fK] = toJs fV
            elif fK == "streets":
                oS[fK] = newJsObject()
                for kStr,vStr in pairs(fV):
                    var seqLnk = newSeq[JsObject]()
                    for strLnk in vStr:
                        var lnkO = newJsObject()
                        for fkL,fvL in strLnk[].fieldPairs:
                            when fvL is bool or
                                    fvL is int or fvL is string:
                                lnkO[fkL] = toJs fvL
                            elif fkL == "neighborLinks":
                                lnkO[fkL] = toJs fvL
                            elif fkL == "geometry":
                                var gms = newSeq[string]()
                                for g in fvL:
                                    let lat = float(g.lat)
                                    let lng = float(g.lng)
                                    gms.add fmt"{lat:0.5f}"
                                    gms.add fmt"{lng:0.5f}"
                                lnkO[fkL] = toJs gms.join(",")
                        seqLnk.add lnkO
                    oS[fK][kStr] = seqLnk
        result[$k] = oS

proc save() =
    if ministryArea.isNil():
        ministryArea = MinistryArea(name: nameArea, cities: initOrderedTable[string, MinistryCity]())
    ministryArea.cities[addrCity] = MinistryCity(
                            allLinks: allLinks,
                            allStreets: allStreets,
                            cachedTiles: cachedTiles,
                            allSectors: allSectors,
                            lastPostfix: lastPostfix
                    )
    let ser = jsonStringify(ministryArea)
    let fname = addrCity & "_" & $now() & ".json"
    saveFunc(ser, fname)
    var citiesExp = newJObject()
    #citiesExp.add(addrCity, )
    var ministryAreaExp = newJObject()
    ministryAreaExp.add("name", newJString nameArea)
    var allSectorsExp = newJArray()
    #var allLinksExp = toJson(allLinks)
    for k,v in pairs(allSectors):
        let s = newJObject()
        s.add("city", newJString v.city)
        allSectorsExp.add s
    let fnameExp = addrCity & "_Exp_" & $now() & ".json"
    let strR = sectors2Json(allSectors)
    #strR.toUgly(allLinksExp)
    consLog("toJson string finish: ")
    saveFunc(jsonStringify(strR), fnameExp)


proc displaySector(sectName: string, show: bool = true)

proc chckdCheck(ev: kdom.Event; n: VNode) =
    for inpChck in kdom.document.querySelectorAll(".show-sector"):
        #consLog("show-sector: ", inpChck.getAttribute "checkd")
        if (inpChck.getAttribute "checkd") == "true":
            inpChck.setAttribute "checked", "true"
        else:
            inpChck.removeAttribute "checked"

proc inSect(sn: string): bool =
    result = false
    for k,v in pairs(allSectors):
        if (k.find sn) != -1:
            result = true
            break
proc reindexSect() =
    var moved = true
    while moved:
        moved = false
        for k,val in mpairs(lastPostfix):
            for v in countdown(val, 1):
                let fromSect = k & "-" & $v
                let prevV = v-1
                let toSect = k & "-" & $prevV
                if prevV != 0 and not allSectors.hasKey toSect:
                    consLog("reindex:: ", fromSect, " ", toSect)
                    moved = true
                    allSectors[toSect] = Sector()
                    allSectors[toSect].shallowCopy allSectors[fromSect]
                    allSectors[toSect].pFix = prevV
                    for name, mV in pairs( (allSectors[fromSect].streets) ):
                        discard allSectors[toSect].streets.hasKeyOrPut(name, allStreets[name].links)
                        allStreets[name].sector = allSectors[toSect]                        
                    del allSectors, fromSect
                    if v == val:
                        dec val

proc createDom(): VNode =
    proc clckOnStr(ev: kdom.Event; n: VNode) =
        let trgt = ev.target
        map.setZoom(20)
        map.setCenter H.geo.Point(lat: trgt.getAttribute("data-lat").parseFloat, lng: trgt.getAttribute("data-lng").parseFloat)
        consLog("onclickStreet::", ev.target.getAttribute("data-lat"))
    result = buildHtml(tdiv(class = "main-root", onmouseenter = chckdCheck)):
        tdiv:
            if allSectors.len != 0:
                button:
                    text "Сохранить"
                    proc onclick(ev: kdom.Event; n: VNode) =
                        save()
            input(type="file", name="fileArea"):
                proc onchange(ev: kdom.Event; n: VNode) =
                    let fReader = newFileReaderObj()
                    cast[kdom.EventTarget](fReader).addEventListener("load", proc(e: kdom.Event) =
                                            let dataTarget = cast[JsObject](e).target
                                            let data = dataTarget.result
                                            let a = jsonParse(data)
                                            let x = cast[MinistryArea](a)
                                            consLog("loaded:: ", x)
                                            load(x)
                                        )
                    let inpFile = cast[JsObject](ev.target)
                    fReader.readAsText(cast[jstypes.Blob](inpFile.files[0]))
                    #consLog("fileArea:: ", inpFile.files)
            tdiv():
                input(`type` = "text", placeholder = "найти адрес на карте"):
                    proc onchange(ev: kdom.Event; n: VNode) =
                        let address = ev.target.value
                        let geocoder = platform.getGeocodingService()
                        let geocodingParameters = newJsObject()
                        geocodingParameters.searchText = address
                        geocodingParameters.jsonattributes = 1
                        geocoder.geocode(
                            geocodingParameters,
                            proc (r: JsObject) =
                                consLog(cstring"найти адрес на карте", r.response.view[0].result[0].location.displayPosition)
                                let c = r.response.view[0].result[0].location.displayPosition
                                map.setCenter( H.geo.Point(lat: c.latitude.to float, lng: c.longitude.to float) )
                                map.setZoom(14) ,
                            proc (e: JsObject) = discard
                        )
            for k,v in pairs(allSectors):
                #discard dbg:
                    #(echo (cstring"sector+: ", $k, $(v.postalCode), $(v.district), $(v.city), $(v.pFix)))
                let id4Move = k.replace(" ", "_")
                tdiv(class = "sector"):
                    span(class = "sect-name"):
                        text v.name
                    tdiv(class = "streets"):
                        for nStreet, links in pairs(v.streets):
                            let streetObj = Street(name: nStreet, sector: v)
                            let totalFam =
                                if tblTotalFam.hasKey(streetObj.hash):
                                    tblTotalFam[streetObj.hash]
                                else:
                                    0
                            let coord = links[0].geometry[0]
                            tdiv(class = "street"):
                                span("data-lat" = $coord.lat, "data-lng" = $coord.lng, onclick = clckOnStr):
                                    text [nStreet, " (", $totalFam, ")"].join""
                    tdiv(class = "show-sector-box"):
                        label(`for` = k):
                            text "Показ. на карте (" & $v.streets.len & ")"
                        input(type = "checkbox", name = "showSector", class = "show-sector", value = k, id = k, checkd = $v.shownOnMap):
                            proc onclick(ev: kdom.Event; n: VNode) =
                                let evClck = cast[JsObject](ev)
                                let t = evClck.target
                                let chckd = t.checked.to bool
                                let sN = t.value.to(cstring)
                                t.checkd = $(t.checked.to bool)
                                #consLog("show-sector: ", document.querySelectorAll(".show-sector"))
                                if chckd:
                                    consLog(cstring"Показ. на карте ev:: ", sN)
                                    displaySector $sN
                                else:
                                    displaySector $sN, false
                    tdiv(class = "for-select"):
                        select(id = id4Move):
                            option(value = ""):
                                text "Двинуть все улицы в"
                            for kOpt,vOpt in pairs(allSectors):
                                if kOpt == v.id:
                                    continue
                                option(value = kOpt):
                                    text kOpt
                        button(id = id4Move):
                            text "Ок !"
                            proc onclick(ev: kdom.Event; n: VNode) =
                                removeAllSectorFromMap()
                                let id = $ev.target.id
                                let fromSect = id.replace("_", " ")
                                let elSel = kdom.document.querySelectorAll("select[id='" & id & "']")
                                let toSect = $elSel[0].value
                                let fromSector = allSectors[fromSect]
                                var namesForDel = newSeq[string]()
                                for name, mV in pairs( (fromSector.streets) ):
                                    consLog("curSector:: ", name, " ", elSel[0].value)
                                    discard allSectors[toSect].streets.hasKeyOrPut(name, allStreets[name].links)
                                    allStreets[name].sector = allSectors[toSect]
                                    namesForDel.add name
                                for n in namesForDel:
                                    del fromSector.streets, n                        
                                if not fromSector.exclude:
                                    if fromSector.pFix == lastPostfix[fromSector.postalCode]:
                                        dec lastPostfix[fromSector.postalCode]
                                    del allSectors, fromSect
                                reindexSect()
                    button(id = id4Move):
                        text "вставить новый участок"
                        proc onclick(ev: kdom.Event; n: VNode) =
                            let id = $ev.target.id
                            let fromSect = id.replace("_", " ")
                            let fromSector = allSectors[fromSect]
                            var allSectorsTmp = initOrderedTable[string, Sector]()
                            var addk = 0
                            var newv: Sector
                            for k,v in allSectors:
                                if v.exclude:
                                    continue
                                let newk =
                                    if addk == 1:
                                        insSect
                                    else:
                                        if k == fromSect:
                                            addk = 1
                                            inc lastPostfix[fromSector.postalCode]
                                            dbg:
                                                consLog("вставить новый участок", id, k, allSectors[fromSect])
                                            allSectorsTmp[k] = v
                                            insSect true
                                        else:
                                            newv = v
                                            k
                                allSectorsTmp[newk] = newv
                            allSectors = cast[OrderedTable[string, Sector]](jsonParse jsonStringify(allSectorsTmp))
                            #reindexSect()
            if allSectors.len != 0:
                tdiv(class = "chg-sect-name"):
                    label:
                        text "установить новое имя района: "
                    input(`type` = "text", placeholder = "новое имя района", name="newDistrictName")
                    p:
                        label:
                            text "с: "
                        input(`type` = "text", placeholder = "с номера участка", name="fromNSect")
                        label:
                            text "по: "
                        input(`type` = "text", placeholder = "по номер участка", name="toNSect")
                    button:
                        text "установить!"
                        proc onclick(ev: kdom.Event; n: VNode) =
                            let elSelects = kdom.document.querySelectorAll("div.chg-sect-name input")
                            var newDistrictName, fromNSect, toNSect: string
                            for el in elSelects:
                                case $el.name
                                of "newDistrictName":
                                    newDistrictName = $(el.value).strip
                                of "fromNSect":
                                    fromNSect = $(el.value).strip
                                of "toNSect":
                                    toNSect = $(el.value).strip
                            for k,v in allSectors.mpairs:
                                if k.strip() in fromNSect..toNSect:
                                    v.folkDistrict = newDistrictName
            for k,v in pairs(lastPostfix):
                tdiv:
                    text k & " : " & $v
            for k,v in pairs(allStreets):
                if v.sector != nil:
                    continue
                let coord = v.links[0].geometry[0]
                tdiv(class = "street"):
                    span("data-lat" = $coord.lat, "data-lng" = $coord.lng, onclick = clckOnStr):
                        text k


var locSearch = $(cast[JsObject](window).location.search.to(cstring))
locSearch = locSearch.replace("?", "")
let arrLs = locSearch.split("&")
let apikey = arrLs[0].split("=")[1]
#let app_id = arrLs[0].split("=")[1]
#let app_code = arrLs[1].split("=")[1]

let opts = H.service.platform.Options(
        #app_id: app_id,
        #app_code: app_code,
        apikey: apikey,
        useHTTPS: true
    )
let pixelRatio = window.devicePixelRatio.to(float)
let hidpi = pixelRatio > 1.float
var layerOpts = DefaultLayersOptions(
        #[tileSize: if hidpi: 512 else: 256,
        pois: true]#
    )

if hidpi: layerOpts.ppi = 320

platform = newPlatform(opts)
let defLayers = platform.createDefaultLayers()

var mapOpts = H.Map.Options(
      pixelRatio: pixelRatio#if hidpi: 2 else: 1
      #noWrap: true
    )

let normalMap = defLayers.vector.normal
map = H.newMap(
            dom.document.getElementById("map"),
            normalMap.map,
            mapOpts
          )

let mapEvts = mapevents.newMapEvents(map)
var behavior {.exportc.} = mapevents.newBehavior(mapEvts)
var uiDef = Hui.UI.createDefault(map, defLayers)

# define main-control
#[
uiDef.addControl("main-ctrl", newControl())

let
    mainCtrl = uiDef.getControl("main-ctrl")

let
    mainCtrlId = "main-control-container"
    mainCtrlEl = document.createElement(cstring"div")
.appendChild(mainCtrlEl)
mainCtrlEl.setAttr(cstring"id", mainCtrlId.cstring)

    ]#

setRenderer createDom, "main-control-container"




map.setCenter H.geo.Point(lat: 50.1518518, lng: 8.9302924)
map.setZoom(9, false)

var mainGroup = newGroup()
var mainSectorGroup = newGroup()
mainGroup.setZIndex 99
map.addObject(mainGroup)
map.addObject(mainSectorGroup)
let mrk = H.map.newMarker(H.geo.Point(lat: 52.00, lng: 8.00))
let p = H.geo.Point(lat: 34.00, lng: 123.00)
#group.addObject(mrk)



let scrPoint = H.math.newPoint(1, 1)
let check = scrPoint.isPointInPolygon([H.math.newPoint(0, 0), H.math.newPoint(0, 3), H.math.newPoint(3, 3)])
echo "check: ", check


let cle = platform.getCustomLocationService()
let geocoder = platform.getGeocodingService();
var pdeService = platform.getPlatformDataService()

proc onGrpStreet(e: PointerEvent) =
    mvStreetGrp.removeAll()
    let trgtGrp = cast[Group]( cast[JsObject](e).currentTarget )
    let street = cast[Street](trgtGrp.getData())
    let sectId = street.sector.id
    let sectNextId = street.sector.nextId
    let sectExclude = street.sector.exclude
    #cast[JsObject](e).stopPropagation()
    #cast[JsObject](e).preventDefault()
    #let eCtx = cast[ContextMenuEvent](e)
    #[eCtx.items.add newContextItem(cstring"bebe", proc() =
                        discard
                    )]#
    let elMoveStreet = kdom.document.createElement("div")
    elMoveStreet.class = "move-str-marker"
    elMoveStreet.appendChild(kdom.document.createElement("span"))
    let elTxt = kdom.document.createTextNode(street.name)
    elMoveStreet[0].appendChild(elTxt)
    elMoveStreet.appendChild(kdom.document.createElement("div"))
    let selEl = kdom.document.createElement("select")
    let mvOpt = kdom.document.createElement("option")
    mvOpt.appendChild(kdom.document.createTextNode("Двинуть в"))
    selEl.appendChild(mvOpt)
    if not sectExclude:
        let mvOptNew = kdom.document.createElement("option")
        mvOptNew.appendChild(kdom.document.createTextNode(sectNextId & "(новый)"))
        mvOptNew.value = sectNextId
        mvOptNew.setAttribute("data-new", "1")
        selEl.appendChild(mvOptNew)
    for kOpt,vOpt in pairs(allSectors):
        if kOpt == sectId:
            continue
        let mvOpt = kdom.document.createElement("option")
        mvOpt.appendChild(kdom.document.createTextNode(kOpt))
        mvOpt.value = kOpt
        selEl.appendChild(mvOpt)
    elMoveStreet[1].appendChild(selEl)
    let btnOk = kdom.document.createElement("button")
    btnOk.appendChild(kdom.document.createTextNode("Ok !"))
    btnOk.class = "ok-str-mv"
    let mvBtnHndl = proc(e: kdom.Event) =
        mvStreetGrp.removeAll()
        removeAllSectorFromMap()
        let trgtBtn = e.target
        #let willNew = trgtBtn.getAttribute("data-new")
        let toSectId = $(cast[kdom.Element](trgtBtn.parentNode).getElementsByTagName("select")[0].value)
        let sectFromId = street.sector.id
        let postCode = street.sector.postalCode
        if not allSectors.hasKey toSectId:
            inc lastPostfix[postCode]
            allSectors[toSectId] = Sector(city: addrCity,
                                    postalCode: postCode,
                                    district: street.sector.district,
                                    pFix: lastPostfix[postCode],
                                    streets: initOrderedTable[string, seq[Link]](),
                                    shownOnMap: false
                            )
        street.sector = allSectors[toSectId]
        allSectors[toSectId].streets[street.name] = street.links
        del(allSectors[sectFromId].streets, street.name)
        let fromSector = allSectors[sectFromId]
        consLog("ok-str-mv ", sectFromId, allSectors[sectFromId] )
        if not fromSector.exclude and allSectors[sectFromId].streets.len == 0:
            if fromSector.pFix == lastPostfix[fromSector.postalCode]:
                dec lastPostfix[fromSector.postalCode]
            del allSectors, sectFromId
        consLog("mvStreet: ", toSectId, street)
        reindexSect()
        redraw()
    let btnClose = kdom.document.createElement("button")
    btnClose.appendChild(kdom.document.createTextNode("закрыть"))
    btnClose.class = "close-str-mv"
    elMoveStreet[1].appendChild(btnOk)
    elMoveStreet[1].appendChild(btnClose)
    let diOpt = DomIconOptions(onAttach: proc(el: dom.Element, di: DomIcon, dm: DomMarker) =
                                let btn = cast[kdom.EventTarget](el.getElementsByClass("ok-str-mv")[0])
                                let btnClose = cast[kdom.EventTarget](el.getElementsByClass("close-str-mv")[0])
                                addEventListener(btn, "click", mvBtnHndl)
                                addEventListener(btnClose, "click", proc(e: kdom.Event) = mvStreetGrp.removeAll())
                                let elEvt = cast[kdom.EventTarget](el)
                                elEvt.addEventListener("mouseenter", proc(e: kdom.Event) =
                                            cast[kdom.EventTarget](map).removeEventListener("tap", loadLinks)
                                )            
                        ,
                            onDetach: proc(el: dom.Element, di: DomIcon, dm: DomMarker) =
                                let btn = cast[kdom.EventTarget](el.getElementsByClass("ok-str-mv")[0])
                                removeEventListener(btn, "click", mvBtnHndl)
                                consLog("mvStreet onDetach")
                                cast[kdom.EventTarget](map).addEventListener("tap", loadLinks, false)
    )
    let iconMoveStreet = newDomIcon(cast[dom.Element](elMoveStreet), diOpt)
    let geoPoint = map.screenToGeo(e.currentPointer.viewportX, e.currentPointer.viewportY)
    let mvStreetMarker = newDomMarker(geoPoint)
    mvStreetMarker.setIcon iconMoveStreet
    mvStreetGrp.addObject(mvStreetMarker)    
    consLog("mvStreet:: ", e.currentpointer, street.name)
    echo "mvStreet: "


proc displayStreet(name: string, tree = false) =
    consLog("checkStreet: ", name)
    if not allStreets.hasKey(name):
        consLog("street not found:: ", name)
        return
    #let firstLink = if allStreets[name].links.len > 0: allStreets[name].links[0] else: nil
    #[if firstLink != nil and (firstLink.cityId != cityId or
                            firstLink.postalCode != postalCode or
                            firstLink.districtId != districtId):
        consLog("other sector:: ", firstLink)
        return]#
    if allStreets[name].sector == nil:
        let pFix = lastPostfix[postalCode]
        discard allSectors.hasKeyOrPut(sectName, Sector(city: addrCity,
                                                    postalCode: postalCode,
                                                    district: addrDistr,
                                                    pFix: pFix,
                                                    streets: initOrderedTable[string, seq[Link]](),
                                                    shownOnMap: false
                                                    )
                                    )
        discard allSectors[sectName].streets.hasKeyOrPut(name, allStreets[name].links)
        allStreets[name].sector = allSectors[sectName]
    for link in allStreets[name].links:
        let grpStreet = newGroup()
        grpStreet.setZIndex 99
        grpStreet.setData cast[JSObj](allStreets[name])
        grpStreet.addEventListener("pointerenter", proc(e: PointerEvent) =
                    cast[kdom.EventTarget](map).removeEventListener(cstring"tap", loadLinks)
                )
        grpStreet.addEventListener("pointerleave", proc(e: PointerEvent) =
                    cast[kdom.EventTarget](map).addEventListener("tap", loadLinks, false)
                )
        grpStreet.addEventListener("tap", onGrpStreet, true)
        #let mapEvts = mapevents.newMapEvents(cast[JsObj](grpStreet))
        mainGroup.addObject(grpStreet)
        let lnStr = newLineString()
        for c in link.geometry:
            lnStr.pushLatLngAlt c.lat, c.lng, cast[Altitude](1.00)
            #consLog("lnStr: ", link.geometry)
        if allLinks.hasKey(link.linkId) and not allLinks[link.linkId].addedToMap:
            let
                pOpt = PolylineOptions(
                            style: SpatialStyle(
                                        strokeColor: cstring"rgba(0, 0, 255, 0.3)",
                                        fillColor: cstring"rgba(255, 0, 0, 0.4)",
                                        lineWidth: 10
                                    ),
                            zIndex: 99
                        )

                pl = H.map.newPolyline(lnStr, pOpt)
            grpStreet.addObject(pl)
            allLinks[link.linkId].addedToMap = true
            consLog("pline: ", pl)
        if tree:
            for nLink in link.neighborLinks:
                let nLnk = if nLink > 0: nLink else: nLink * -1
                if allLinks.hasKey(nLnk):
                    #consLog("link data: ", allLinks[nLnk])
                    displayStreet allLinks[nLnk].name, tree = false
                else:
                    consLog("link not found:: ", nLnk)

proc displaySector(sectName: string, show: bool = true) =
    let sector = allSectors[sectName]
    if not show:
        mainSectorGroup.removeObject(sectorGrp[sector])
        sectorGrp[sector].removeAll()
        sector.shownOnMap = false
        return
    sectorGrp[sector] = newGroup()
    sectorGrp[sector].setZIndex -99
    sector.shownOnMap = true
    for n,links in pairs(sector.streets):
        for link in links:
            let lnStr = newLineString()
            for c in link.geometry:
                lnStr.pushLatLngAlt c.lat, c.lng, cast[Altitude](1.00)
                #consLog("lnStr: ", link.geometry)
            #if allLinks.hasKey(link.linkId) and not allLinks[link.linkId].addedToMap:
            let
                pOpt = PolylineOptions(
                            style: SpatialStyle(
                                        strokeColor: cstring"rgba(255, 0, 0, 0.2)",
                                        fillColor: cstring"rgba(255, 0, 0, 0.4)",
                                        lineWidth: 10
                                    ),
                                    zIndex: -99
                        )
                pl = H.map.newPolyline(lnStr, pOpt)
            consLog("pOpt: ", pOpt)
            sectorGrp[sector].addObject(pl)
            consLog("pline: ", pl)
    mainSectorGroup.addObject(sectorGrp[sector])
    

proc showBorder(hrCoord: string, sCol: string, latlon = true) =
    let hrArrArea = (hrCoord.split " ").map(
        proc(item: string): string =
            result = (item.split ",").map(
                proc(item: string): string =
                    result = item.strip
            ).join(",")
    ).join(",").split ","
    let hrLnStr = newLineString()
    var
        iLat = 0
        iLng = 1
    if latlon:
        iLat = 1
        iLng = 0
    for i in countup(0, hrArrArea.high-3, 3):
        #consLog("geoArea: hr ", i, hrArrArea.high)
        hrLnStr.pushLatLngAlt hrArrArea[i + iLng].parseFloat, hrArrArea[i + iLat].parseFloat, cast[Altitude](hrArrArea[i+3].parseFloat)
    hrLnStr.pushLatLngAlt hrArrArea[iLng].parseFloat, hrArrArea[iLat].parseFloat, cast[Altitude](hrArrArea[2].parseFloat)
    let
        pOpt = PolylineOptions(
                    style: SpatialStyle(
                                strokeColor: cstring(sCol),
                                fillColor: cstring(sCol),
                                lineWidth: 10
                            )
                )
        pl = H.map.newPolyline(hrLnStr, pOpt)
    map.addObject(pl)
    #consLog("geoArea: hr ", hrArrArea[2], hrLnStr)

proc geoArea() =
    let hrCoordReal = "49.95856259839435,8.850124261434395,0.0 49.96396515545882,8.899470891953959,0.0 49.989107714500946,8.942093035419573,0.0 49.99375559635732,8.973836498540546,0.0 49.98852001928919,9.014720749471216,0.0 49.98595544705414,9.046298016450189,0.0 49.993374764204034,9.054906229836575,0.0 50.01241735811533,9.038966773881107,0.0 50.02965494688769,9.03186813780005,0.0 50.0384117586606,9.032281998108914,0.0 50.042818175748586,9.027509152282287,0.0 50.04441439462123,9.022565665862723,0.0 50.04644677958852,9.013523319190714,0.0 50.04425309054112,8.996242389995311,0.0 50.04241418571553,8.987752631175479,0.0 50.04476926168952,8.980317812800713,0.0 50.05134995729781,8.977353932502664,0.0 50.05405939323471,8.980217342282131,0.0 50.06044531552646,8.986546984952541,0.0 50.062896251887224,8.988757336361253,0.0 50.06734631621531,8.99182168717788,0.0 50.06673365070724,8.992977098141527,0.0 50.0668626335698,8.99398180332731,0.0 50.06718803495289,8.994414733080061,0.0 50.06771451792822,8.995464253486665,0.0 50.06829194422368,8.99569356046626,0.0 50.0688014322406,8.995790574957626,0.0 50.06906749605375,8.996778358869724,0.0 50.06879577129238,8.997378084816354,0.0 50.06905051330128,8.998956775175868,0.0 50.06930053266752,8.99941800765802,0.0 50.0695826597326,8.999881101814484,0.0 50.07118974475246,8.99940230955102,0.0 50.07246819127017,8.999262421160052,0.0 50.073681046891316,8.999278572803176,0.0 50.07593045003854,8.998761720223174,0.0 50.07685298579153,8.998697113650673,0.0 50.079516837714955,8.99906860144255,0.0 50.08036829651911,8.999048176213728,0.0 50.08163131412362,8.999132593752917,0.0 50.08380948509669,8.998839123161446,0.0 50.08398524097505,8.998457611392535,0.0 50.08529083589718,8.998731517277907,0.0 50.0858180853043,8.999103246693766,0.0 50.087745007018746,8.999113029046814,0.0 50.08994800500485,8.99887825257364,0.0 50.09095218700986,8.998614129041318,0.0 50.09268435151408,8.997880452562647,0.0 50.093989709477825,8.9992499819895,0.0 50.09529893546212,9.000556974921759,0.0 50.097739470199144,9.003266612926636,0.0 50.11201852058528,9.02981141216353,0.0 50.11661516874831,9.067234864827416,0.0 50.12025635598552,9.07282045477725,0.0 50.14215732616893,9.07477541125969,0.0 50.13214371793553,9.104686488157405,0.0 50.130002073318444,9.11819544464286,0.0 50.12962960360105,9.129525537179045,0.0 50.124042209958354,9.131849658724928,0.0 50.12329717485541,9.139257796152435,0.0 50.12525286726787,9.144487069630674,0.0 50.12804657496021,9.150297373495386,0.0 50.130455597090595,9.155493171369901,0.0 50.133915546952075,9.158535444434747,0.0 50.1367776800252,9.15868265119595,0.0 50.13741151788165,9.163817274408206,0.0 50.14339492987892,9.173004915543089,0.0 50.14755755017878,9.192392814174495,0.0 50.14648131805793,9.200345557307376,0.0 50.138180651937496,9.259625280641485,0.0 50.13309753499998,9.307707323856194,0.0 50.139325423584935,9.327568851365392,0.0 50.12993748742165,9.339142835021836,0.0 50.12858337744752,9.365496359295658,0.0 50.12641773051991,9.372735178643259,0.0 50.11574275323997,9.381663055838633,0.0 50.09423086055464,9.394210342707808,0.0 50.087113888846716,9.404106700966404,0.0 50.084234652636276,9.41068546866214,0.0 50.08332028837411,9.415072180815773,0.0 50.084109152691816,9.419263307077205,0.0 50.08422122075908,9.425175379748403,0.0 50.08359146921259,9.427138246524793,0.0 50.08359146921259,9.433746564671972,0.0 50.09022443676629,9.46096498397125,0.0 50.09085360543011,9.474022801340594,0.0 50.093517639965924,9.48311122533397,0.0 50.09417105978058,9.497057255254838,0.0 50.09552813400177,9.509122921590878,0.0 50.10598134317437,9.5205618000653,0.0 50.114221688388604,9.519935012203698,0.0 50.14498492404182,9.511705614500329,0.0 50.151057005957576,9.529820900852283,0.0 50.16355592364119,9.537067015393063,0.0 50.17319571327903,9.524804360016356,0.0 50.17694399525393,9.501393836115371,0.0 50.192469459564606,9.505852983525081,0.0 50.19496733876523,9.518673032328001,0.0 50.19962499700489,9.516589022864023,0.0 50.21399704559683,9.50504530922025,0.0 50.21870102145308,9.466106812451708,0.0 50.26614431812017,9.43139020351146,0.0 50.2704110296101,9.442662471130737,0.0 50.27772026972424,9.4554185495736,0.0 50.30061968660411,9.419174629647651,0.0 50.3134338989555,9.398350843677145,0.0 50.330902260659,9.396070867111032,0.0 50.34710327756438,9.365823178000584,0.0 50.41660380223247,9.344974529943373,0.0 50.42288128194858,9.245267930092574,0.0 50.42450902384603,9.234516048623957,0.0 50.421660438811095,9.224935164146977,0.0 50.415420082407365,9.218334999285055,0.0 50.40619370176144,9.159039969799737,0.0 50.39988345120526,9.134129670159584,0.0 50.38861790491299,9.116032443925288,0.0 50.38196590399061,9.085373613598946,0.0 50.373828204075195,9.060876585432112,0.0 50.374851912213195,9.039245421406951,0.0 50.37455942642779,9.033894956807094,0.0 50.36909604401242,9.032055311810234,0.0 50.34884219264727,9.036714437078075,0.0 50.34206593823363,9.028913111048201,0.0 50.338055046494205,9.028371352296126,0.0 50.32394508151426,9.03866476858554,0.0 50.31439772920148,9.016777715001732,0.0 50.30756222761449,9.006886141097945,0.0 50.30215231393127,8.999211834250447,0.0 50.30015521042514,8.987558257185748,0.0 50.29616075185897,8.975449906381932,0.0 50.29107641039998,8.972493877077715,0.0 50.27792723722931,8.94907302951354,0.0 50.27618342766435,8.937021525427118,0.0 50.274948190575785,8.92258245921037,0.0 50.25656116848032,8.893022166168203,0.0 50.24522017796395,8.85641288016981,0.0 50.23634884074695,8.855222008654989,0.0 50.22470113569143,8.860339308210316,0.0 50.20947108695584,8.860934343042329,0.0 50.20672916183294,8.839751103022607,0.0 50.20094013589099,8.796432567251937,0.0 50.197435910668744,8.790006191066185,0.0 50.1946134041465,8.79057185680632,0.0 50.18875997039989,8.791839840630303,0.0 50.18371958792864,8.791637049898368,0.0 50.17642594359777,8.789065201919588,0.0 50.17596274342498,8.78995123147805,0.0 50.17430232089517,8.792046274117968,0.0 50.17337983900064,8.792936667239935,0.0 50.173916557905876,8.7938270603619,0.0 50.173195340484554,8.794979333813854,0.0 50.17431909312838,8.796367299562801,0.0 50.17334629386889,8.798724222532709,0.0 50.17103162290417,8.799588427621675,0.0 50.16957231619278,8.79793858154274,0.0 50.16703939070253,8.793905624460896,0.0 50.16438890109903,8.794534137252873,0.0 50.16375141964782,8.79050118017103,0.0 50.16162082784406,8.789139402455083,0.0 50.16103364018217,8.79076306050102,0.0 50.1591545911941,8.790527368204028,0.0 50.1596579151296,8.787280052112155,0.0 50.15856737323834,8.783220906997313,0.0 50.157225133682765,8.783011402733322,0.0 50.1560842004315,8.7835875394593,0.0 50.15568151160696,8.781728189116372,0.0 50.138275414238024,8.77894862521831,0.0 50.13670242407733,8.77838227975314,0.0 50.13690217682525,8.784467717601034,0.0 50.13534508071917,8.794250560713733,0.0 50.13391419097039,8.802588957192343,0.0 50.13357750481077,8.81237180030504,0.0 50.13319873004944,8.816967766868055,0.0 50.12932663828693,8.816967766868055,0.0 50.12356000792097,8.817755646850285,0.0 50.12381257562391,8.812306143639855,0.0 50.12170780404554,8.807447550416098,0.0 50.120865869500825,8.806725327099054,0.0 50.11556134136147,8.803179867179015,0.0 50.11324568846011,8.805346537130145,0.0 50.106340167703365,8.80816977373314,0.0 50.10335027363762,8.817164736863607,0.0 50.100570768108895,8.819594033475484,0.0 50.09652756307581,8.818280900171766,0.0 50.090630610745976,8.820775853448833,0.0 50.08907200924542,8.82274555340441,0.0 50.08818737503363,8.82530616334666,0.0 50.0851963479583,8.842048612969064,0.0 50.07200832727764,8.835811229776404,0.0 50.07049126160658,8.824386970034057,0.0 50.069570879337796,8.78607195954587,0.0 50.0601144750599,8.77637532098599,0.0 50.048860122033034,8.752320198404746,0.0 50.01891548545801,8.76089799405387,0.0 50.01232515932821,8.762762732238464,0.0 50.00777131509019,8.767797525336864,0.0 50.00381631081293,8.766492208607648,0.0 50.002510604252436,8.768218421614016,0.0 50.00128762337993,8.775689982557171,0.0 50.002779059304025,8.78613160499326,0.0 50.00131196288862,8.790503627643895,0.0 49.99779764073278,8.794819888766732,0.0 49.99865804458652,8.799875040273319,0.0 50.00348400921596,8.811082687365706,0.0 50.00061646545155,8.81260605687341,0.0 50.00033669592648,8.815217547458044,0.0 49.99781869693746,8.815326359565736,0.0 49.99648969985931,8.811844372119557,0.0 49.99383159550032,8.813150117411876,0.0 49.994111402878666,8.819134783334993,0.0 49.98877967758542,8.820035779675596,0.0 49.98385558936126,8.814211125129365,0.0 49.97969399505043,8.814642581021678,0.0 49.9713003514494,8.818202092133264,0.0 49.96810899538112,8.812377437587031,0.0 49.96519496372066,8.813456077317817,0.0 49.962003202814614,8.82165373927177,0.0 49.96255830686967,8.839127702910474,0.0 49.96380726759058,8.846246725133646,0.0"
    let hrCoord = "8.74344999062572,50.04918999904961,0 8.751160000623477,50.0240599912103,0 8.754709994364463,50.01274999536513,0 8.757490069155791,50.00470163525198,0 8.762733428456755,50.00328437886608,0 8.764625619546589,50.00285518138227,0 8.770820082372893,50.00139911723744,0 8.772673791350965,50.00094266817716,0 8.77914111075552,49.99943225272401,0 8.799229992240086,49.99467000542582,0 8.806542356164457,49.99340340620989,0 8.809790356707138,49.99206374565822,0 8.826786125387034,49.98576635583486,0 8.828778769472731,49.98395187720181,0 8.831507689809753,49.98097186169272,0 8.830959149889964,49.97966245881608,0 8.829928960125969,49.9778595543125,0 8.830465197667758,49.9768960693446,0 8.830997048231009,49.97595153004782,0 8.83394675737425,49.97397788936575,0 8.836460977629683,49.97217362668664,0 8.83910802473485,49.96908500881526,0 8.840122212590229,49.96799437118023,0 8.841363208739749,49.9668289258026,0 8.842263170839054,49.96603842183582,0 8.843115976927399,49.96501359037988,0 8.846351833332184,49.9627537294549,0 8.849460013049532,49.95986999442856,0 8.850210000098501,49.95926998619805,0 8.850310012566743,49.95926999267505,0 8.865430008710506,49.95390999382382,0 8.891260000848778,49.94599000213314,0 8.908000004981322,49.96970998840088,0 8.960089986326672,49.98685999774121,0 9.028550004173386,49.98896999905399,0 9.051090005623092,49.98967000446294,0 9.063509599805697,49.99349370576994,0 9.058420003685276,50.00014000125238,0 9.053349983587822,50.00350000123728,0 9.043370001095513,50.00774999264858,0 9.039590003958708,50.01043999620001,0 9.037680002386232,50.0117099996073,0 9.035770000347792,50.01386000058577,0 9.035669991374673,50.01396999599814,0 9.033520003630585,50.01612999279517,0 9.03276999394412,50.01722999549925,0 9.031890007343058,50.01854999140686,0 9.031080010354554,50.02017000106182,0 9.030590017083911,50.02186000123651,0 9.030160003507783,50.02427999548287,0 9.030019994132037,50.02558000112721,0 9.03012998938997,50.02655999787962,0 9.030250000259972,50.02768999624666,0 9.03161000235999,50.03279999301565,0 9.032170004807355,50.0358999942769,0 9.032050012345229,50.03739999588439,0 9.031490007969513,50.03882000226924,0 9.030510014244126,50.04000000228209,0 9.029080001550227,50.04103999783368,0 9.029060008563725,50.04106000232493,0 9.028230008798136,50.04156999577097,0 9.026240009262718,50.04279999711334,0 9.024160016072742,50.04365000084064,0 9.023260013005588,50.04386000537015,0 9.019740018159242,50.04436999886058,0 9.017760016210493,50.04465999781608,0 9.013460007365307,50.04553999270155,0 9.011000004708681,50.04575999839583,0 9.00992999888183,50.04561998877342,0 9.008480008624115,50.04557998927629,0 9.005680013424682,50.04550000056366,0 8.986750005661659,50.04149000275402,0 8.978420013141989,50.04530999078934,0 8.976519982950132,50.0514200003693,0 8.982709988738773,50.05690999839843,0 8.986820008613575,50.06226000595279,0 8.987800012679832,50.06321000762544,0 8.989760009887313,50.06513000580236,0 8.990918897321578,50.0669106073983,0 8.9955775301496,50.06892022836311,0 8.998568988963262,50.06893433107653,0 8.999404770882135,50.06967750682338,0 8.99907863971808,50.070980702649,0 8.998540008233778,50.07845000669163,0 8.999480727122569,50.07942879191786,0 8.998936147196799,50.08570047236539,0 8.997979981825159,50.09309999923527,0 9.009470009726822,50.10552999340482,0 9.014060011409995,50.1093099951841,0 9.018390009198136,50.11148999968705,0 9.022280002796611,50.11211998982098,0 9.030180002730933,50.11276999957308,0 9.036709983650752,50.11439000225139,0 9.03690999604585,50.11440999933917,0 9.03949998805237,50.11470999733926,0 9.041409993836245,50.11494000056713,0 9.043569987178085,50.11518999631258,0 9.047210001617215,50.1158499945509,0 9.05294999694393,50.11569999345475,0 9.055779984887241,50.11657998906307,0 9.062110001201511,50.11675000135271,0 9.065399990762362,50.11700000561905,0 9.071007549127517,50.11922371673292,0 9.076630005563471,50.1161700007584,0 9.077190003068765,50.115860002529,0 9.090149996865359,50.11705999751791,0 9.097210008411061,50.12491999822693,0 9.097229998645521,50.12493000896303,0 9.097450000598039,50.12500001156322,0 9.100480005609697,50.12522999907779,0 9.101720017827175,50.12503999964554,0 9.104050013666759,50.12524999543405,0 9.106250000414615,50.1255599977141,0 9.106320013833074,50.12556999995883,0 9.11103000773252,50.12645000491829,0 9.112480002104718,50.12650000158009,0 9.118190018941625,50.12683999405951,0 9.11824001589531,50.12684999758118,0 9.119370021092625,50.12667000066124,0 9.120230000806123,50.12640000226687,0 9.121240007930481,50.12608999931724,0 9.122669997795143,50.1251799912294,0 9.125470008557192,50.12341000006478,0 9.129070017631035,50.12185001116103,0 9.134449996804847,50.11918999923478,0 9.134810008978569,50.11920999602372,0 9.134890001642818,50.11917000907523,0 9.138790008249355,50.11738000700088,0 9.143799995794254,50.11436000115628,0 9.153480013609004,50.1177800012857,0 9.174246170565004,50.11909431140469,0 9.178573419936008,50.12093255348469,0 9.187279993149794,50.12424999394975,0 9.190869996641968,50.12840999555607,0 9.190140006470225,50.12852999126118,0 9.189239992099489,50.12886999244492,0 9.18859001078415,50.13008000182714,0 9.188529991233642,50.13068000290921,0 9.188270001636816,50.13122999393559,0 9.187689999246999,50.13169000225765,0 9.186230008527531,50.13220000137167,0 9.184630011698792,50.13358999951587,0 9.184889997736651,50.13418000049787,0 9.184539995171448,50.13461999983619,0 9.183930004443509,50.13530000248941,0 9.183950002803973,50.135519998149,0 9.183550012978392,50.13613999783406,0 9.183569996231322,50.13690999406499,0 9.18340000738119,50.13743999921365,0 9.183380014260379,50.13787000106181,0 9.190900001716518,50.139159993859,0 9.193700011750751,50.13930999759451,0 9.19464001127551,50.13981000038044,0 9.195470000586393,50.14028998889953,0 9.196120007766066,50.14010998828039,0 9.196500004917223,50.14001998961674,0 9.197040001756861,50.14030999242293,0 9.199190010294648,50.14073999922731,0 9.200440003999781,50.14084998669727,0 9.201030013515277,50.14057999207999,0 9.203099982949214,50.14095000662204,0 9.205299986371029,50.14180000860304,0 9.206359985346644,50.142070008102,0 9.207580000543322,50.14207999782826,0 9.209859987405412,50.14242999853374,0 9.210280003353484,50.1423899976447,0 9.210799991009644,50.14220999766564,0 9.21077998816282,50.1435000057295,0 9.211479992867652,50.14477000460019,0 9.214099996581536,50.14445000468506,0 9.218959999344854,50.14661000455769,0 9.221479995862085,50.14939999389495,0 9.225630001631478,50.14855000094843,0 9.23032000616189,50.14765999014259,0 9.232970002625747,50.14675999789494,0 9.233769992622126,50.14662999691726,0 9.235819988502438,50.14626998818617,0 9.240770008871321,50.14369999990418,0 9.250599997697448,50.14088999946022,0 9.253009998704444,50.13936000061953,0 9.257409988922282,50.13877999779094,0 9.258539987369192,50.13882999185971,0 9.261029985191303,50.13894999352718,0 9.26667000168456,50.13956998800712,0 9.270219998473655,50.14184999133448,0 9.271399995864714,50.14201999982645,0 9.276349996686779,50.14272000476213,0 9.281169993334959,50.14154000700376,0 9.281790004285499,50.14151999702619,0 9.28505000417664,50.14177000501881,0 9.294040000079619,50.13933999639883,0 9.298069993519123,50.13708999386204,0 9.304220003766982,50.13527001045085,0 9.307460002912588,50.13401000172517,0 9.3099899963248,50.13394000197258,0 9.313210010638157,50.13483999891268,0 9.317820007007097,50.13657000315733,0 9.32087000656426,50.13792000208673,0 9.327880001083775,50.14102000396739,0 9.332359997806428,50.13920999562789,0 9.335839993928891,50.13698998995007,0 9.336390008811645,50.13671999110127,0 9.339360000403303,50.13273000018819,0 9.341829993133189,50.1314900069315,0 9.349580011888042,50.13060000490764,0 9.357900000002719,50.1309800011009,0 9.364500003588615,50.1308599976779,0 9.373790012600809,50.13085001035299,0 9.374940014378062,50.13078000272372,0 9.376428136780461,50.13060459037479,0 9.375980001360301,50.12583000875451,0 9.380379996288745,50.12133000326065,0 9.382299998223088,50.11936999839725,0 9.384039990002806,50.11687999723922,0 9.386960003003646,50.1104799943284,0 9.392690004434337,50.10208999192354,0 9.39389999043634,50.09908999048587,0 9.39441999471242,50.09769998717655,0 9.395280005887983,50.09654000569314,0 9.398049991407143,50.09346000849757,0 9.399579989575344,50.09215000204925,0 9.401979985879303,50.08986000850655,0 9.404899991283124,50.08774999576386,0 9.408080014793335,50.08628000072305,0 9.410360008182412,50.08474000191088,0 9.412109999917282,50.08400999347561,0 9.414540018844249,50.08372999722369,0 9.416490008385686,50.08366999838898,0 9.419320007524787,50.08447000100686,0 9.421189997530622,50.08477000057801,0 9.421729983690359,50.0848199989533,0 9.422609992020972,50.0848999888351,0 9.424210000439418,50.08487999332674,0 9.426209991743331,50.08466000872539,0 9.426650001161059,50.08445000438933,0 9.427099982830001,50.08406000313204,0 9.427139990696315,50.08406000087415,0 9.427652721408091,50.08399998652941,0 9.433353179705726,50.08402470953537,0 9.435354143826626,50.08505389047933,0 9.436088619491672,50.08522879361796,0 9.438430526576967,50.08697187563428,0 9.440104382080714,50.08699613917442,0 9.445369991346254,50.08990999762638,0 9.447630008726817,50.08999999740072,0 9.450919994621692,50.09031000114513,0 9.452070007349786,50.0907899928403,0 9.454410007723135,50.09108999360934,0 9.460950000938215,50.09060999515631,0 9.462300008199286,50.0910400032701,0 9.463400013428359,50.09106000139991,0 9.464200003484436,50.09124000726924,0 9.465530012619313,50.09153000694008,0 9.468800008351925,50.09136999634158,0 9.470470017914517,50.09143000256835,0 9.472329999587991,50.09161000390467,0 9.473620019051696,50.09215000133324,0 9.474920003056653,50.09292999912699,0 9.476870017014669,50.09377000009614,0 9.478919993936698,50.09430999575569,0 9.481419984146658,50.0947799948108,0 9.483559984403359,50.09436999910113,0 9.485509981915525,50.09412999558609,0 9.48570999585527,50.09412000396971,0 9.487359987494594,50.09400999892856,0 9.490429987404328,50.09412999491645,0 9.493209983692267,50.09459999267533,0 9.495159986345893,50.09531999217066,0 9.496829992324216,50.09657999894574,0 9.498319988002368,50.09723999301944,0 9.49989998994757,50.09718000287389,0 9.501569988519432,50.09664000069188,0 9.502680008048856,50.09603999797577,0 9.504629999438921,50.09574000956214,0 9.506760006872188,50.09622000084823,0 9.507140003812562,50.09742000406875,0 9.507229996886643,50.09819000714014,0 9.50669001130621,50.09907000222062,0 9.507150006893196,50.09931999902311,0 9.50923999463094,50.09956000551333,0 9.512149998788429,50.09941000120356,0 9.512820008669731,50.0990800014653,0 9.513100009864747,50.09966999606637,0 9.518980005320945,50.10612000219624,0 9.523749987770032,50.10609999798064,0 9.509789996972424,50.14568999412518,0 9.510159999038692,50.17993000361417,0 9.523900010995279,50.20862999333181,0 9.497610010511844,50.23025999464183,0 9.465759992135864,50.23500999995167,0 9.427309998664841,50.28948999496187,0 9.39269000551494,50.33608999941583,0 9.354189991318192,50.3790699957637,0 9.352780014398681,50.43896001016936,0 9.340660001490294,50.4547299998002,0 9.312470000603268,50.45978998838441,0 9.299499989859983,50.45929999898711,0 9.289360011907432,50.45382000673616,0 9.262010012800003,50.40678999774384,0 9.261579990204883,50.37911000208434,0 9.163230003564165,50.3586100105654,0 9.131989998719183,50.34574999621018,0 9.062800000324119,50.32285000000135,0 9.054520002404079,50.31968000467632,0 9.043719996102452,50.32165000058219,0 9.029761680801087,50.32841918451295,0 9.031495109187416,50.31272183455483,0 8.995839452582921,50.30250677011594,0 8.987631336027818,50.30006956026648,0 8.975659492935346,50.29547621167906,0 8.958677331367527,50.28630458701393,0 8.94929415829554,50.28125262914848,0 8.925608601416379,50.27595619488345,0 8.912707196248872,50.26838770369456,0 8.900321281931532,50.26109642163877,0 8.883946027953995,50.2514976812132,0 8.857519269942278,50.24799938088881,0 8.843243933535447,50.24615324039392,0 8.843337919829239,50.24519622029486,0 8.844352709690199,50.23641778130721,0 8.848844132593994,50.23205190395576,0 8.859845616898108,50.22335260208263,0 8.858916319673716,50.22092275483271,0 8.854913957622637,50.21029795607451,0 8.828012506624319,50.20845601508016,0 8.792170003634453,50.19689999140842,0 8.792079997664727,50.19360999114326,0 8.792090007857588,50.19360999589294,0 8.792080005707826,50.1933399969401,0 8.792139995449546,50.18931998969914,0 8.792109992014069,50.18893999697589,0 8.792080000426376,50.18849999434099,0 8.792679986357536,50.18761999891223,0 8.792780002183326,50.18624999797653,0 8.792809992943038,50.1838499994514,0 8.78973001669163,50.17977998885446,0 8.789990009297167,50.17618999887759,0 8.790029994197257,50.17608999350487,0 8.790400013363707,50.1756399975125,0 8.795660002988884,50.17271001146669,0 8.800430009638776,50.17120000991109,0 8.800030003318794,50.17109000869478,0 8.80016999786298,50.17019999937831,0 8.800160007579409,50.16933000575472,0 8.798210009160762,50.16943000004811,0 8.798119992086578,50.16853000305719,0 8.797839987310598,50.16741000349072,0 8.795570001629894,50.16727000126137,0 8.794420002285929,50.16686998641285,0 8.794869986905674,50.16460000764227,0 8.794839990093175,50.16445000317964,0 8.795069987661732,50.1639400006493,0 8.794959989515347,50.16379001174276,0 8.794649984336918,50.1638499933831,0 8.793969990776221,50.1630399881526,0 8.791709999964247,50.16336999710949,0 8.790470002191894,50.16343999740508,0 8.790340002022822,50.16295999319533,0 8.789559999991919,50.16145999765807,0 8.790999987988663,50.16111999166834,0 8.790610009406777,50.15989999880812,0 8.790650015217244,50.1588999906634,0 8.789859999743616,50.15894999130114,0 8.789490009437273,50.1588699891094,0 8.787180014898484,50.1593899986436,0 8.786940002233044,50.15923998964287,0 8.786050003904881,50.15883999909401,0 8.785669999219367,50.15878999189965,0 8.785020015562498,50.15871999044146,0 8.783420004936072,50.15842000281186,0 8.783420004789116,50.15770999268128,0 8.783470016746801,50.15722999454914,0 8.783580009619461,50.15699999220811,0 8.784100012663544,50.15583999017743,0 8.782219996826949,50.15551999603872,0 8.782360012243217,50.15504999142234,0 8.782400002741433,50.15412000308445,0 8.782440000873432,50.1538799934948,0 8.782640002335953,50.15348999380655,0 8.782690004419679,50.15288999409114,0 8.782599997613589,50.15168999527978,0 8.782499994394218,50.15002000083744,0 8.782429997799444,50.14841999909195,0 8.782339993684557,50.14642999456324,0 8.782259999824177,50.14484999042134,0 8.782299991382095,50.14447000212288,0 8.782329990151951,50.14413999428914,0 8.782350006299202,50.14389999847396,0 8.782369988407282,50.14374000265145,0 8.78239000173469,50.14349999358076,0 8.782439996314656,50.14299999406526,0 8.782439988694478,50.1429199972104,0 8.782470000856153,50.14267999368212,0 8.782480003228939,50.14251999070935,0 8.782579988275536,50.14241999306769,0 8.783599991220438,50.14111999489931,0 8.784448782893042,50.1405347806952,0 8.784710985537078,50.14005921419489,0 8.784836043163592,50.13976715250182,0 8.784909988556111,50.13939000291317,0 8.784920000629107,50.13928999326227,0 8.784719982911794,50.13919999095377,0 8.77993000857648,50.13822000388137,0 8.779900001379451,50.13804999861398,0 8.779870002850776,50.13781999822846,0 8.779780007883684,50.13723999143221,0 8.781680019517596,50.13739999790258,0 8.785470012109293,50.13728999853527,0 8.790470012031696,50.13658999710204,0 8.795220001648541,50.13552000122132,0 8.796740008487991,50.13528000323189,0 8.79849000489105,50.13476000552564,0 8.801570014121655,50.13428000627525,0 8.809370015405136,50.13413999475548,0 8.806000008358936,50.12600000470178,0 8.800339551601194,50.11398120331311,0 8.798730684364719,50.11222326889193,0 8.803275711144671,50.10682728967874,0 8.806256200740775,50.10212970751106,0 8.809628959422538,50.09681686079544,0 8.812426567410549,50.0923736430835,0 8.814529068369041,50.08870301933311,0 8.815564740819466,50.08674190292712,0 8.816983190135087,50.08430003950284,0 8.816736771584527,50.08396773922301,0 8.819257293064814,50.08161630263398,0 8.825500005361317,50.07011000106249,0 8.825430011347251,50.06916000981824,0 8.825340007617122,50.06887000547547,0 8.825010007651045,50.06831000400231,0 8.824340007935508,50.06807000324666,0 8.824190003312365,50.0678600107172,0 8.823980000479738,50.06767000416784,0 8.823560009647329,50.06769000265334,0 8.819140000891526,50.06794999086822,0 8.784360013267232,50.06681998757962,0 8.778350008752462,50.05852000117123,0 8.769430002590275,50.05571000525481,0 8.74344999062572,50.04918999904961,0"
    #showBorder(hrCoord, "rgba(0, 0, 255, 1)", false)
    showBorder(hrCoordReal, "rgba(255, 0, 0, 1)")
    proc showBorderDistrict(borderData, strokeColor, fillColor: string) =
        var geocodingParameters = GeoServiceParameters()
        geocodingParameters.jsonattributes = 1
        geocodingParameters.searchtext = ""
        geocodingParameters.country = "DEU"
        geocodingParameters.state = "Hessen"
        geocodingParameters.additionalData = "IncludeShapeLevel,district"
        let bordersStr = borderData
        consLog("geoArea: ", bordersStr.split NewLines)
        let arrArea = (bordersStr.split NewLines).map(
            proc(item: string): string =
                result = (item.split ",").map(
                    proc(item: string): string =
                        result = item.strip
                ).join(",")
        ).join(",").split ","
        consLog("geoArea: ", arrArea[0])
        let onErrGeo =
            proc(e: JSObj) =
                discard
        let onResGeoForMap = proc(r: JsObject) =
            let res = r.response.view[0].result[0]
            let loc = res["location"]
            consLog("Location+:", loc)
            let shp = $loc.shape.value.to(cstring)
            let
                pOpt = PolygonOptions(
                            style: SpatialStyle(
                                        strokeColor: cstring(strokeColor),
                                        fillColor: cstring(fillColor),
                                        lineWidth: 5
                                    ),
                            zIndex: -999
                        )
                pl = H.map.newPolygon(shp.toGeometry(), pOpt)
            map.addObject(pl)
            #consLog("geoArea::: ", r)
        for city in arrArea:
            let arrCity = (city.split ">")
            let isCity = (arrCity.len == 2 and arrCity[1] == "city")
            if isCity:
                geocodingParameters.additionalData = "IncludeShapeLevel,city"
            else:
                geocodingParameters.additionalData = "IncludeShapeLevel,district"
            closureScope:
                let c = arrCity[0]
                let additionalData = geocodingParameters.additionalData
                let onResGeo = proc(r: JsObject) =
                        let res = r.response.view[0].result[0]
                        let matchLvl = $res.matchLevel.to(cstring)
                        let loc = res["location"]
                        consLog("location:", loc.displayPosition.latitude.to(float))
                        #if matchLvl == "city" and c != loc.Address.City.to(cstring):
                            #window.alert("Not city: " & c)
                        #elif matchLvl == "district" and c != loc.Address.District.to(cstring):
                            #window.alert("Not district: " & c)
                        #[if matchLvl != "city" and matchLvl != "district":
                            window.alert(matchLvl & " is Not district and Not city: " & c)
                            consLog("geoArea::: ", matchLvl, c)
                        else:]#
                        let typeShp =
                                if isUndefined(loc.shape):
                                    "city"
                                else:
                                    "district"
                        #if typeShp == "city":
                            #conslog("geoArea: shape: ", c, loc.Shape.Value.to(cstring))
                        var reverseGeocodingParameters = ReverseGeoServiceParameters()
                        reverseGeocodingParameters.jsonattributes = 1
                        reverseGeocodingParameters.prox = $(loc.displayPosition.latitude.to(float)) & "," & $(loc.displayPosition.longitude.to(float)) & ",1"
                        reverseGeocodingParameters.mode = "retrieveAddresses"
                        reverseGeocodingParameters.locationattributes = "none"
                        reverseGeocodingParameters.maxResults = 1
                        reverseGeocodingParameters.additionalData = additionalData

                        geocodingParameters.searchtext = c
                        geocodingParameters.additionalData = additionalData
                        conslog("geocodingParameters:", geocodingParameters)
                        geocoder.reverseGeocode(reverseGeocodingParameters, onResGeoForMap, onErrGeo)
                geocodingParameters.searchtext = arrCity[0]
                geocoder.geocode(geocodingParameters, onResGeo, onErrGeo)
    #[showBorderDistrict("""63110 Rodgau Rollwald,63322 Rödermark Waldacker,63128 Dietzenbach ,63150 Heusenstamm ,63179 Obertshausen ,63073 Offenbach am Main Bieber,63075 Offenbach am Main Waldheim,63075 Offenbach am Main Biebernsee,63477 Maintal Bischofsheim,61138 Niederdorfelden ,61137 Schöneck Oberdorfelden,61137 Schöneck Kilianstädten,61130 Nidderau Heldenbergen,61130 Nidderau Eichen,63674 Altenstadt Höchst,63674 Altenstadt Oberau,63674 Altenstadt Waldsiedlung,63674 Altenstadt Lindheim,63674 Altenstadt Enzheim,63654 Büdingen Düdelsheim,63654 Büdingen Rohrbach,63654 Büdingen Aulendiebach,63654 Büdingen Dudenrod,63699 Kefenrod Bindsachsen,63699 Kefenrod ,63699 Kefenrod Burgbracht,63633 Birstein Bössgesäß,63633 Birstein Illnhausen,63633 Birstein Kirchbracht,63633 Birstein Völzberg,63633 Birstein Lichenroth,63633 Birstein Wettges,63628 Bad Soden-Salmünster Schönhof,63628 Bad Soden-Salmünster Kerbersdorf,63628 Bad Soden-Salmünster Ahl,63628 Bad Soden-Salmünster Alsberg,63637 Jossgrund Burgjoß,63637 Jossgrund Oberndorf,63637 Jossgrund Pfaffenhausen,63639 Flörsbachtal Lohrhaupten,63639 Flörsbachtal Kempfenbrunn,63639 Flörsbachtal Mosborn,63639 Flörsbachtal Flörsbach,63599 Biebergemünd Roßbach,63599 Biebergemünd Lützel,63589 Linsengericht>city,63579 Freigericht Horbach,63579 Freigericht Neuses,63579 Freigericht Somborn,63538 Großkrotzenburg ,63512 Hainburg Klein-Krotzenburg,63500 Seligenstadt ,63533 Mainhausen Mainflingen,63533 Mainhausen Zellhausen,63110 Rodgau Nieder-Roden,63517 Rodenbach Oberrodenbach,63599 Biebergemünd Bieber""",
                "rgba(0, 0, 255, 1)",
                "rgba(0, 0, 255, 0.1)"
    )]#
    showBorderDistrict("""63688 Ober-Seemen,63697 Merkenfritz,63697 Hirzenhain,63683 Lißberg,63683 Eckartsborn,63691 Bobenhausen,63683 Wippenbach,63683 Selters (Ortenberg),63683 Bleichenbach,63654 Büdingen>city,63674 Enzheim,63674 Lindheim,63674 Oberau,63674 Höchst,61130 Eichen,61130 Nidderau Heldenbergen,61130 Windecken,61137 Schöneck,61137 Oberdorfelden,61138 Niederdorfelden>city,63477 Maintal>city,63165 Mühlheim am Main>city,63075 Waldheim,63179 Obertshausen>city,63150 Heusenstamm>city,63128 Dietzenbach,63322 Waldacker,63322 Rödermark Ober-Roden,63110 Rodgau>city,63533 Mainhausen>city,63538 Großkrotzenburg>city,63517 Rodenbach>city,63579 Neuses,63579 Horbach,63589 Waldrode,63599 Biebergemünd>city,63639 Flörsbachtal>city,63637 Pfaffenhausen>city,63628 Alsberg,63628 Kerbersdorf,63628 Schönhof,63633 Wettges""",
                "rgba(255, 0, 0, 1)",
                "rgba(255, 0, 0, 0)"
    )
    #[showBorderDistrict("""63688 Gedern Ober-Seemen, Hirzenhain, Merkenfritz, Eckartsborn, Bobenhausen, Wippenbach, Selters (Ortenberg), Bleichenbach, 63654 Rohrbach, Enzheim, Lindheim, Oberau, 63674 Höchst, Eichen, Nidderau Heldenbergen, Windecken, Schöneck Kilianstädten, Niederdorfelden, Wettges, Schönhof, Alsberg, Burgioss, Jossgrund, Lohrhaupten, Kempfenbrunn, Mosborn, Lützel, Waldrode, Horbach, Neuses, Rodenbach, Großkrotzenburg, Froschhausen, Mainhausen, Zellhausen, Rödermark, Waldacker, Dietzenbach, Heusenstamm, Obertshausen, Waldheim, Mühlheim, 63477 Bischofsheim, Niederdorfelden""",
                "rgba(255, 0, 0, 1)",
                "rgba(255, 0, 0, 0.1)"
    )]#


proc loadLinks(e: kdom.Event) =
    let pE = cast[PointerEvent](e)
    consLog("PointerEvent: ", e)
    mainGroup.removeAll()
    for k, v in allLinks.mpairs:
        v.addedToMap = false        
    let geoPoint = map.screenToGeo(pE.currentPointer.viewportX, pE.currentPointer.viewportY)
    var reverseGeocodingParameters = ReverseGeoServiceParameters()
    reverseGeocodingParameters.jsonattributes = 1
    reverseGeocodingParameters.prox = $geoPoint.lat & "," & $geoPoint.lng & ",1"
    reverseGeocodingParameters.mode = "retrieveAddresses"
    reverseGeocodingParameters.maxResults = 1
    reverseGeocodingParameters.additionaldata = "SuppressStreetType,Unnamed"
    reverseGeocodingParameters.locationattributes = "linkInfo"
    reverseGeocodingParameters.additionalData = "IncludeShapeLevel,city"
    var rgcp = cast[JsObject](reverseGeocodingParameters)
    #consLog(e.currentPointer, geoPoint, rgcp.additionaldata, reverseGeocodingParameters)

    
    proc parseTiles(tiles: seq[JsObject]) =
        when true:
            for t in tiles:
                let rows = t.Rows.to(seq[JsObject])
                let meta = t.Meta.to(JsObject)
                let tileId = @[$meta.tileX.to(cstring), $meta.tileY.to(cstring), $meta.level.to(cstring), $meta.layerName.to(cstring)].join("_")
                consLog("Tiles: ", t, rows)
                for r in rows:
                    let linkId = ($r.LINK_ID.to(cstring)).parseInt()
                    if allLinks.hasKeyOrPut(linkId, Link(linkId: linkId)) and
                                allLinks[linkId].readOnly:
                        continue
                    consLog("Row: ", linkId, r)
                    if r.NAMES.to(bool) and not r.NAME.to(bool):
                        var strName = $(r.NAMES.to(cstring))
                        #if (strName.find "L3008") != -1 or (strName.find "Anschlussstelle Erlensee") != -1:
                        #if (strName.find "Maintaler Str") != -1 or (strName.find "Anschlussstelle Erlensee") != -1:
                        #var seqNames = strName.split("\u001D")
                        #consLog("street name: ", "-----------" , seqNames[seqNames.high].split("\u001E")[0].replace("GERBN", ""))
                        for seqNames in strName.split("\u001D"):
                            consLog("street name: ", "ddddd")
                            let txt = seqNames.split("\u001E")[0].replace("GERBN", "")
                            if not (txt[0] in Digits) and not (txt[1] in Digits):
                                allLinks[linkId].name = allLinks[linkId].name & (" " & seqNames.split("\u001E")[0].replace("GERBN", ""))
                                allLinks[linkId].name = strip(allLinks[linkId].name)
                                break
                            for seqText in seqNames.split("\u001E"):
                                consLog("street name: ", seqText)
                                
                        #strName = $(r.NAMES.to(cstring))
                        #var seqNames = strName.split("\u001D")
                        #allLinks[linkId].name = seqNames[seqNames.high].split("\u001E")[0].replace("GERBN", "")
                    elif r.NAME.to(bool):
                        #if strName == "L3268": strName = "Maintaler Straße"
                        allLinks[linkId].geometry = newSeq[Coord]()
                        let lats = ( $(r.LAT.to(cstring)) ).split(",")
                        let lngs = ( $(r.LON.to(cstring)) ).split(",")
                        var lat0 = 0'f#lats[0].strip().parseFloat()
                        var lng0 = 0'f#lngs[0].strip().parseFloat()
                        #allLinks[linkId].geometry.add Coord(lat: cast[Latitude]( lat0 / 100_000.00 ),
                                                                #lng: cast[Longitude]( lng0 / 100_000.00) )
                        for i in 0..lats.high:
                            let strLat = if lats[i].strip() == "": lat0 else: lat0 + lats[i].strip().parseFloat()
                            let strLng = if lngs[i].strip() == "": lng0 else: lng0 + lngs[i].strip().parseFloat()
                            allLinks[linkId].geometry.add Coord(lat: cast[Latitude]( strLat / 100_000.00 ),
                                                                lng: cast[Longitude]( strLng / 100_000.00) )
                            lat0 = strLat
                            lng0 = strLng
                        #consLog("geometry: ", allLinks[linkId].geometry)
                    elif r.POSTAL_CODES.to(bool):
                        allLinks[linkId].cityId = ( $(r.ADMIN_PLACE_IDS.to(cstring)) ).split(",")[3].split(";")[0].parseInt
                        let distrPrt = ( $(r.ADMIN_PLACE_IDS.to(cstring)) ).split(",")[4]
                        consLog("distrPrt:: ", distrPrt)
                        let districtId = if distrPrt == "" or distrPrt[0] == ';': 0 else: distrPrt.split(";")[0].parseInt
                        allLinks[linkId].districtId = districtId + allLinks[linkId].cityId
                        #echo ( $(r.ADMIN_PLACE_IDS.to(cstring)) ).split(",")[4]
                        allLinks[linkId].postalCode = ( $(r.POSTAL_CODES.to(cstring)) ).split(";")[0]
                    elif r.REF_NODE_NEIGHBOR_LINKS.to(bool):
                        let rLinks = $(r.REF_NODE_NEIGHBOR_LINKS.to(cstring))
                        let nonRLinks = $(r.NONREF_NODE_NEIGHBOR_LINKS.to(cstring))
                        let refLinks = rLinks.split(",")
                        let nonRefLinks = nonRLinks.split(",")
                        consLog("xxxxxxxxx", cstring( $(r.NONREF_NODE_NEIGHBOR_LINKS.to(cstring)) ), "".split(",").len)
                        let refLinksInt = map(refLinks, proc (x: string): int =
                                            x.parseInt())
                        let nonRefLinksInt = if nonRLinks == "": newSeq[int]() else: map(nonRefLinks, proc (x: string): int =
                                            x.parseInt())
                        allLinks[linkId].neighborLinks = concat(refLinksInt, nonRefLinksInt)
                    let street = allLinks[linkId].name
                    if street != "" and allLinks[linkId].cityId == cityId:
                        if not allStreets.hasKeyOrPut(street, Street(name: street, links: newSeq[Link]())):
                            discard
                        allStreets[street].links.add allLinks[linkId]
                    discard cachedTiles.hasKeyOrPut(tileId, t)
                    #consLog("cachedTiles:: ", cachedTiles[tileId])
            for k, v in allLinks.mpairs:
                v.readOnly = true
                if v.name == "":
                    v.name = "uknown!!!"
            consLog("allLinks: ", allLinks, allStreets)
            allStreets.sort(sortStreetTbl)
            displayStreet allLinks[clckLinkId].name, tree = true
            if not allSectors.hasKey sectName:
                lastPostfix[postalCode] = lastPostfix[postalCode] - 1
            allSectors.sort(sortSectorTbl)
            #for k,v in pairs(allSectors):
            redraw()
        



    let onResRoadGeom =
        proc(res: JsObject) =
            consLog("onResRoadGeom::", res)
            var tiles = res.Tiles.to(seq[JsObject])
            for k, v in cachedTiles.pairs:
                tiles.add v
            parseTiles(tiles)
            #var group = newGroup()
            #mainGroup.addObject(group)
            
                
    let onErrRoadGeom =
        proc(e: JsObj) =
            discard
    let onResIndexRoadGeom =
        proc(res: JsObject) =
            let layerObj = res.Layers[0]
            let ePnt = getEntryPoint()
            let ePntType = getEntryPointType()
            consLog("onResIndexRoadGeom::", res)
            var prmsPde = newJsObject()
            var tXYs = newSeq[string]()
            let layers = @[
                        "ROAD_ADMIN_FC",
                        "ROAD_GEOM_FC",
                        "ROAD_NAME_FC",
                        "LINK_FC"
                        ]
            var rLayers = newSeq[string]()
            var levels = newSeq[string]()
            var tileXYs = layerObj.tileXYs.to(seq[JsObject])
            let level = layerObj.level.to(int)
            var allCrds = newSeq[tuple[lat: float, lng: float]]()
            var prevTxys = initTable[string, tuple[level, tx, ty: int]]()
            for xy in tileXYs:
                let
                    tx = xy.x.to(int)
                    ty = xy.y.to(int)
                    latlng = getCoord(level, tx, ty)
                prevTxys[@[$level, $tx, $ty].join("_")] = (level: level, tx: tx, ty: ty)
                allCrds.add( (lat: latlng[0], lng: latlng[1]) )
                consLog("onResIndexRoadGeom latlng:: ", latlng)
            for lvl in 10..13:
                for crd in allCrds:
                    let txy = getTileXY(lvl, crd[0], crd[1])
                    let k = @[$lvl, $txy[0], $txy[1]].join("_")
                    consLog("onResIndexRoadGeom latlng:: ", k, txy)
                    discard prevTxys.hasKeyOrPut(k, (level: lvl, tx: txy[0], ty: txy[1]))
            for lr in layers:
                #for xy in tileXYs:
                for lvlTxTy in values(prevTxys):
                    let
                        #xStr = $xy.x.to(int)
                        xStr = $lvlTxTy.tx
                        #yStr = $xy.y.to(int)
                        yStr = $lvlTxTy.ty
                        level = lvlTxTy.level
                        layerName = lr & $(level-8)
                    if cachedTiles.hasKey @[xStr, yStr, $level, layerName].join("_"):
                        continue
                    tXYs.add (xStr & "," & yStr)
                    levels.add $level
                    rLayers.add layerName
            if rLayers.len == 0:
                var tiles = newSeq[JsObject]()
                for k, v in cachedTiles.pairs:
                    tiles.add v
                parseTiles(tiles)
                return
            prmsPde.layers = rLayers.join(",").cstring
            prmsPde.levels = levels.join(",").cstring
            prmsPde.tilexy = tXYs.join(",").cstring
            prmsPde.meta = 1
            #echo layer
            consLog("tXYs:: ", prmsPde)
            #prmsPde.values = linkId.to(cstring)
            pdeService.request(ePnt.TILES, ePntType.JSON, prmsPde, onResRoadGeom, onErrRoadGeom)
    let onErrIndexRoadGeom =
        proc(e: JsObj) =
            discard
    let onResRevGeo =
        proc(r: JsObject) =
            let res = cast[JsObject](r)
            let mapReference = res.response.view[0].result[0].location.mapReference
            let cityShape = res.response.view[0].result[0].location.shape.value.to(cstring)
            let cityGeo = cast[MultiGeometry](toGeometry(cityShape))
            let address = res.response.view[0].result[0].location.address
            let linkId = mapReference.referenceId
            clckLinkId = linkId.to(int)
            let geoms =
                if isUndefined(cast[JsObject](cityGeo).getExterior):
                    cityGeo.getGeometries()
                else:
                    @[cast[AbstractGeometry](cityGeo)]
            consLog("toGeometry multi: ", geoms)
            #let geoms = cityGeo.getGeometries()
            for g in geoms:
                let lnStr = g.getExterior()
                consLog("revResp0::", res, lnStr)
                let
                    pOpt = PolylineOptions(
                                style: SpatialStyle(
                                            strokeColor: cstring"rgba(0, 255, 255, 1)",
                                            fillColor: cstring"rgba(0, 255, 255, 1)",
                                            lineWidth: 10
                                        )
                            )
                    pl = H.map.newPolyline(lnStr, pOpt)
                when true:
                    if cityId == 0:
                        map.addObject(pl)
            let
                revCityId = parseInt( $(mapReference.cityId.to(cstring)) )
                revPostalCode = $(address.postalCode.to(cstring))
            when true:
                if cityId != 0 and revCityId != cityId:
                    return
            cityId = revCityId
            postalCode = revPostalCode
            districtId = if mapReference.districtId.to(bool): parseInt( $(mapReference.districtId.to(cstring)) ) else: 0
            addrCity = $(address.city.to(cstring))
            addrDistr = if address.district.isUndefined or $(address.district.to(cstring)) == addrCity: "" else: $(address.district.to(cstring))
            discard lastPostfix.hasKeyOrPut(postalCode, 0)
            lastPostfix[postalCode] = lastPostfix[postalCode] + 1
            let pFix = lastPostfix[postalCode]
            var seqSectName = newSeq[string]()
            seqSectName.add postalCode & "-" & $pFix
            consLog("revResp::", linkId, cityId, districtId)
            #borderDistr.add @[postalCode, addrCity, addrDistr].join(" ")
            #consLog("borderDistr::", borderDistr.join(","))
            sectName = seqSectName.join(" ")
            let ePnt = getEntryPoint()
            let ePntType = getEntryPointType()
            var prmsPde = newJsObject()
            prmsPde.layer = cstring"ROAD_GEOM_FCn"
            prmsPde.attributes = cstring"LINK_ID"
            prmsPde.values = linkId.to(cstring)
            let zKey = "z" & addrCity & "-1"
            if not allSectors.hasKey(zKey):
                allSectors[zKey] = Sector(exclude: true, pFix: 1, city: "", postalCode: ("z" & addrCity), district: "")
            when true:
                pdeService.request(ePnt.INDEX, ePntType.JSON, prmsPde, onResIndexRoadGeom, onErrIndexRoadGeom)
    let onErrRevGeo =
        proc(e: JsObj) =
            discard
    geocoder.reverseGeocode(reverseGeocodingParameters, onResRevGeo, onErrRevGeo)#
    consLog("ep: ", pdeService)

map.addObject(mvStreetGrp)

var strGgeoPoint = newSeq[string]()
proc getPoint(e: kdom.Event) =
    let pE = cast[PointerEvent](e)
    let geoPoint = map.screenToGeo(pE.currentPointer.viewportX, pE.currentPointer.viewportY)
    let mrk = H.map.newMarker(geoPoint)
    map.addObject(mrk)

    strGgeoPoint.add [geoPoint.lat, geoPoint.lng, 0].join(",")
    consLog("points: ", strGgeoPoint.join(" "))

cast[kdom.EventTarget](map).addEventListener("tap", #[getPoint]# loadLinks, false)

geoArea()

addEventListener(cast[kdom.EventTarget](window), "resize", proc (e: kdom.Event) = cast[JsObject](map).getViewPort().resize());





consLog("Pixel:: ", pixelRatio)
consLog("Platform: ", platform)
consLog("uiDef:: ", uiDef, uiDef.getMap())
#consLog("Layers:: ", layerOpts, defLayers.vector.normal.map)

