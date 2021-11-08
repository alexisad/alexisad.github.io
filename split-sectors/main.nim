# nim -r -d:ssl c main.nim
# nim -r --gc:orc -d:ssl c main.nim
# nim -r --gc:orc -d:ssl -d:release c main.nim
import tile, types, utils, pde
import std / [httpclient, strutils, sequtils, strformat, uri, json, tables, parsecsv, streams, sugar]
import std / [algorithm]
import flatty, supersnappy

const
    apikey = "rJQnOk6DBkUYFFQGR31fN7ZZWeoGtkGYI0PJM8uVoo8"
    hrCoordReal = "49.95856259839435,8.850124261434395,0.0 49.96396515545882,8.899470891953959,0.0 49.989107714500946,8.942093035419573,0.0 49.99375559635732,8.973836498540546,0.0 49.98852001928919,9.014720749471216,0.0 49.98595544705414,9.046298016450189,0.0 49.993374764204034,9.054906229836575,0.0 50.01241735811533,9.038966773881107,0.0 50.02965494688769,9.03186813780005,0.0 50.0384117586606,9.032281998108914,0.0 50.042818175748586,9.027509152282287,0.0 50.04441439462123,9.022565665862723,0.0 50.04644677958852,9.013523319190714,0.0 50.04425309054112,8.996242389995311,0.0 50.04241418571553,8.987752631175479,0.0 50.04476926168952,8.980317812800713,0.0 50.05134995729781,8.977353932502664,0.0 50.05405939323471,8.980217342282131,0.0 50.06044531552646,8.986546984952541,0.0 50.062896251887224,8.988757336361253,0.0 50.06734631621531,8.99182168717788,0.0 50.06673365070724,8.992977098141527,0.0 50.0668626335698,8.99398180332731,0.0 50.06718803495289,8.994414733080061,0.0 50.06771451792822,8.995464253486665,0.0 50.06829194422368,8.99569356046626,0.0 50.0688014322406,8.995790574957626,0.0 50.06906749605375,8.996778358869724,0.0 50.06879577129238,8.997378084816354,0.0 50.06905051330128,8.998956775175868,0.0 50.06930053266752,8.99941800765802,0.0 50.0695826597326,8.999881101814484,0.0 50.07118974475246,8.99940230955102,0.0 50.07246819127017,8.999262421160052,0.0 50.073681046891316,8.999278572803176,0.0 50.07593045003854,8.998761720223174,0.0 50.07685298579153,8.998697113650673,0.0 50.079516837714955,8.99906860144255,0.0 50.08036829651911,8.999048176213728,0.0 50.08163131412362,8.999132593752917,0.0 50.08380948509669,8.998839123161446,0.0 50.08398524097505,8.998457611392535,0.0 50.08529083589718,8.998731517277907,0.0 50.0858180853043,8.999103246693766,0.0 50.087745007018746,8.999113029046814,0.0 50.08994800500485,8.99887825257364,0.0 50.09095218700986,8.998614129041318,0.0 50.09268435151408,8.997880452562647,0.0 50.093989709477825,8.9992499819895,0.0 50.09529893546212,9.000556974921759,0.0 50.097739470199144,9.003266612926636,0.0 50.11201852058528,9.02981141216353,0.0 50.11661516874831,9.067234864827416,0.0 50.12025635598552,9.07282045477725,0.0 50.14215732616893,9.07477541125969,0.0 50.13214371793553,9.104686488157405,0.0 50.130002073318444,9.11819544464286,0.0 50.12962960360105,9.129525537179045,0.0 50.124042209958354,9.131849658724928,0.0 50.12329717485541,9.139257796152435,0.0 50.12525286726787,9.144487069630674,0.0 50.12804657496021,9.150297373495386,0.0 50.130455597090595,9.155493171369901,0.0 50.133915546952075,9.158535444434747,0.0 50.1367776800252,9.15868265119595,0.0 50.13741151788165,9.163817274408206,0.0 50.14339492987892,9.173004915543089,0.0 50.14755755017878,9.192392814174495,0.0 50.14648131805793,9.200345557307376,0.0 50.138180651937496,9.259625280641485,0.0 50.13309753499998,9.307707323856194,0.0 50.139325423584935,9.327568851365392,0.0 50.12993748742165,9.339142835021836,0.0 50.12858337744752,9.365496359295658,0.0 50.12641773051991,9.372735178643259,0.0 50.11574275323997,9.381663055838633,0.0 50.09423086055464,9.394210342707808,0.0 50.087113888846716,9.404106700966404,0.0 50.084234652636276,9.41068546866214,0.0 50.08332028837411,9.415072180815773,0.0 50.084109152691816,9.419263307077205,0.0 50.08422122075908,9.425175379748403,0.0 50.08359146921259,9.427138246524793,0.0 50.08359146921259,9.433746564671972,0.0 50.09022443676629,9.46096498397125,0.0 50.09085360543011,9.474022801340594,0.0 50.093517639965924,9.48311122533397,0.0 50.09417105978058,9.497057255254838,0.0 50.09552813400177,9.509122921590878,0.0 50.10598134317437,9.5205618000653,0.0 50.114221688388604,9.519935012203698,0.0 50.14498492404182,9.511705614500329,0.0 50.151057005957576,9.529820900852283,0.0 50.16355592364119,9.537067015393063,0.0 50.17319571327903,9.524804360016356,0.0 50.17694399525393,9.501393836115371,0.0 50.192469459564606,9.505852983525081,0.0 50.19496733876523,9.518673032328001,0.0 50.19962499700489,9.516589022864023,0.0 50.21399704559683,9.50504530922025,0.0 50.21870102145308,9.466106812451708,0.0 50.26614431812017,9.43139020351146,0.0 50.2704110296101,9.442662471130737,0.0 50.27772026972424,9.4554185495736,0.0 50.30061968660411,9.419174629647651,0.0 50.3134338989555,9.398350843677145,0.0 50.330902260659,9.396070867111032,0.0 50.34710327756438,9.365823178000584,0.0 50.41660380223247,9.344974529943373,0.0 50.42288128194858,9.245267930092574,0.0 50.42450902384603,9.234516048623957,0.0 50.421660438811095,9.224935164146977,0.0 50.415420082407365,9.218334999285055,0.0 50.40619370176144,9.159039969799737,0.0 50.39988345120526,9.134129670159584,0.0 50.38861790491299,9.116032443925288,0.0 50.38196590399061,9.085373613598946,0.0 50.373828204075195,9.060876585432112,0.0 50.374851912213195,9.039245421406951,0.0 50.37455942642779,9.033894956807094,0.0 50.36909604401242,9.032055311810234,0.0 50.34884219264727,9.036714437078075,0.0 50.34206593823363,9.028913111048201,0.0 50.338055046494205,9.028371352296126,0.0 50.32394508151426,9.03866476858554,0.0 50.31439772920148,9.016777715001732,0.0 50.30756222761449,9.006886141097945,0.0 50.30215231393127,8.999211834250447,0.0 50.30015521042514,8.987558257185748,0.0 50.29616075185897,8.975449906381932,0.0 50.29107641039998,8.972493877077715,0.0 50.27792723722931,8.94907302951354,0.0 50.27618342766435,8.937021525427118,0.0 50.274948190575785,8.92258245921037,0.0 50.25656116848032,8.893022166168203,0.0 50.24522017796395,8.85641288016981,0.0 50.23634884074695,8.855222008654989,0.0 50.22470113569143,8.860339308210316,0.0 50.20947108695584,8.860934343042329,0.0 50.20672916183294,8.839751103022607,0.0 50.20094013589099,8.796432567251937,0.0 50.197435910668744,8.790006191066185,0.0 50.1946134041465,8.79057185680632,0.0 50.18875997039989,8.791839840630303,0.0 50.18371958792864,8.791637049898368,0.0 50.17642594359777,8.789065201919588,0.0 50.17596274342498,8.78995123147805,0.0 50.17430232089517,8.792046274117968,0.0 50.17337983900064,8.792936667239935,0.0 50.173916557905876,8.7938270603619,0.0 50.173195340484554,8.794979333813854,0.0 50.17431909312838,8.796367299562801,0.0 50.17334629386889,8.798724222532709,0.0 50.17103162290417,8.799588427621675,0.0 50.16957231619278,8.79793858154274,0.0 50.16703939070253,8.793905624460896,0.0 50.16438890109903,8.794534137252873,0.0 50.16375141964782,8.79050118017103,0.0 50.16162082784406,8.789139402455083,0.0 50.16103364018217,8.79076306050102,0.0 50.1591545911941,8.790527368204028,0.0 50.1596579151296,8.787280052112155,0.0 50.15856737323834,8.783220906997313,0.0 50.157225133682765,8.783011402733322,0.0 50.1560842004315,8.7835875394593,0.0 50.15568151160696,8.781728189116372,0.0 50.138275414238024,8.77894862521831,0.0 50.13670242407733,8.77838227975314,0.0 50.13690217682525,8.784467717601034,0.0 50.13534508071917,8.794250560713733,0.0 50.13391419097039,8.802588957192343,0.0 50.13357750481077,8.81237180030504,0.0 50.13319873004944,8.816967766868055,0.0 50.12932663828693,8.816967766868055,0.0 50.12356000792097,8.817755646850285,0.0 50.12381257562391,8.812306143639855,0.0 50.12170780404554,8.807447550416098,0.0 50.120865869500825,8.806725327099054,0.0 50.11556134136147,8.803179867179015,0.0 50.11324568846011,8.805346537130145,0.0 50.106340167703365,8.80816977373314,0.0 50.10335027363762,8.817164736863607,0.0 50.100570768108895,8.819594033475484,0.0 50.09652756307581,8.818280900171766,0.0 50.090630610745976,8.820775853448833,0.0 50.08907200924542,8.82274555340441,0.0 50.08818737503363,8.82530616334666,0.0 50.0851963479583,8.842048612969064,0.0 50.07200832727764,8.835811229776404,0.0 50.07049126160658,8.824386970034057,0.0 50.069570879337796,8.78607195954587,0.0 50.0601144750599,8.77637532098599,0.0 50.048860122033034,8.752320198404746,0.0 50.01891548545801,8.76089799405387,0.0 50.01232515932821,8.762762732238464,0.0 50.00777131509019,8.767797525336864,0.0 50.00381631081293,8.766492208607648,0.0 50.002510604252436,8.768218421614016,0.0 50.00128762337993,8.775689982557171,0.0 50.002779059304025,8.78613160499326,0.0 50.00131196288862,8.790503627643895,0.0 49.99779764073278,8.794819888766732,0.0 49.99865804458652,8.799875040273319,0.0 50.00348400921596,8.811082687365706,0.0 50.00061646545155,8.81260605687341,0.0 50.00033669592648,8.815217547458044,0.0 49.99781869693746,8.815326359565736,0.0 49.99648969985931,8.811844372119557,0.0 49.99383159550032,8.813150117411876,0.0 49.994111402878666,8.819134783334993,0.0 49.98877967758542,8.820035779675596,0.0 49.98385558936126,8.814211125129365,0.0 49.97969399505043,8.814642581021678,0.0 49.9713003514494,8.818202092133264,0.0 49.96810899538112,8.812377437587031,0.0 49.96519496372066,8.813456077317817,0.0 49.962003202814614,8.82165373927177,0.0 49.96255830686967,8.839127702910474,0.0 49.96380726759058,8.846246725133646,0.0 49.95856259839435,8.850124261434395,0.0"
    border = "63688 Ober-Seemen,63697 Merkenfritz,63697 Hirzenhain,63683 Lißberg,63683 Eckartsborn,63691 Bobenhausen,63683 Wippenbach,63683 Selters (Ortenberg),63683 Bleichenbach,63654 Büdingen>city,63674 Enzheim,63674 Lindheim,63674 Oberau,63674 Höchst,61130 Eichen,61130 Nidderau Heldenbergen,61130 Windecken,61137 Schöneck,61137 Oberdorfelden,61138 Niederdorfelden>city,63477 Maintal>city,63165 Mühlheim am Main>city,63075 Waldheim,63179 Obertshausen>city,63150 Heusenstamm>city,63128 Dietzenbach,63322 Waldacker,63322 Rödermark Ober-Roden,63110 Rodgau>city,63533 Mainhausen>city,63538 Großkrotzenburg>city,63517 Rodenbach>city,63579 Neuses,63579 Horbach,63589 Waldrode,63599 Biebergemünd>city,63639 Flörsbachtal>city,63637 Pfaffenhausen>city,63628 Alsberg,63628 Kerbersdorf,63628 Schönhof,63633 Wettges"
    sectorBorderPonts = getBorderPoints(hrCoordReal) #get seq[Point] of polygon sector

