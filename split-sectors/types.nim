import utils, strutils, tables, unicode, sugar, hashes
#import nre except toSeq

export hashes

type
    Sector* = ref object
        name*: string
        streets*: seq[AdminStreet]
    City* = ref object
        id*: string
        name*: string
        pdeName*: seq[PdeName]
    District* = ref object
        id*: string
        name*: string
        pdeName*: seq[PdeName]
        polygonOuter*: seq[float]
        outerPoints*: seq[Point]
    Admin* = ref object
        city*: City
        postalCode*: string
        district*: District
    AdminStreet* = ref object
        city*: City
        postalCode*: string
        district*: District
        street*: string
        roadlinks*: seq[RoadLink]
    TileId* = object
        x*, y*: int
    TileLayerSet* = ref object
        layers*: seq[string]
        levels*: seq[int]
        tileXys*: seq[string]
    TileLayerSetDistribBy* = ref object
        layrs*: seq[seq[string]]
        levels*: seq[seq[int]]
        tileXys*: seq[seq[string]]
    Area* = ref object
        roadLinks*: TableRef[string, RoadLink]
        cities*: TableRef[string, City]
        districts*: TableRef[string, District]
    RoadLink* = ref object
        linkId*: string
        name*: seq[PdeName]
        disstrictId*: string
        cityId*: string
        coords*: seq[Point]
        refNodeCoord*: Point
        nonRefNodeCoord*: Point
        linkLen*: float
        refLinks*: seq[string]
        nonRefLinks*: seq[string]
        postalCode*: string
        addresses*: seq[string]
    PdeNameType* = enum
        abbreviation = "A - abbreviation", baseName = "B - base name",
        exonym = "E - exonym", shortenedName = "K - shortened name",
        synonym = "S - synonym", unknown = "unknown"
    PdeNameKind* = enum
        name, translit, phoneme
    PdeName* = ref object
        name*: string
        lang*: LangCode
        nameType*: PdeNameType
        nameKind*: PdeNameKind
    LangCode* = distinct string

proc encodeName*(it: seq[PdeName], lang = "GER".LangCode): string

proc hashCityPc*(x: RoadLink): Hash =
    result = x.cityId.hash !& x.postalCode.hash
    result = !$result

proc hash*(x: LangCode): Hash =
    result = string(x).hash
    result = !$result

proc hash*(x: Admin): Hash =
    result = x.postalCode.hash !& x.city.pdeName.encodeName.hash !&
                x.district.pdeName.encodeName.hash
    result = !$result


proc hash*(x: AdminStreet): Hash =
    result = x.postalCode.hash !& x.city.pdeName.encodeName.hash !&
                x.district.pdeName.encodeName.hash !& x.street.hash
    result = !$result

proc hashAdm*(x: AdminStreet): Hash =
    let adm = Admin(postalCode: x.postalCode, city: x.city, district: x.district)
    adm.hash


func countAddresses*(admStr: AdminStreet): int =
    for link in admStr.roadlinks:
        result += link.addresses.len

func countAddresses*(sector: Sector): int =
    for street in sector.streets:
        result += street.countAddresses

proc getEnumTypeStreet(x: char): PdeNameType =
    case x
    of 'A':
        result = PdeNameType.abbreviation
    of 'B':
        result = PdeNameType.baseName
    of 'E':
        result = PdeNameType.exonym
    of 'K':
        result = PdeNameType.shortenedName
    of 'S':
        result = PdeNameType.synonym
    else:
        result = PdeNameType.unknown
    

proc parsePdeNames*(strEnc: string): seq[PdeName] {.inline.} =
    #echo "strEnc:", strEnc
    let arrLngStr = strEnc.split '\x1d'
    #if arrLngStr.len > 0:
        #echo "arrLngStr:", arrLngStr
    for lng in arrLngStr:
        let arrName = lng.split '\x1e'
        var pdeName: PdeName
        if arrName.len > 0:
            let
                lngCode = arrName[0].runeSubStr(0, 3)
                nameTyp = getEnumTypeStreet arrName[0].runeSubStr(3, 1)[0]
                nameTxt = arrName[0].runeSubStr(5)
            pdeName = PdeName(name: nameTxt, lang: lngCode.LangCode, nameType: nameTyp)
            #echo "arrName[0]:", arrName[0]
            #echo "lngCode:", lngCode
            #echo "nameTyp:", nameTyp
            #echo "nameTxt:", nameTxt
        if arrName.len > 1:
            let arrTranslTmp = arrName[1].split ';'
            let arrTransl = collect(newSeq):
                for t in arrTranslTmp:
                    if unicode.strip(t) != "":
                        t
            if arrTransl.len > 0:
                echo "arrTransl:", arrTransl
        when false:
            if arrName.len > 2:
                let arrPhonemTmp = arrName[2].split ';'
                let arrPhonem = collect(newSeq):
                    for t in arrPhonemTmp:
                        if unicode.strip(t) != "":
                            t
                if arrPhonem.len > 0:
                    echo "arrPhonem:", arrPhonem[0]
                    let
                        lngCodePhon = arrPhonem[0].runeSubStr(0, 3)
                        isPreferedPhon = arrPhonem[0].runeSubStr(3, 1)
                        nameTxtPhon = arrPhonem[0].runeSubStr(5)
                    echo "nameTxtPhon:", nameTxtPhon
                    #discard
        result.add pdeName
        #echo "arrName:", arrName


proc encodeName*(it: seq[PdeName], lang = "GER".LangCode): string =
    var street = collect(initTable):
        for s in it:
            {s.lang.string: s.name}
    for s in it:
        #echo "strName:", s.lang.string, " ", s.name, " nameType:", s.nameType, " nameKind:", s.nameKind
        if s.nameType != PdeNameType.baseName:
            continue
        if s.nameKind != PdeNameKind.name:
            continue
        if street[s.lang.string].len < s.name.len:
            street[s.lang.string] = s.name
        #if find(s, re"^.*\d+").isNone: #none digital in street name
        #var sTmp = ""
        #for s in it.name:
    if (street.hasKey lang.string):
        return street[lang.string]
    if (street.hasKey "ENG"):
        return street["ENG"]
    for s in street.values:
        result = s
        break

