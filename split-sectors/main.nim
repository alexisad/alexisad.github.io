# nim -r -d:ssl c main.nim
# nim -r --gc:orc -d:ssl c main.nim
# nim -r --gc:orc -d:ssl -d:release c main.nim
import tile, types, utils, pde
import httpclient, strutils, sequtils, strformat, uri, json, tables, parsecsv, std/streams, sugar
import flatty, supersnappy

const
    apikey = "***"
    hrCoordReal = "49.95856259839435,8.850124261434395,0.0 49.96396515545882,8.899470891953959,0.0 49.989107714500946,8.942093035419573,0.0 49.99375559635732,8.973836498540546,0.0 49.98852001928919,9.014720749471216,0.0 49.98595544705414,9.046298016450189,0.0 49.993374764204034,9.054906229836575,0.0 50.01241735811533,9.038966773881107,0.0 50.02965494688769,9.03186813780005,0.0 50.0384117586606,9.032281998108914,0.0 50.042818175748586,9.027509152282287,0.0 50.04441439462123,9.022565665862723,0.0 50.04644677958852,9.013523319190714,0.0 50.04425309054112,8.996242389995311,0.0 50.04241418571553,8.987752631175479,0.0 50.04476926168952,8.980317812800713,0.0 50.05134995729781,8.977353932502664,0.0 50.05405939323471,8.980217342282131,0.0 50.06044531552646,8.986546984952541,0.0 50.062896251887224,8.988757336361253,0.0 50.06734631621531,8.99182168717788,0.0 50.06673365070724,8.992977098141527,0.0 50.0668626335698,8.99398180332731,0.0 50.06718803495289,8.994414733080061,0.0 50.06771451792822,8.995464253486665,0.0 50.06829194422368,8.99569356046626,0.0 50.0688014322406,8.995790574957626,0.0 50.06906749605375,8.996778358869724,0.0 50.06879577129238,8.997378084816354,0.0 50.06905051330128,8.998956775175868,0.0 50.06930053266752,8.99941800765802,0.0 50.0695826597326,8.999881101814484,0.0 50.07118974475246,8.99940230955102,0.0 50.07246819127017,8.999262421160052,0.0 50.073681046891316,8.999278572803176,0.0 50.07593045003854,8.998761720223174,0.0 50.07685298579153,8.998697113650673,0.0 50.079516837714955,8.99906860144255,0.0 50.08036829651911,8.999048176213728,0.0 50.08163131412362,8.999132593752917,0.0 50.08380948509669,8.998839123161446,0.0 50.08398524097505,8.998457611392535,0.0 50.08529083589718,8.998731517277907,0.0 50.0858180853043,8.999103246693766,0.0 50.087745007018746,8.999113029046814,0.0 50.08994800500485,8.99887825257364,0.0 50.09095218700986,8.998614129041318,0.0 50.09268435151408,8.997880452562647,0.0 50.093989709477825,8.9992499819895,0.0 50.09529893546212,9.000556974921759,0.0 50.097739470199144,9.003266612926636,0.0 50.11201852058528,9.02981141216353,0.0 50.11661516874831,9.067234864827416,0.0 50.12025635598552,9.07282045477725,0.0 50.14215732616893,9.07477541125969,0.0 50.13214371793553,9.104686488157405,0.0 50.130002073318444,9.11819544464286,0.0 50.12962960360105,9.129525537179045,0.0 50.124042209958354,9.131849658724928,0.0 50.12329717485541,9.139257796152435,0.0 50.12525286726787,9.144487069630674,0.0 50.12804657496021,9.150297373495386,0.0 50.130455597090595,9.155493171369901,0.0 50.133915546952075,9.158535444434747,0.0 50.1367776800252,9.15868265119595,0.0 50.13741151788165,9.163817274408206,0.0 50.14339492987892,9.173004915543089,0.0 50.14755755017878,9.192392814174495,0.0 50.14648131805793,9.200345557307376,0.0 50.138180651937496,9.259625280641485,0.0 50.13309753499998,9.307707323856194,0.0 50.139325423584935,9.327568851365392,0.0 50.12993748742165,9.339142835021836,0.0 50.12858337744752,9.365496359295658,0.0 50.12641773051991,9.372735178643259,0.0 50.11574275323997,9.381663055838633,0.0 50.09423086055464,9.394210342707808,0.0 50.087113888846716,9.404106700966404,0.0 50.084234652636276,9.41068546866214,0.0 50.08332028837411,9.415072180815773,0.0 50.084109152691816,9.419263307077205,0.0 50.08422122075908,9.425175379748403,0.0 50.08359146921259,9.427138246524793,0.0 50.08359146921259,9.433746564671972,0.0 50.09022443676629,9.46096498397125,0.0 50.09085360543011,9.474022801340594,0.0 50.093517639965924,9.48311122533397,0.0 50.09417105978058,9.497057255254838,0.0 50.09552813400177,9.509122921590878,0.0 50.10598134317437,9.5205618000653,0.0 50.114221688388604,9.519935012203698,0.0 50.14498492404182,9.511705614500329,0.0 50.151057005957576,9.529820900852283,0.0 50.16355592364119,9.537067015393063,0.0 50.17319571327903,9.524804360016356,0.0 50.17694399525393,9.501393836115371,0.0 50.192469459564606,9.505852983525081,0.0 50.19496733876523,9.518673032328001,0.0 50.19962499700489,9.516589022864023,0.0 50.21399704559683,9.50504530922025,0.0 50.21870102145308,9.466106812451708,0.0 50.26614431812017,9.43139020351146,0.0 50.2704110296101,9.442662471130737,0.0 50.27772026972424,9.4554185495736,0.0 50.30061968660411,9.419174629647651,0.0 50.3134338989555,9.398350843677145,0.0 50.330902260659,9.396070867111032,0.0 50.34710327756438,9.365823178000584,0.0 50.41660380223247,9.344974529943373,0.0 50.42288128194858,9.245267930092574,0.0 50.42450902384603,9.234516048623957,0.0 50.421660438811095,9.224935164146977,0.0 50.415420082407365,9.218334999285055,0.0 50.40619370176144,9.159039969799737,0.0 50.39988345120526,9.134129670159584,0.0 50.38861790491299,9.116032443925288,0.0 50.38196590399061,9.085373613598946,0.0 50.373828204075195,9.060876585432112,0.0 50.374851912213195,9.039245421406951,0.0 50.37455942642779,9.033894956807094,0.0 50.36909604401242,9.032055311810234,0.0 50.34884219264727,9.036714437078075,0.0 50.34206593823363,9.028913111048201,0.0 50.338055046494205,9.028371352296126,0.0 50.32394508151426,9.03866476858554,0.0 50.31439772920148,9.016777715001732,0.0 50.30756222761449,9.006886141097945,0.0 50.30215231393127,8.999211834250447,0.0 50.30015521042514,8.987558257185748,0.0 50.29616075185897,8.975449906381932,0.0 50.29107641039998,8.972493877077715,0.0 50.27792723722931,8.94907302951354,0.0 50.27618342766435,8.937021525427118,0.0 50.274948190575785,8.92258245921037,0.0 50.25656116848032,8.893022166168203,0.0 50.24522017796395,8.85641288016981,0.0 50.23634884074695,8.855222008654989,0.0 50.22470113569143,8.860339308210316,0.0 50.20947108695584,8.860934343042329,0.0 50.20672916183294,8.839751103022607,0.0 50.20094013589099,8.796432567251937,0.0 50.197435910668744,8.790006191066185,0.0 50.1946134041465,8.79057185680632,0.0 50.18875997039989,8.791839840630303,0.0 50.18371958792864,8.791637049898368,0.0 50.17642594359777,8.789065201919588,0.0 50.17596274342498,8.78995123147805,0.0 50.17430232089517,8.792046274117968,0.0 50.17337983900064,8.792936667239935,0.0 50.173916557905876,8.7938270603619,0.0 50.173195340484554,8.794979333813854,0.0 50.17431909312838,8.796367299562801,0.0 50.17334629386889,8.798724222532709,0.0 50.17103162290417,8.799588427621675,0.0 50.16957231619278,8.79793858154274,0.0 50.16703939070253,8.793905624460896,0.0 50.16438890109903,8.794534137252873,0.0 50.16375141964782,8.79050118017103,0.0 50.16162082784406,8.789139402455083,0.0 50.16103364018217,8.79076306050102,0.0 50.1591545911941,8.790527368204028,0.0 50.1596579151296,8.787280052112155,0.0 50.15856737323834,8.783220906997313,0.0 50.157225133682765,8.783011402733322,0.0 50.1560842004315,8.7835875394593,0.0 50.15568151160696,8.781728189116372,0.0 50.138275414238024,8.77894862521831,0.0 50.13670242407733,8.77838227975314,0.0 50.13690217682525,8.784467717601034,0.0 50.13534508071917,8.794250560713733,0.0 50.13391419097039,8.802588957192343,0.0 50.13357750481077,8.81237180030504,0.0 50.13319873004944,8.816967766868055,0.0 50.12932663828693,8.816967766868055,0.0 50.12356000792097,8.817755646850285,0.0 50.12381257562391,8.812306143639855,0.0 50.12170780404554,8.807447550416098,0.0 50.120865869500825,8.806725327099054,0.0 50.11556134136147,8.803179867179015,0.0 50.11324568846011,8.805346537130145,0.0 50.106340167703365,8.80816977373314,0.0 50.10335027363762,8.817164736863607,0.0 50.100570768108895,8.819594033475484,0.0 50.09652756307581,8.818280900171766,0.0 50.090630610745976,8.820775853448833,0.0 50.08907200924542,8.82274555340441,0.0 50.08818737503363,8.82530616334666,0.0 50.0851963479583,8.842048612969064,0.0 50.07200832727764,8.835811229776404,0.0 50.07049126160658,8.824386970034057,0.0 50.069570879337796,8.78607195954587,0.0 50.0601144750599,8.77637532098599,0.0 50.048860122033034,8.752320198404746,0.0 50.01891548545801,8.76089799405387,0.0 50.01232515932821,8.762762732238464,0.0 50.00777131509019,8.767797525336864,0.0 50.00381631081293,8.766492208607648,0.0 50.002510604252436,8.768218421614016,0.0 50.00128762337993,8.775689982557171,0.0 50.002779059304025,8.78613160499326,0.0 50.00131196288862,8.790503627643895,0.0 49.99779764073278,8.794819888766732,0.0 49.99865804458652,8.799875040273319,0.0 50.00348400921596,8.811082687365706,0.0 50.00061646545155,8.81260605687341,0.0 50.00033669592648,8.815217547458044,0.0 49.99781869693746,8.815326359565736,0.0 49.99648969985931,8.811844372119557,0.0 49.99383159550032,8.813150117411876,0.0 49.994111402878666,8.819134783334993,0.0 49.98877967758542,8.820035779675596,0.0 49.98385558936126,8.814211125129365,0.0 49.97969399505043,8.814642581021678,0.0 49.9713003514494,8.818202092133264,0.0 49.96810899538112,8.812377437587031,0.0 49.96519496372066,8.813456077317817,0.0 49.962003202814614,8.82165373927177,0.0 49.96255830686967,8.839127702910474,0.0 49.96380726759058,8.846246725133646,0.0 49.95856259839435,8.850124261434395,0.0"
    border = "63688 Ober-Seemen,63697 Merkenfritz,63697 Hirzenhain,63683 Lißberg,63683 Eckartsborn,63691 Bobenhausen,63683 Wippenbach,63683 Selters (Ortenberg),63683 Bleichenbach,63654 Büdingen>city,63674 Enzheim,63674 Lindheim,63674 Oberau,63674 Höchst,61130 Eichen,61130 Nidderau Heldenbergen,61130 Windecken,61137 Schöneck,61137 Oberdorfelden,61138 Niederdorfelden>city,63477 Maintal>city,63165 Mühlheim am Main>city,63075 Waldheim,63179 Obertshausen>city,63150 Heusenstamm>city,63128 Dietzenbach,63322 Waldacker,63322 Rödermark Ober-Roden,63110 Rodgau>city,63533 Mainhausen>city,63538 Großkrotzenburg>city,63517 Rodenbach>city,63579 Neuses,63579 Horbach,63589 Waldrode,63599 Biebergemünd>city,63639 Flörsbachtal>city,63637 Pfaffenhausen>city,63628 Alsberg,63628 Kerbersdorf,63628 Schönhof,63633 Wettges"
    sectorBorderPonts = getBorderPoints(hrCoordReal) #get seq[Point] of polygon sector