#map distrivt id to District object with border
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
        #TODO - polygonOuter and outerPoints are not correct (see please below) but for this logic of app it could be enough
        #[
            https://tcs.ext.here.com/pde/layer?region=WEU&release=latest&url_root=pde.api.here.com&layer=ADMIN_POLY_9
            Polylines are cut at tile boundaries, so that a polyline is decomposed into smaller pieces.
            Longitude coordinate values with a leading zero indicate that the line to the next coordinate is artificially introduced by tiling.
            These lines must be used to draw filled polygons and to compute 'point in polygon', but must be skipped when drawing border lines.
        ]#
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


# get inner districts by admin area names which are border
proc getDistricts(d: string): TableRef[string, District] =
    var
        client = newHttpClient()
        cityIds: seq[string]
        districtIds: seq[string]
        maxTileX, maxTileY = int.low
        minTileX, minTileY = int.high
    let
        arrDistricts = d.split ","
    for distr in arrDistricts: #get cityIds or districtIds which on the border
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
    var txys: seq[(int, int)] #Tile ids for whole area
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
    let numPart = (arrTileXYs.len div 64) + 1 #needs split by 64 - limit of REST API
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
        if i > 0: #keep header only from response of first request
            arrResPolyAdmin.delete(0) #we need only one header of columns for layer ADMIN_POLY_9
        arrAllPolyAdmin = arrAllPolyAdmin.concat(arrResPolyAdmin)
    let tblDistrict = parseDistricts(arrAllPolyAdmin.join "\n")
    #del districts outside the border of the sector
    var forDel: seq[string]
    for k,v in tblDistrict:
        var
            inSector = true
            cntNotInSector = 0
        for p in v.outerPoints:
            if not p.isPointInPolygon sectorBorderPonts:
                inc cntNotInSector
                if cntNotInSector == 10: # at least 10 vertices of district are not in main polygon
                    inSector = false
                    break
        if not inSector:
            forDel.add v.id
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
            if not area.roadLinks.hasKeyOrPut(linkId, RoadLink(isStrNameEmpty: true)):
                area.roadLinks[linkId].linkId = linkId
            #echo "linkId:", linkId, tblRoadLinks.len
            b



