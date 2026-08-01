import 'dart:io';

import 'package:flutter/material.dart';

class SegmentationReviewView extends StatelessWidget {
  final File visualizationImage;
  final VoidCallback onDiscard;
  final VoidCallback onApprove;

  const SegmentationReviewView({
    super.key,
    required this.visualizationImage,
    required this.onDiscard,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.route_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              "Step 1 · Evaluate A* Segmentation",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Pinch to zoom and check that each line was separated correctly before running recognition.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(20),
            ),
            height: 360,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Image.file(visualizationImage, fit: BoxFit.contain, width: double.infinity),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDiscard,
                icon: const Icon(Icons.refresh),
                label: const Text('Discard & Retake'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Approve & Recognize'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
