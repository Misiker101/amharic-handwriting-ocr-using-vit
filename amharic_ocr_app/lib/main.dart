import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

void main() {
  runApp(const AmharicOcrApp());
}

class AmharicOcrApp extends StatelessWidget {
  const AmharicOcrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amharic OCR Thesis',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OcrHomeScreen(),
    );
  }
}

class OcrHomeScreen extends StatefulWidget {
  const OcrHomeScreen({super.key});

  @override
  State<OcrHomeScreen> createState() => _OcrHomeScreenState();
}

class _OcrHomeScreenState extends State<OcrHomeScreen> {
  // IMPORTANT: Network Configuration
  // If using Android Emulator, use "10.0.2.2" to reach your Windows PC localhost.
  // If using a physical Android device, use your PC's IPv4 address on the Wi-Fi network (e.g., 192.168.1.5).
  final String ip = "10.140.163.42";
  final String serverUrl = "http://192.168.137.1:8000";

  bool _isLoading = false;
  String _statusMessage = "";
  File? _visualizationImage;
  String? _sessionId;
  String? _finalText;

  Future<void> _scanAndSegment() async {
    // 1. Launch Google ML Kit Document Scanner
    // This provides the native auto-border detection and deskewing interface.
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
        File scannedImage = File(result.images.first);
        await _uploadForSegmentation(scannedImage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanner Error: $e')),
      );
    }
  }

  Future<void> _uploadForSegmentation(File imageFile) async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Uploading & processing A* segmentation on PC...";
      _finalText = null;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$serverUrl/segment'));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        // Retrieve the Session ID mapped by FastAPI
        _sessionId = response.headers['x-session-id'];

        // Save the received "smoothed separating paths" image to local storage
        final directory = await getTemporaryDirectory();
        final visFile = File('${directory.path}/vis_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await visFile.writeAsBytes(await response.stream.toBytes());

        setState(() {
          _visualizationImage = visFile;
          _isLoading = false;
        });
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network Error: Make sure Python server is running.\nDetails: $e')),
      );
    }
  }

  Future<void> _proceedToRecognition() async {
    if (_sessionId == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = "Running Hybrid ViT batch inference...";
    });

    try {
      var response = await http.post(Uri.parse('$serverUrl/recognize/$_sessionId'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          // FIX: Changed from data['transcription'] to data['text'] to match the FastAPI JSON response payload
          _finalText = data['text'];
          _isLoading = false;
        });
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recognition Error: $e')),
      );
    }
  }

  void _resetApp() {
    setState(() {
      _visualizationImage = null;
      _finalText = null;
      _sessionId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amharic OCR Inference'),
        actions: [
          if (_visualizationImage != null || _finalText != null)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _resetApp)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            ],

            // Phase 1: Idle - Ready to Scan
            if (!_isLoading && _visualizationImage == null && _finalText == null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                icon: const Icon(Icons.document_scanner, size: 30),
                label: const Text('Scan Handwritten Document', style: TextStyle(fontSize: 18)),
                onPressed: _scanAndSegment,
              ),

            // Phase 2: Segmentation Verification
            if (!_isLoading && _visualizationImage != null && _finalText == null) ...[
              const Text(
                "Step 1: Evaluate A* Segmentation",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                child: Image.file(_visualizationImage!),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetApp,
                      child: const Text('Discard & Retake'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _proceedToRecognition,
                      child: const Text('Approve & Recognize'),
                    ),
                  ),
                ],
              )
            ],

            // Phase 3: Final Recognition Output
            if (!_isLoading && _finalText != null) ...[
              const Text(
                "Step 2: Recognition Result",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _finalText!,
                  style: const TextStyle(fontSize: 20, height: 1.8),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}