proc checkRoadLinksOnAdmin(strm: Stream): TableRef[string, string] =
    var
        layer: string
        willHead = false
        header: seq[string]
        idxPlIds, idxLinkId, idxPcs, iNames: int
        idxLat, idxLng: int
        tblCityEmpDistrict = newTable[string, seq[string]]() #links with empty districtId grouped by city
        tblCityEmpPc = newTable[string, seq[string]]() #links with empty postal codes grouped by city
        tblLink2City = newTable[string, string]() #map linkId to cityid
        tblLink2Pc = newTable[string, string]() #map linkId to postal code
        tblLink2StrName = newTable[string, string]() #map linkId to streetName
        tblCity2Links = newTable[string, seq[string]]() #map cityid to linkIds
        tblLinkIdHasAddress = newTable[string, seq[Point]]() #links which have addresses
        tblLinkNodeCoords = newTable[string, seq[Point]]() #links with refnode coords
        tblLinksDistrict = newTable[string, string]() #links to district
        tblNameStr2CityDistr = newTable[string, seq[string]]() #map name streets to city + district
        tblLinksNewDistrict = newTable[string, string]() #links with new district
    for line in strm.lines():
        let arrLine = line.split '\t'
        if arrLine[0] == "Meta:":
            layer = arrLine[1].multiReplace getFcs()
            willHead = true
            continue
        case layer:
        of "ROAD_ADMIN":
            if willHead:
                header = line.split '\t'
                idxLinkId = header.getIndex "LINK_ID"
                idxPlIds = header.getIndex "ADMIN_PLACE_IDS"
                idxPcs = header.getIndex "POSTAL_CODES"
                willHead = false
            else:
                let
                    arrRow = line.split '\t'
                    districtId = parseAdmins(arrRow[idxPlIds], false)[4]
                    cityId = parseAdmins(arrRow[idxPlIds], false)[3]
                    postalCode = arrRow[idxPcs].split(";")[0]
                    linkId = arrRow[idxLinkId]
                tblLink2City[linkId] = cityId
                if cityId == "":
                    echo "city is empty link:", linkId
                if districtId == "":
                    discard tblCityEmpDistrict.hasKeyOrPut(cityId, @[])
                    tblCityEmpDistrict[cityId].add linkId
                else:
                    discard tblLinksDistrict.hasKeyOrPut(linkId, districtId)
                if postalCode == "null":
                    discard tblCityEmpPc.hasKeyOrPut(cityId, @[])
                    tblCityEmpPc[cityId].add linkId
                else:
                    tblLink2Pc[linkId] = postalCode
        of "POINT_ADDRESS":
            if willHead:
                header = line.split '\t'
                idxLinkId = header.getIndex "LINK_ID"
                idxLat = header.getIndex "LAT"
                idxLng = header.getIndex "LON"
                willHead = false
            else:
                let
                    arrRow = line.split '\t'
                    linkId = arrRow[idxLinkId]
                #echo "linkId:", linkId, " ", arrRow[idxLat], " ", arrRow[idxLng]
                let lng = arrRow[idxLng].parseInt
                let lat = arrRow[idxLat].parseInt
                discard tblLinkIdHasAddress.hasKeyOrPut(linkId, @[])
                tblLinkIdHasAddress[linkId].add Point(x: lng / 100_000, y: lat / 100_000)
        of "LINK":
            if willHead:
                header = line.split '\t'
                idxLinkId = header.getIndex "LINK_ID"
                idxLat = header.getIndex "LAT"
                idxLng = header.getIndex "LON"
                willHead = false
            else:
                let
                    arrRow = line.split '\t'
                    linkId = arrRow[idxLinkId]
                    lngs = arrRow[idxLng]
                    lats = arrRow[idxLat]
                #echo "linkId:", linkId, " ", lngs, " ", lats
                let coords = parseCoords(lats, lngs)
                tblLinkNodeCoords[linkId] = coords
        of "ROAD_NAME":
            if willHead:
                header = line.split '\t'
                idxLinkId = header.getIndex "LINK_ID"
                iNames = header.getIndex "NAMES"
                willHead = false
            else:
                let
                    arrRow = line.split '\t'
                    linkId = arrRow[idxLinkId]
                    pdeNames = parsePdeNames arrRow[iNames]
                    street = pdeNames.decodeName()
                if street == "":
                    continue
                tblLink2StrName[linkId] = street
        else:
            discard #ignore other layers
    for cityId, linkIds in tblCityEmpPc:
        echo "PC null:", linkIds
    when true:
        for linkId, cityId in tblLink2City:
            discard tblCity2Links.hasKeyOrPut(cityId, @[])
            tblCity2Links[cityId].add linkId
            if not tblLink2StrName.hasKey(linkId) or
                    not tblLinksDistrict.hasKey(linkId): # avoid links without street name or district
                continue
            let
                street = tblLink2StrName[linkId]
                distrId = tblLinksDistrict[linkId]
                distrCity = [cityId, distrId].join("_")
            discard tblNameStr2CityDistr.hasKeyOrPut(street, @[])
            if not tblNameStr2CityDistr[street].contains(distrCity):
                tblNameStr2CityDistr[street].add distrCity
            let distrCts = tblNameStr2CityDistr[street].join("_")
            if distrCts.count(cityId) > 0:
                echo "same city:", tblNameStr2CityDistr[street]
                echo "same city linkId:", linkId, " ", street
        #quit 0
    for street, distrCity in tblNameStr2CityDistr:
        if distrCity.len > 1:
            echo "distrCity:", street, " ", distrCity
    for cityId, linkIds in tblCityEmpDistrict: #iterate by links with empty district of some city
        let
            empDistrWithAddrLinks = linkIds#.filterIt(tblLinkIdHasAddress.hasKey it)
        for linkId in empDistrWithAddrLinks:
            if tblLink2StrName.hasKey(linkId) and
                            tblNameStr2CityDistr.hasKey(tblLink2StrName[linkId]):
                let
                    street = tblLink2StrName[linkId]
                    cityDistrs = tblNameStr2CityDistr[street]
                if cityDistrs.len == 1: #if in a city only one street name in one district
                    let cityDistr = cityDistrs[0].split("_")
                    if cityDistr[0] == cityId: #check it because the street name could be in another city
                        tblLinksNewDistrict[linkId] = cityDistr[1]
                        continue
            var
                minD = float.high
                nearLink: string
            for point in tblLinkNodeCoords[linkId]:
                for mlinkId in tblCity2Links[cityId]:
                    if tblCityEmpDistrict[cityId].contains(mlinkId): #if mlinkId has also empty district
                        continue
                    let mPoints = tblLinkNodeCoords[mlinkId]
                    for mPoint in mPoints:
                        let d = point.distance mPoint
                        if d < minD:
                            nearLink = mlinkId
                            minD = d
            try:
                tblLinksNewDistrict[linkId] = tblLinksDistrict[nearLink]
                #echo "distr:",tblLinksDistrict[nearLink]
            except:
                discard # 
                #echo "linkId->nearLink:", linkId, ",", nearLink
        when false:
            if empDistrWithAddrLinks.len != 0:
                echo "cityId:", cityId
                echo "linkIds:", empDistrWithAddrLinks.join(",")
                echo ""
                #break
    strm.close
    result = tblLinksNewDistrict