proc parseDistricts(d: string): TableRef[string, District] =
    result = newTable[string, District]()
    var
        parser: CsvParser
    let
        strmD = newStringStream(d)
    parser.open(strmD, "districts.csv", '\t')
    parser.readHeaderRow()
    while parser.readRow():
        let
            id = parser.rowEntry("ADMIN_PLACE_ID")
            #arrLat = (parser.rowEntry("LAT").split ",").map(proc (item: string): string = (if item == "": "0" else: item))
            arrLat = (parser.rowEntry("LAT").split ",").map((item) => (if item == "": "0" else: item))
            arrLng = (parser.rowEntry("LON").split ",").map((item) => (if item == "": "0" else: item))
        #echo parser.rowEntry("LAT")
        #echo arrLat
        var
            district = 
                if result.hasKey id:
                    result[id]
                else:
                    new(District)
            prevLat: int
            prevLng: int
        for i in 0..arrLat.high:
            prevLat = prevLat + arrLat[i].parseInt
            prevLng = prevLng + arrLng[i].parseInt
            let
                curLat = prevLat.toFloat / 100_000.00
                curLng = prevLng.toFloat / 100_000.00
            district.polygonOuter.add(curLat)
            district.polygonOuter.add(curLng)
            district.polygonOuter.add(0.00) #altitude
            district.outerPoints.add Point(x: curLng, y: curLat)
        district.id = id
        district.name = parser.rowEntry("NAME")
        result[id] = district
    parser.close()
    strmD.close()



