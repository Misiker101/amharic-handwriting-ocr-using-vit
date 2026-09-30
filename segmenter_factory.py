from segmenter import HybridAStarSegmenter
from segmenter_kraken import KrakenLineSegmenter

SEGMENTER_REGISTRY = {
    "astar": HybridAStarSegmenter,
    "kraken": KrakenLineSegmenter,
}

DEFAULT_ALGORITHM = "astar"  