proc filterRoadLinks(strm: Stream, tblDistrict: TableRef[string, District], tblLinksNewDistrict: TableRef[string, string]): Area =
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
                let linkId = arrRow[idxLinkId]
                var districtId = parseAdmins(arrRow[idxPlIds], false)[4]
                if tblLinksNewDistrict.hasKey(linkId): #above districtId is empty
                    #if linkId == "1037974970":
                        #echo "should be added!"
                        #quit 0
                    #echo "should be empty districtId:", districtId
                    districtId = tblLinksNewDistrict[linkId]
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
                var
                    districtId = parseAdmins(arrRow[idxPlIds], false)[4]
                if tblLinksNewDistrict.hasKey(linkId): #above districtId is empty
                    districtId = tblLinksNewDistrict[linkId]
                let
                    cityId = parseAdmins(arrRow[idxPlIds], false)[3]
                    link = area.roadLinks[linkId]
                link.postalCode = arrRow[idxPcs].split(";")[0]
                link.districtId = districtId
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
                var
                    districtId = link.districtId
                if tblLinksNewDistrict.hasKey(linkId): #above districtId is empty
                    districtId = tblLinksNewDistrict[linkId]
                area.cities[cityId].pdeName = parsePdeNames arrRow[iCty]
                if arrRow[iDstr] != "null":
                    area.districts[districtId].pdeName = parsePdeNames arrRow[iDstr]
        of "ROAD_GEOM":
            #echo "ROAD_GEOM!!!!"
            readHead:
                let
                    idxLat = header.getIndex "LAT"
                    idxLon = header.getIndex "LON"
                    link = area.roadLinks[linkId]
                link.coords = parseCoords(arrRow[idxLat], arrRow[idxLon])
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
                link.refLinks = if arrRow[idxRefs] == "": @[] else: arrRow[idxRefs].replace("-", "").split ","
                link.nonRefLinks = if arrRow[idxNonRefs] == "": @[] else: arrRow[idxNonRefs].replace("-", "").split ","
        of "ROAD_NAME":
            #echo "ROAD_NAME!!!!"
            readHead:
                #echo arrRow[header.getIndex "LINK_ID"]
                let
                    iNames = header.getIndex "NAMES"
                    pdeNames = parsePdeNames arrRow[iNames]
                    dStrName = pdeNames.decodeName()
                    link = area.roadLinks[linkId]
                    strName =
                        if dStrName.len > 0 and isNumber(dStrName[1..^1]): #ignore strange street names like 'L3202' etc.
                            ""
                        else:
                            dStrName
                link.name = pdeNames
                link.isStrNameEmpty = strName == ""
                #for strName in pdeNames:
                    #echo "strName:", strName.lang.string, " ", strName.name
        of "POINT_ADDRESS":
            readHead:
                let
                    iAddr = header.getIndex "ADDRESSES"
                    pdeNames = parsePdeNames arrRow[iAddr]
                    link = area.roadLinks[linkId]
                link.addresses.add pdeNames.decodeName
                #for strName in pdeNames:
                    #echo "strName:", strName.lang.string, " ", strName.name
        else:
            echo "strange layer name:", layer
        #of "name":
    strm.close
    result = area


