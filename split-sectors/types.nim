import utils

type
    District* = ref object of Rootref
        id*: string
        name*: string
        polygonOuter*: seq[float]
        outerPoints*: seq[Point]
    TileId* = object
        x*, y*: int
    Road* = ref object of Rootref
        linkId*: string
        name*: string
        disstrictId*: string
        cityId*: string
        coords*: seq[Point]
        linkLen*: float
        refLinks*: seq[string]
        nonRefLinks*: seq[string]
        #postalCode*: int