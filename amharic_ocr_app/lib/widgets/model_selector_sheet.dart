import 'package:flutter/material.dart';

import '../models/ocr_model_option.dart';

/// Shows the available recognizer architectures (Hybrid ViT depths,
/// pure ViT, standard Transformer, and the CNN-BiGRU-CTC / ResNet18
/// baselines) and lets the user pick which one they *intend* to use.
///
/// See the TODO in `OcrModelOption` — selecting a model here is persisted
/// locally and shown throughout the UI, but is not yet transmitted to the
/// backend, since the current `/recognize` endpoint always runs the single
/// bundled checkpoint. Wiring this up is a backend-side change.
Future<OcrModelOption?> showModelSelectorSheet(
    BuildContext context, {
      required OcrModelOption current,
    }) {
  return showModalBottomSheet<OcrModelOption>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recognizer Model',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Choose which architecture to run inference with.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: OcrModelOption.all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final option = OcrModelOption.all[i];
                    final selected = option.backendKey == current.backendKey;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(ctx).pop(option),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: selected ? scheme.primary : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(option.label,
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(option.description,
                                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