proc getDistricts(d: string): TableRef[string, District] =
    var
        client = newHttpClient()
        cityIds: seq[string]
        districtIds: seq[string]
        maxTileX, maxTileY = int.low
        minTileX, minTileY = int.high
    let
        arrDistricts = d.split ","
    for distr in arrDistricts:
        let
            arrAddr = distr.split ">"
            isCity = arrAddr.len == 2
            searchtext = encodeUrl arrAddr[0].strip
            url = fmt"https://geocoder.ls.hereapi.com/6.2/geocode.json?apikey={apikey}&searchtext={searchtext}&jsonattributes=1&country=DEU"
            res = parseJson(client.getContent url)
            coord = res["response"]["view"][0]["result"][0]["location"]["displayPosition"]
            lat = coord["latitude"].getFloat
            lng = coord["longitude"].getFloat
            prox = encodeUrl fmt"{lat},{lng},1"
            urlRev = fmt"https://reverse.geocoder.ls.hereapi.com/6.2/reversegeocode.json?apikey={apikey}&jsonattributes=1&mode=retrieveAddresses&prox={prox}&maxResults=1"
            resRev = parseJson(client.getContent urlRev)
            mapReference = resRev["response"]["view"][0]["result"][0]["location"]["mapReference"]
        if isCity:
            cityIds.add mapReference["cityId"].getStr
        else:
            districtIds.add mapReference["districtId"].getStr
    let
        distrValues = encodeUrl(districtIds.join ",")
        urlAdminPlaceDistr = fmt"https://fleet.ls.hereapi.com/1/index.json?apikey={apikey}&layer=ADMIN_PLACE_9&attributes=ADMIN_PLACE_ID&values={distrValues}"
        resAdminDistrIdx = parseJson(client.getContent urlAdminPlaceDistr)
        cityValues = encodeUrl(cityIds.join ",")
        urlAdminPlaceCity = fmt"https://fleet.ls.hereapi.com/1/index.json?apikey={apikey}&layer=ADMIN_PLACE_8&attributes=ADMIN_PLACE_ID&values={cityValues}"
        resAdminCityIdx = parseJson(client.getContent urlAdminPlaceCity)
    var txys: seq[(int, int)]
    for layer in resAdminDistrIdx["Layers"]:
        for tileXY in layer["tileXYs"]:
            txys.add (tileXY["x"].getInt, tileXY["y"].getInt)
    #echo txys
    for layer in resAdminCityIdx["Layers"]:
        for tileXY in layer["tileXYs"]:
            txys = txys.concat toTileXY(10, tileXY["x"].getInt, tileXY["y"].getInt, 11)
            for txy in txys:
                if txy[0] < minTileX:
                    minTileX = txy[0]
                if txy[0] > maxTileX:
                    maxTileX = txy[0]
                if txy[1] < minTileY:
                    minTileY = txy[1]
                if txy[1] > maxTileY:
                    maxTileY = txy[1]
    var
        arrTileXYs, arrLevels, arrLayers: seq[string]
    for tx in minTileX..maxTileX:
        for ty in minTileY..maxTileY:
            arrTileXYs.add [tx, ty].join(",")
            arrLevels.add "11"
            arrLayers.add "ADMIN_POLY_9"
    let numPart = (arrTileXYs.len div 64) + 1
    let dTileXYs = arrTileXYs.distribute(numPart, false)
    let dLevels = arrLevels.distribute(numPart, false)
    let dLayers = arrLayers.distribute(numPart, false)
    var arrAllPolyAdmin: seq[string]
    for i in 0..dTileXYs.high:
        let
            allTileXYs = encodeUrl(dTileXYs[i].join ",")
            levels = encodeUrl(dLevels[i].join ",")
            layers = encodeUrl(dLayers[i].join ",")
            urlPolyAdmin = fmt"https://fleet.ls.hereapi.com/1/tiles.txt?apikey={apikey}&tilexy={allTileXYs}&layers={layers}&levels={levels}"
            resPolyAdmin = client.getContent urlPolyAdmin
        var arrResPolyAdmin = resPolyAdmin.split "\l"
        if i > 0:
            arrResPolyAdmin.delete(0) #delete header
        arrAllPolyAdmin = arrAllPolyAdmin.concat(arrResPolyAdmin)
    let tblDistrict = parseDistricts(arrAllPolyAdmin.join "\n")
    #del districts outside the border
    var forDel: seq[string]
    for k,v in tblDistrict:
        for p in v.outerPoints:
            if not p.isPointInPolygon sectorBorderPonts:
                forDel.add v.id
            break
    for id in forDel:
        tblDistrict.del id
    result = tblDistrict
        #echo resPolyAdmin
        #echo urlPolyAdmin
    #echo resAdminCityIdx.pretty
    #echo [minTileX, maxTileX, minTileY, maxTileY].join ","
    #echo allTileXYs
    #echo res["response"]["view"][0]["result"][0]["location"]["displayPosition"].pretty
    #echo resRev["response"]["view"][0]["result"][0]["location"]["mapReference"].pretty
    #return @[]