proc splitLinksByStreet(area: Area): TableRef[AdminStreet, seq[RoadLink]] =
    let tblRoadLinks = area.roadLinks
    var
        tblAdminStrKeys = newTable[Hash, AdminStreet]()
    result = newTable[AdminStreet, seq[RoadLink]]()
    for linkId, link in tblRoadLinks.pairs:
        let strName =
            if link.isStrNameEmpty:
                linkId
            else:
                link.name.decodeName
        if linkId == "942399477":
            echo "strNameLink:", strName, link.isStrNameEmpty
        #if strName == "":
            #strName = linkId  #if street is empty then set linkId
        var admStr = AdminStreet(
                        postalCode: link.postalCode,
                        city: area.cities[link.cityId],
                        district: area.districts[link.districtId],
                        street: strName,
                        isStrNameEmpty: link.isStrNameEmpty,
                        roadLinks: @[]
                )
        if not tblAdminStrKeys.hasKeyOrPut(admStr.hash, admStr):
            result[admStr] = @[]
        admStr = tblAdminStrKeys[admStr.hash]
        admStr.roadlinks.add link
        result[admStr].add link


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


func getMinLat(roadLinks: seq[RoadLink]): float =
    var
        minLat = float.high
    for link in roadLinks:
        if minLat > link.refNodeCoord.y:
            minLat = link.refNodeCoord.y
        if minLat > link.nonRefNodeCoord.y:
            minLat = link.nonRefNodeCoord.y
    minLat


