import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import '../models/ocr_model_option.dart';
import '../models/ocr_state.dart';
import '../models/scan_history_item.dart';
import '../services/history_service.dart';
import '../services/ocr_api_service.dart';
import '../services/settings_service.dart';

class OcrController extends ChangeNotifier {
  OcrPhase phase = OcrPhase.idle;
  String statusMessage = "";
  File? visualizationImage;
  String? sessionId;
  String? finalText;
  String? errorMessage;

  OcrModelOption selectedModel = OcrModelOption.defaultOption;
  String serverUrl = "";

  bool get isLoading =>
      phase == OcrPhase.uploadingSegmentation || phase == OcrPhase.recognizing;

  Future<void> loadSettings() async {
    serverUrl = await SettingsService.getServerUrl();
    selectedModel = await SettingsService.getSelectedModel();
    notifyListeners();
  }

  Future<void> updateSelectedModel(OcrModelOption option) async {
    selectedModel = option;
    await SettingsService.setSelectedModel(option);
    notifyListeners();
  }

  Future<void> updateServerUrl(String url) async {
    serverUrl = url;
    await SettingsService.setServerUrl(url);
    notifyListeners();
  }

  OcrApiService get _api => OcrApiService(serverUrl: serverUrl);

  Future<void> scanDocument() async {
    final options = DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full,
      pageLimit: 1,
      isGalleryImport: true,
    );

    final documentScanner = DocumentScanner(options: options);

    try {
      final result = await documentScanner.scanDocument();
      if (result != null && result.images.isNotEmpty) {
        final scannedImage = File(result.images.first);
        await _uploadForSegmentation(scannedImage);
      }
    } catch (e) {
      errorMessage = 'Scanner error: $e';
      notifyListeners();
    }
  }

  /// Step 2
  Future<void> _uploadForSegmentation(File imageFile) async {
    phase = OcrPhase.uploadingSegmentation;
    statusMessage = "Uploading & processing A* segmentation on PC...";
    finalText = null;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.uploadForSegmentation(imageFile);
      sessionId = result.sessionId;
      visualizationImage = result.visualizationImage;
      phase = OcrPhase.segmented;
    } catch (e) {
      phase = OcrPhase.error;
      errorMessage = 'Network error: make sure the Python server is running.\nDetails: $e';
    }
    notifyListeners();
  }

  /// Step 3
  Future<void> proceedToRecognition() async {
    if (sessionId == null) return;

    phase = OcrPhase.recognizing;
    statusMessage = "Running Hybrid ViT batch inference...";
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.recognize(sessionId!, modelVariantKey: selectedModel.backendKey);
      finalText = result.text;
      phase = OcrPhase.completed;

      // Client-side only: keep a local record of this transcript.
      await HistoryService.add(
        ScanHistoryItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          text: result.text,
          modelLabel: selectedModel.label,
          visualizationPath: visualizationImage?.path,
        ),
      );
    } catch (e) {
      phase = OcrPhase.error;
      errorMessage = 'Recognition error: $e';
    }
    notifyListeners();
  }

  void retryFromError() {
    if (sessionId != null && visualizationImage != null) {
      // We already have a segmented session — let the user try recognition again.
      phase = OcrPhase.segmented;
      errorMessage = null;
    } else {
      resetApp();
    }
    notifyListeners();
  }

  void resetApp() {
    phase = OcrPhase.idle;
    visualizationImage = null;
    finalText = null;
    sessionId = null;
    errorMessage = null;
    statusMessage = "";
    notifyListeners();
  }
}