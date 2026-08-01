///
/// TODO(backend): the FastAPI `/recognize/{session_id}` route currently
/// always loads a single fixed checkpoint (`hybrid_vit.pth`). To actually
/// let the app switch models at inference time, the backend needs a small
/// addition, e.g.:
///
///   @app.post("/recognize/{session_id}")
///   async def recognize(session_id: str, model_variant: str = Form("hybrid_vit_6")):
///       engine = MODEL_REGISTRY[model_variant]   # lazy-load / cache per variant
///       ...
///
/// Until that lands, this enum + selector are wired up end-to-end in the UI
/// and persisted locally, but `OcrApiService` intentionally does NOT send
/// the selection over the wire yet — so nothing about the existing,
/// working request/response contract is touched. Flip the flag in
/// `OcrApiService.sendModelSelection` once the backend is ready.
enum OcrModelVariant {
  hybridVit2,
  hybridVit4,
  hybridVit6,
  hybridVit8,
  pureVit,
  standardTransformer,
  cnnBiGruCtc,
  resnet18,
}

class OcrModelOption {
  final OcrModelVariant variant;
  final String backendKey;
  final String label;
  final String description;
  final bool isDefault;

  const OcrModelOption({
    required this.variant,
    required this.backendKey,
    required this.label,
    required this.description,
    this.isDefault = false,
  });

  static const List<OcrModelOption> all = [
    OcrModelOption(
      variant: OcrModelVariant.hybridVit6,
      backendKey: "hybrid_vit_6",
      label: "Hybrid ViT (6 layers)",
      description: "CNN + ViT encoder, 6 layers — best accuracy/speed balance.",
      isDefault: true,
    ),
    OcrModelOption(
      variant: OcrModelVariant.hybridVit2,
      backendKey: "hybrid_vit_2",
      label: "Hybrid ViT (2 layers)",
      description: "Lightest hybrid variant — fastest inference.",
    ),
    OcrModelOption(
      variant: OcrModelVariant.hybridVit4,
      backendKey: "hybrid_vit_4",
      label: "Hybrid ViT (4 layers)",
      description: "Mid-depth hybrid encoder.",
    ),
    OcrModelOption(
      variant: OcrModelVariant.hybridVit8,
      backendKey: "hybrid_vit_8",
      label: "Hybrid ViT (8 layers)",
      description: "Deepest hybrid variant — highest capacity.",
    ),
    OcrModelOption(
      variant: OcrModelVariant.pureVit,
      backendKey: "pure_vit",
      label: "Pure ViT",
      description: "No CNN front-end — raw patch-based Vision Transformer.",
    ),
    OcrModelOption(
      variant: OcrModelVariant.standardTransformer,
      backendKey: "standard_transformer",
      label: "Standard Transformer",
      description: "Classic encoder-decoder Transformer baseline.",
    ),
    OcrModelOption(
      variant: OcrModelVariant.cnnBiGruCtc,
      backendKey: "cnn_bigru_ctc",
      label: "CNN-BiGRU-CTC",
      description: "Sequence baseline: CNN features + BiGRU + CTC decoding.",
    ),
    OcrModelOption(
      variant: OcrModelVariant.resnet18,
      backendKey: "resnet18",
      label: "ResNet18 Baseline",
      description: "Convolutional-only baseline for comparison.",
    ),
  ];

  static OcrModelOption byBackendKey(String key) {
    return all.firstWhere(
          (m) => m.backendKey == key,
      orElse: () => all.firstWhere((m) => m.isDefault),
    );
  }

  static OcrModelOption get defaultOption =>
      all.firstWhere((m) => m.isDefault);
}