proc findEdgeStreet(seqAdmStr: seq[AdminStreet]): tuple[minCoord: Point, admStr: AdminStreet] =
    var
        minLat = float.high
        minLng = float.high
    for admStr in seqAdmStr:
        for link in admStr.roadLinks:
            if minLat > link.refNodeCoord.y:
                minLat = link.refNodeCoord.y
                result = (link.refNodeCoord, admStr)
            if minLat > link.nonRefNodeCoord.y:
                minLat = link.nonRefNodeCoord.y
                result = (link.nonRefNodeCoord, admStr)
            when false:
                if minLng > link.refNodeCoord.x:
                    minLng = link.refNodeCoord.x
                    result = admStr
                if minLng > link.nonRefNodeCoord.x:
                    minLng = link.nonRefNodeCoord.x
                    result = admStr


proc mapLink2AdminStreet(admStrs: TableRef[AdminStreet, seq[RoadLink]]): TableRef[string, AdminStreet] =
    result = newTable[string, AdminStreet]()
    for k,v in admStrs:
        for link in v:
            discard result.hasKeyOrPut(link.linkId, k)


proc findConnectedStrs(admStr: AdminStreet, minCoord: Point, link: RoadLink, isRefNode: bool,
                        tblLink2AdmStr: TableRef[string, AdminStreet],
                        street2Sector: TableRef[AdminStreet, Sector]): seq[tuple[distance: float, admStr: AdminStreet]] {.inline.} =
    let
        byLinks =
            if isRefNode:
                link.refLinks
            else:
                link.nonRefLinks
        nodeCoord =
            if isRefNode:
                link.refNodeCoord
            else:
                link.nonRefNodeCoord
        d = nodeCoord.distance minCoord
    for lnkId in byLinks:
        #if link.linkId == "567298955":
            #echo "find lnkId:", lnkId
            #quit 0
        if not tblLink2AdmStr.hasKey(lnkId): #avoid connected links from other sector areas
            continue
        let refAdmStr = tblLink2AdmStr[lnkId]
        if admStr.hash == refAdmStr.hash:
            continue # we need only other street - avoid the same street
        #if street2Sector.hasKey(refAdmStr):
            #continue # already in some sector - ignore it
        if admStr.hashAdm != refAdmStr.hashAdm:
            continue # we need only street in the same admin area
        result.add (distance: d, admStr: refAdmStr)


func adminKey(admStr: AdminStreet, numSector = 0): string {.inline.}=
    let
        cityName = admStr.city.pdeName.decodeName
        dn = admStr.district.pdeName.decodeName
        distrName = if dn != cityName: dn else: ""
        nSect = if numSector == 0: "" else: fmt"-{numSector}"
    result = fmt"{admStr.postalCode}{nSect} {cityName} {distrName}".strip


