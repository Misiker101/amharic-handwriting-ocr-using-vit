import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';

/// Thin result wrapper for the segmentation call.
class SegmentationResult {
  final String? sessionId;
  final File visualizationImage;

  SegmentationResult({required this.sessionId, required this.visualizationImage});
}

/// Thin result wrapper for the recognition call.
class RecognitionResult {
  final String text;
  /// Optional — only populated if the backend happens to include it.
  /// Safe no-op today since the current API doesn't return this key.
  final double? confidence;

  RecognitionResult({required this.text, this.confidence});
}

/// Everything that talks to the FastAPI backend lives here, isolated from
/// UI/state code. The request/response shapes are IDENTICAL to the
/// original implementation:
///
///   POST {serverUrl}/segment              multipart field "file"
///        -> 200, body = jpg bytes, header "x-session-id"
///   POST {serverUrl}/recognize/{sessionId}
///        -> 200, json body { "text": "..." }
///
/// Nothing about this contract has been changed.
class OcrApiService {
  final String serverUrl;

  const OcrApiService({required this.serverUrl});

  Future<SegmentationResult> uploadForSegmentation(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$serverUrl${AppConstants.segmentEndpoint}'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final sessionId = response.headers['x-session-id'];

      final directory = await getTemporaryDirectory();
      final visFile = File(
          '${directory.path}/vis_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await visFile.writeAsBytes(await response.stream.toBytes());

      return SegmentationResult(sessionId: sessionId, visualizationImage: visFile);
    } else {
      throw Exception("Server returned ${response.statusCode}");
    }
  }

  /// [modelVariantKey] is accepted but intentionally NOT sent to the
  /// server yet — see TODO in `OcrModelOption`. Kept as a parameter so the
  /// call site (controller) doesn't need to change again once the backend
  /// supports it; you'll just uncomment the field below.
  Future<RecognitionResult> recognize(String sessionId, {String? modelVariantKey}) async {
    var response = await http.post(
      Uri.parse('$serverUrl${AppConstants.recognizeEndpoint(sessionId)}'),
      // TODO(backend): once /recognize accepts a model selector, switch to
      // a multipart/form POST (or add ?model=... query param) e.g.:
      //   body: {'model_variant': modelVariantKey ?? ''},
      // For now we keep the exact original no-body POST so the currently
      // working single-model endpoint is never touched.
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return RecognitionResult(
        text: data['text'] as String,
        // Purely defensive - only used if/when backend adds this key.
        confidence: (data['confidence'] as num?)?.toDouble(),
      );
    } else {
      throw Exception("Server returned ${response.statusCode}");
    }
  }
}
