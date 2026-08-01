import 'package:flutter/material.dart';

import '../models/ocr_model_option.dart';

class ScanLaunchCard extends StatelessWidget {
  final VoidCallback onScan;
  final OcrModelOption selectedModel;
  final VoidCallback onChangeModel;

  const ScanLaunchCard({
    super.key,
    required this.onScan,
    required this.selectedModel,
    required this.onChangeModel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.document_scanner_rounded, size: 56, color: Colors.white),
        ),
        const SizedBox(height: 28),
        Text(
          'Scan a handwritten page',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Auto border detection, deskewing, and contrast\nnormalization run right on your device.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onScan,
          icon: const Icon(Icons.document_scanner_outlined),
          label: const Text('Scan Handwritten Document'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onChangeModel,
          icon: const Icon(Icons.psychology_outlined),
          label: Text('Model: ${selectedModel.label}'),
        ),
      ],
    );
  }
}
