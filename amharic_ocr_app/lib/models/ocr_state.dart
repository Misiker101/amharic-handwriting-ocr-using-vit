/// The four screens/phases of the flow — identical logic to the original
/// (scan -> segment -> approve -> recognize), just modeled explicitly
/// instead of being inferred from nullable fields.
enum OcrPhase {
  idle,
  uploadingSegmentation,
  segmented, // waiting for user to Approve & Recognize (or discard)
  recognizing,
  completed,
  error,
}
