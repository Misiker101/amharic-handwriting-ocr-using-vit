import 'package:flutter/material.dart';

import '../models/ocr_state.dart';

class LoadingOverlay extends StatelessWidget {
  final OcrPhase phase;
  final String statusMessage;

  const LoadingOverlay({super.key, required this.phase, required this.statusMessage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUploading = phase == OcrPhase.uploadingSegmentation;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(strokeWidth: 4, color: scheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            statusMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _StepDots(activeIndex: isUploading ? 0 : 1),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int activeIndex; // 0 = segmenting, 1 = recognizing
  const _StepDots({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget dot(int i, String label) {
      final active = i == activeIndex;
      final done = i < activeIndex;
      return Column(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active || done ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: active ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              )),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(0, 'Segment'),
        Container(width: 32, height: 1, color: scheme.outlineVariant, margin: const EdgeInsets.symmetric(horizontal: 8)),
        dot(1, 'Recognize'),
      ],
    );
  }
}
