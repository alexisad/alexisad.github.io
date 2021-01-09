import utils

type
    District* = ref object of Rootref
        id*: int
        name*: string
        polygonOuter*: seq[float]
        outerPoints*: seq[Point]
    TileId* = object
        x*, y*: int