import 'package:flutter/material.dart';

import '../controllers/ocr_controller.dart';
import '../models/ocr_state.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/model_selector_sheet.dart';
import '../widgets/recognition_result_view.dart';
import '../widgets/scan_launch_card.dart';
import '../widgets/segmentation_review_view.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OcrController _controller = OcrController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.loadSettings();
  }

  void _onControllerChanged() {
    if (_controller.errorMessage != null && _controller.phase != OcrPhase.error) {
      // Scanner-level error (doesn't move the phase) -> just toast it.
      final msg = _controller.errorMessage!;
      _controller.errorMessage = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  Future<void> _pickModel() async {
    final chosen = await showModelSelectorSheet(context, current: _controller.selectedModel);
    if (chosen != null) {
      await _controller.updateSelectedModel(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amharic OCR'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              await _controller.loadSettings();
            },
          ),
          if (_controller.phase != OcrPhase.idle)
            IconButton(
              tooltip: 'Start over',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _controller.resetApp,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: SingleChildScrollView(
            key: ValueKey(_controller.phase),
            padding: const EdgeInsets.all(20),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_controller.phase) {
      case OcrPhase.idle:
        return ScanLaunchCard(
          onScan: _controller.scanDocument,
          selectedModel: _controller.selectedModel,
          onChangeModel: _pickModel,
        );

      case OcrPhase.uploadingSegmentation:
      case OcrPhase.recognizing:
        return LoadingOverlay(phase: _controller.phase, statusMessage: _controller.statusMessage);

      case OcrPhase.segmented:
        return SegmentationReviewView(
          visualizationImage: _controller.visualizationImage!,
          onDiscard: _controller.resetApp,
          onApprove: _controller.proceedToRecognition,
        );

      case OcrPhase.completed:
        return RecognitionResultView(
          text: _controller.finalText ?? '',
          modelLabel: _controller.selectedModel.label,
          onScanAnother: _controller.resetApp,
        );

      case OcrPhase.error:
        return ErrorView(
          message: _controller.errorMessage ?? 'Unknown error',
          onRetry: _controller.retryFromError,
          onStartOver: _controller.resetApp,
        );
    }
  }
}