template readHead(b: untyped): untyped =
    if willHead:
        header = line.split '\t'
        idxLinkId = header.getIndex "LINK_ID"
        willHead = false
    else:
        arrRow = line.split '\t'
        linkId = arrRow[idxLinkId].strip
        if exceptsLinks.contains linkId:
            continue
        else:
            if not area.roadLinks.hasKeyOrPut(linkId, new RoadLink):
                area.roadLinks[linkId].linkId = linkId
            #echo "linkId:", linkId, tblRoadLinks.len
            b


proc filterRoadLinks(strm: Stream, tblDistrict: TableRef[string, District]): Area =
    var
        exceptsLinks: seq[string]
        layer: string
        willHead = false
        header: seq[string]
        idxPlIds, idxLinkId, idxPcs: int
        area = Area(
                roadLinks: newTable[string, RoadLink](),
                cities: newTable[string, City](),
                districts: newTable[string, District]()
            )
        #tblRoadLinks = newTable[string, RoadLink]()
    for line in strm.lines():
        let arrLine = line.split '\t'
        if arrLine[0] == "Meta:":
            layer = arrLine[1].multiReplace getFcs()
            willHead = true
            continue
        if layer == "ROAD_ADMIN":
            if willHead:
                header = line.split '\t'
                idxLinkId = header.getIndex "LINK_ID"
                idxPlIds = header.getIndex "ADMIN_PLACE_IDS"
                willHead = false
            else:
                let arrRow = line.split '\t'
                let districtId = parseAdmins(arrRow[idxPlIds], false)[4]
                if not tblDistrict.hasKey districtId:
                    exceptsLinks.add arrRow[idxLinkId].strip
    strm.setPosition 0
    for line in strm.lines():
        let arrLine = line.split '\t'
        if arrLine[0] == "Meta:":
            layer = arrLine[1].multiReplace getFcs()
            willHead = true
            continue
        var
            linkId: string
            arrRow: seq[string]
        case layer
        of "ROAD_ADMIN":
            #echo "ROAD_ADMIN!!!!"
            readHead:
                idxPlIds = header.getIndex "ADMIN_PLACE_IDS"
                idxPcs = header.getIndex "POSTAL_CODES"
                #echo "idxPlIds:", arrRow
                let
                    districtId = parseAdmins(arrRow[idxPlIds], false)[4]
                    cityId = parseAdmins(arrRow[idxPlIds], false)[3]
                    link = area.roadLinks[linkId]
                link.postalCode = arrRow[idxPcs].split(";")[0]
                link.disstrictId = districtId
                link.cityId = cityId
                discard area.cities.hasKeyOrPut(cityId, City(id: cityId))
                discard area.districts.hasKeyOrPut(districtId, District(id: districtId))
        of "ROAD_ADMIN_NAMES":
            readHead:
                let
                    iCty = header.getIndex "ORDER8_NAMES" #city
                    iDstr = header.getIndex "BUILTUP_NAMES" #district
                    link = area.roadLinks[linkId]
                    cityId = link.cityId
                    districtId = link.disstrictId
                area.cities[cityId].pdeName = parsePdeNames arrRow[iCty]
                area.districts[districtId].pdeName = parsePdeNames arrRow[iDstr]
        of "ROAD_GEOM":
            #echo "ROAD_GEOM!!!!"
            readHead:
                let
                    idxLat = header.getIndex "LAT"
                    idxLon = header.getIndex "LON"
                area.roadLinks[linkId].coords = parseCoords(arrRow[idxLat], arrRow[idxLon])
        of "LINK":
            #echo "ROAD_GEOM!!!!"
            readHead:
                let
                    idxLat = header.getIndex "LAT"
                    idxLon = header.getIndex "LON"
                    idxRefs = header.getIndex "REF_NODE_NEIGHBOR_LINKS"
                    idxNonRefs = header.getIndex "NONREF_NODE_NEIGHBOR_LINKS"
                    coords = parseCoords(arrRow[idxLat], arrRow[idxLon])
                    link = area.roadLinks[linkId]
                link.refNodeCoord = coords[0]
                link.nonRefNodeCoord = coords[1]
                link.refLinks = arrRow[idxRefs].replace("-", "").split ","
                link.nonRefLinks = arrRow[idxNonRefs].replace("-", "").split ","
        of "ROAD_NAME":
            #echo "ROAD_NAME!!!!"
            readHead:
                #echo arrRow[header.getIndex "LINK_ID"]
                let
                    iNames = header.getIndex "NAMES"
                    pdeNames = parsePdeNames arrRow[iNames]
                area.roadLinks[linkId].name = pdeNames
                #for strName in pdeNames:
                    #echo "strName:", strName.lang.string, " ", strName.name
        else:
            discard
        #of "name":
    strm.close
    result = area


