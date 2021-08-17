import utils, strutils, tables, unicode, sugar, hashes
import nre except toSeq

type
    District* = ref object of Rootref
        id*: string
        name*: string
        polygonOuter*: seq[float]
        outerPoints*: seq[Point]
    TileId* = object
        x*, y*: int
    RoadLink* = ref object of Rootref
        linkId*: string
        name*: seq[StreetName]
        disstrictId*: string
        cityId*: string
        coords*: seq[Point]
        linkLen*: float
        refLinks*: seq[string]
        nonRefLinks*: seq[string]
        postalCode*: string
    StreetNameType* = enum
        abbreviation = 'A', baseName = 'B',
        exonym = 'E', shortenedName = 'K',
        synonym = 'S'
    StreetNameKind* = enum
        name, translit, phoneme
    StreetName* = ref object of Rootref
        name*: string
        lang*: LangCode
        nameType*: StreetNameType
        nameKind*: StreetNameKind
    LangCode* = distinct string


proc hashCityPc*(x: RoadLink): Hash =
    result = x.cityId.hash !& x.postalCode.hash
    result = !$result



proc parseStreetNames*(strEnc: string): seq[StreetName] {.inline.} =
    #echo "strEnc:", strEnc
    let arrLngStr = strEnc.split '\x1d'
    #if arrLngStr.len > 0:
        #echo "arrLngStr:", arrLngStr
    for lng in arrLngStr:
        let arrName = lng.split '\x1e'
        var streetName: StreetName
        if arrName.len > 0:
            let
                lngCode = arrName[0].runeSubStr(0, 3)
                nameTyp = StreetNameType arrName[0].runeSubStr(3, 1)[0]
                nameTxt = arrName[0].runeSubStr(5)
            streetName = StreetName(name: nameTxt, lang: lngCode.LangCode, nameType: nameTyp)
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
        result.add streetName
        #echo "arrName:", arrName


proc streetName*(it: RoadLink, lang = "GER".LangCode): string =
    var street = collect(initTable()):
        for s in it.name:
            {s.lang.string: s.name}
    for s in it.name:
        echo "strName:", s.lang.string, " ", s.name, " ", s.nameType, " ", s.nameKind
        if s.nameType != StreetNameType.baseName:
            continue
        if s.nameKind != StreetNameKind.name:
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