proc addStreet2Sector(admStr: AdminStreet,
                        numSector: var int,
                        sectors: var OrderedTableRef[string, Sector],
                        street2Sector: var TableRef[AdminStreet, Sector]): bool {.inline.} =
    result = true
    let
        sectorName = admStr.adminKey(numSector)
    discard sectors.hasKeyOrPut(sectorName, Sector(name: sectorName, streets: newSeq[AdminStreet]()))
    var sector = sectors[sectorName]
    if street2Sector.hasKeyOrPut(admStr, sector):
        return false
    if not admStr.isStrNameEmpty:
        sector.streets.add admStr # only here add street to sector
    if sector.countAddresses >= 100: #sector.streets.len > 7:
        #echo "sector.countAddresses:", sector.countAddresses
        inc numSector


proc isSplitAllStreets(tblAdminStreet: TableRef[AdminStreet, seq[RoadLink]],
                        street2Sector: var TableRef[AdminStreet, Sector]): bool {.inline.} =
    #echo "start"
    result = true
    var cnt: int
    for k,v in tblAdminStreet:
        if k.isStrNameEmpty:
            continue
        if not street2Sector.hasKey(k):
            result = false
            inc cnt
            #break
        #else:
            #echo "doch"
    if cnt < 500:
        echo "isSplitAllStreets:", cnt
    #echo "end"



proc nearestStreets(admStr: AdminStreet, minCoord: Point,
                    tblAdminStreet: TableRef[AdminStreet, seq[RoadLink]],
                    tblLink2AdmStr: TableRef[string, AdminStreet],
                    numSector: var int,
                    sectors: var OrderedTableRef[string, Sector],
                    street2Sector: var TableRef[AdminStreet, Sector],
                    dstncStr: var seq[tuple[distance: float, admStr: AdminStreet]]) =
    for link in admStr.roadLinks:
        echo "link.linkId:", link.linkId
        dstncStr = dstncStr.concat findConnectedStrs(admStr, minCoord, link, true, tblLink2AdmStr, street2Sector) #refLinks 
        dstncStr = dstncStr.concat findConnectedStrs(admStr, minCoord, link, false, tblLink2AdmStr, street2Sector) #nonRefLinks
    let dstncStrCpy = dstncStr.sortedByIt(it.distance)
    #echo "dstncStrCpy:", dstncStrCpy
    #if dstncStrCpy.len == 0:
        #echo "distance+street: empty!:", street2Sector[admStr].name, " ", admStr.street
    var alreadyAddedStrs: seq[AdminStreet]
    for dStr in dstncStrCpy:
        if not dStr.admStr.addStreet2Sector(numSector, sectors, street2Sector):
            echo "dStr.admStr.street:", dStr.admStr.street
            alreadyAddedStrs.add dStr.admStr
    #if isSplitAllStreets(tblAdminStreet, street2Sector):
        #return
    for dStr in dstncStrCpy:
        if not alreadyAddedStrs.contains(dStr.admStr):
            dStr.admStr.nearestStreets(minCoord, tblAdminStreet, tblLink2AdmStr, numSector, sectors, street2Sector, dstncStr)




func sectors2AdminName(sectors: var OrderedTableRef[string, Sector]): TableRef[string, seq[string]] =
    result = newTable[string, seq[string]]()
    var sectsForDel: seq[string]
    for k,v in sectors:
        if v.streets.len == 0:
            {.cast(noSideEffect).}:
                echo "sectors2AdminName:", k , " - no streets"
            sectsForDel.add k
            continue
        let
            admStr = v.streets[0]
            adminKey = admStr.adminKey
        discard result.hasKeyOrPut(adminKey, newSeq[string]())
        result[adminKey].add k
    for s in sectsForDel:
        sectors.del s