proc splitLinksByStreet(area: Area): TableRef[AdminStreet, seq[RoadLink]] =
    let tblRoadLinks = area.roadLinks
    var
        tblAdminStrKeys = newTable[Hash, AdminStreet]()
    result = newTable[AdminStreet, seq[RoadLink]]()
    for k,v in tblRoadLinks.pairs:
        let strName = v.name.encodeName
        if strName == "":
            continue
        var admStr = AdminStreet(
                        postalCode: v.postalCode,
                        city: area.cities[v.cityId],
                        district: area.districts[v.disstrictId],
                        street: strName,
                        roadLinks: @[]
                )
        if not tblAdminStrKeys.hasKeyOrPut(admStr.hash, admStr):
            result[admStr] = @[]
        admStr = tblAdminStrKeys[admStr.hash]
        admStr.roadlinks.add v
        result[admStr].add v


proc splitStreetsByAdmin(admStr: TableRef[AdminStreet, seq[RoadLink]]): TableRef[Admin, seq[AdminStreet]] =
    result = newTable[Admin, seq[AdminStreet]]()
    var
        tblAdminKeys = newTable[Hash, Admin]()
    for k in admStr.keys:
        var adm = Admin(
                postalCode: k.postalCode,
                city: k.city,
                district: k.district
            )
        if not tblAdminKeys.hasKeyOrPut(adm.hash, adm):
            result[adm] = @[]
        adm = tblAdminKeys[adm.hash]
        result[adm].add k



