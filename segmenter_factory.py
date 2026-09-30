from segmenter import HybridAStarSegmenter
from segmenter_kraken import KrakenLineSegmenter

SEGMENTER_REGISTRY = {
    "astar": HybridAStarSegmenter,
    "kraken": KrakenLineSegmenter,
}

DEFAULT_ALGORITHM = "astar"  


def get_segmenter(algorithm: str = DEFAULT_ALGORITHM):
    key = (algorithm or DEFAULT_ALGORITHM).lower()
    if key not in SEGMENTER_REGISTRY:
        raise ValueError(f"Unknown segmentation algorithm '{algorithm}'. "
                          f"Choose one of: {list(SEGMENTER_REGISTRY)}")
    return SEGMENTER_REGISTRY[key]()