proc fixLinks(area: Area, fixFile: string) =
    var
        parser: CsvParser
    let
        strmD = newFileStream(fixFile)
    parser.open(strmD, "fixLinks.csv", ';')
    parser.readHeaderRow()
    while parser.readRow():
        let
            linkIds = parser.rowEntry("linkIds")
            districtId = parser.rowEntry("districtId")
            cityId = parser.rowEntry("cityId")
            postalCode = parser.rowEntry("pc")
            seqLinkIds = linkIds.split","
        var linksForDel: seq[string]
        for linkId, link in area.roadLinks:
            if seqLinkIds.contains(linkId):
                link.districtId = districtId
                link.cityId = cityId
                link.postalCode = postalCode
                if not area.districts.hasKey(districtId) or
                        not area.cities.hasKey(cityId):
                    linksForDel.add linkId
        for linkId in linksForDel:
            area.roadLinks.del linkId
        echo "fixLinks:", linkIds
    strmD.close



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
    when false: #getRoadLinks
        let layers = @[
                ("ROAD_ADMIN", 0),
                ("ROAD_ADMIN_NAMES", 0),
                ("ROAD_GEOM", 0),
                ("ROAD_NAME", 0),
                ("LINK", 0),
                ("POINT_ADDRESS", 13)
            ]
        getRoadLinks(layers, sectorBorderPonts, apikey, 2, 5, "roadLinks.txt")
    when false: #get list of all districtIds of whole main area
        let tblDistrict = getDistricts border
        let data = tblDistrict.toFlatty().compress()
        let sData = openFileStream("tblDistrict.data", fmWrite)
        sData.write(data)
        sData.close
        #writeFile("tblDistrict.json", tblDistrict.toJson)
    when false: # recognize & fill missing districtIds for some links
        let tblLinksNewDistrict = checkRoadLinksOnAdmin(openFileStream "roadLinks.txt")
        let sData = openFileStream("tblLinksNewDistrict.data", fmWrite)
        sData.write(tblLinksNewDistrict.toFlatty().compress())
        sData.close
    when false: # filter road links by districtIds of main area
        let tblDistrict = (openFileStream "tblDistrict.data").readAll()
            .uncompress().fromFlatty(TableRef[string, District])
        let tblLinksNewDistrict = (openFileStream "tblLinksNewDistrict.data").readAll().uncompress().fromFlatty(TableRef[string, string])
        var area = filterRoadLinks(openFileStream "roadLinks.txt", tblDistrict, tblLinksNewDistrict)
        let data = area.toFlatty().compress()
        let sData = openFileStream("area.data", fmWrite)
        sData.write(data)
        sData.close
        #tblRoadLinks.clear
    when true:
        let sDataR = openFileStream "area.data"
        let area = sDataR.readAll().uncompress().fromFlatty(Area)
        area.fixLinks "fixLinkAdmin.csv"
        #quit 0
        #[let tblRoadLinks = area.roadLinks
        echo tblRoadLinks["52418711"].name.decodeName
        echo tblRoadLinks["1200131157"].name.decodeName
        echo tblRoadLinks["990689333"].name.decodeName
        echo tblRoadLinks["1157468789"].name.decodeName]#
        let
            tblAdminStreet = area.splitLinksByStreet()
            tblAdminWithStreet = tblAdminStreet.splitStreetsByAdmin()
            tblLink2AdmStreet = tblAdminStreet.mapLink2AdminStreet()
        #for k,v in tblAdminStreet.pairs:
            #if k.city.pdeName.decodeName == "Hanau" and k.postalCode == "63452":
                #echo "admStr: city:", k.city.pdeName.decodeName, ", district:", k.district.pdeName.decodeName, ", street:", k.street, ", hash:", k.hash
        var
            sectors = newOrderedTable[string, Sector]()
            street2Sector = newTable[AdminStreet, Sector]()
        for adm, admStrs in tblAdminWithStreet:
            var admStrsSorted = admStrs
            admStrsSorted.sort do (a, b: AdminStreet) -> int:
                let
                    aMinLat = a.roadlinks.getMinLat
                    bMinLat = b.roadlinks.getMinLat
                cmp(aMinLat, bMinLat)
            var
                numSector = 1
            for admStr in admStrsSorted:
                if not admStr.addStreet2Sector(numSector, sectors, street2Sector):
                    echo "added already:", admStr.street
            when false:
                let (minCoord, edgeStreet) = admStrs.findEdgeStreet()
                #echo "adm:", [adm.postalCode, adm.city.pdeName.decodeName, adm.district.pdeName.decodeName, edgeStreet.street].join(", ")
                #echo "edgeStreet:", edgeStreet.street
                var
                    numSector = 1
                    dstncStr: seq[tuple[distance: float, admStr: AdminStreet]]
                discard edgeStreet.addStreet2Sector(numSector, sectors, street2Sector)
                edgeStreet.nearestStreets(minCoord, tblAdminStreet, tblLink2AdmStreet, numSector, sectors, street2Sector, dstncStr)
                #break
        let admSectors = sectors2AdminName sectors
        for k,s in admSectors:
            echo "AdminName:", k
            if s.len == 1: #if admin area has only 1 sector after split
                let
                    nameSector = s[0]
                    sector = sectors[nameSector]
                if sector.countAddresses > 50:
                    continue
                echo "only 1 sector:", nameSector, " :", sector.countAddresses
                for admStr in sector.streets:
                    echo "street:", admStr.street, "-", admStr.countAddresses
                    var linkIds: seq[string]
                    for link in admStr.roadlinks:
                        linkIds.add link.linkId
                        echo "linkId:", link.linkId, ", distr:", link.districtId
                    echo "admStr.roadlinks:", linkIds.join","
                    #quit 0
            elif s.len == 0:
                echo "no sectors:", k
        when true:
            for nameSector in admSectors["63452 Hanau"]:
                let sector = sectors[nameSector]
                echo "+"
                echo "+nameSector:", nameSector, " :", sector.countAddresses
                for admStr in sector.streets:
                    echo "+street:", admStr.street, "-", admStr.countAddresses, admStr.isStrNameEmpty
                    for link in admStr.roadlinks:
                        echo "+linkId:", link.linkId
        #for k,v in street2Sector.pairs:
            #echo "uniq street:", k.street
main()