proc findEdgeStreet(seqAdmStr: seq[AdminStreet]): AdminStreet =
    var
        minLat = float.high
        minLng = float.high
    for admStr in seqAdmStr:
        for link in admStr.roadLinks:
            if minLat > link.refNodeCoord.y:
                minLat = link.refNodeCoord.y
                result = admStr
            if minLat > link.nonRefNodeCoord.y:
                minLat = link.nonRefNodeCoord.y
                result = admStr
            if minLng > link.refNodeCoord.x:
                minLng = link.refNodeCoord.x
                result = admStr
            if minLng > link.nonRefNodeCoord.x:
                minLng = link.nonRefNodeCoord.x
                result = admStr



proc main() =
    when false: #collect data for district visualization
        let tblDistrict = getDistricts border
        writeFile("visual_districts.csv", "")
        var visDistrFile: File
        discard visDistrFile.open("visual_districts.csv", fmAppend)
        var data: seq[string]
        for d in tblDistrict.values:
            data.add d.polygonOuter.join(",")
        visDistrFile.write(data.join ("\n"))
        visDistrFile.close()
    when false:
        let layers = @[
                "ROAD_ADMIN",
                "ROAD_ADMIN_NAMES",
                "ROAD_GEOM",
                "ROAD_NAME",
                "LINK"
            ]
        getRoadLinks(layers, sectorBorderPonts, apikey, 2, 5, "roadLinks.txt")
    when false:
        let tblDistrict = getDistricts border
        let data = tblDistrict.toFlatty().compress()
        let sData = openFileStream("tblDistrict.data", fmWrite)
        sData.write(data)
        sData.close
        #writeFile("tblDistrict.json", tblDistrict.toJson)
    when true:
        #let tblDistrict = (readFile "tblDistrict.json").fromJson(TableRef[string, District])
        let tblDistrict = (openFileStream "tblDistrict.data").readAll().uncompress().fromFlatty(TableRef[string, District])
        var area = filterRoadLinks(openFileStream "roadLinks.txt", tblDistrict)
        let data = area.toFlatty().compress()
        let sData = openFileStream("area.data", fmWrite)
        sData.write(data)
        sData.close
        #tblRoadLinks.clear
    when false:
        let sDataR = openFileStream "area.data"
        let area = sDataR.readAll().uncompress().fromFlatty(Area)
        let tblRoadLinks = area.roadLinks
        echo tblRoadLinks["52418711"].name.encodeName
        echo tblRoadLinks["1200131157"].name.encodeName
        echo tblRoadLinks["990689333"].name.encodeName
        echo tblRoadLinks["1157468789"].name.encodeName
        let
            tblAdminStreet = area.splitLinksByStreet()
            tblAdminWithStreet = tblAdminStreet.splitStreetsByAdmin()
        #for k,v in tblAdminStreet.pairs:
            #if k.city.pdeName.encodeName == "Hanau" and k.postalCode == "63452":
                #echo "admStr: city:", k.city.pdeName.encodeName, ", district:", k.district.pdeName.encodeName, ", street:", k.street, ", hash:", k.hash
        for adm, admStr in tblAdminWithStreet:
            let edgeStreet = admStr.findEdgeStreet()
            echo "adm:", [adm.postalCode, adm.city.pdeName.encodeName, adm.district.pdeName.encodeName, edgeStreet.street].join(", ")
            #echo "edgeStreet:", edgeStreet.street

main()