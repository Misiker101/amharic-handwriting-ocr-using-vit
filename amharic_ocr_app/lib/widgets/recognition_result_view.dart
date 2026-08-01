import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/result_formatter.dart';

class RecognitionResultView extends StatefulWidget {
  final String text;
  final String modelLabel;
  final VoidCallback onScanAnother;

  const RecognitionResultView({
    super.key,
    required this.text,
    required this.modelLabel,
    required this.onScanAnother,
  });

  @override
  State<RecognitionResultView> createState() => _RecognitionResultViewState();
}

class _RecognitionResultViewState extends State<RecognitionResultView> {
  late TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(covariant RecognitionResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.text = widget.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lines = ResultFormatter.splitLines(_controller.text);
    final words = ResultFormatter.wordCount(_controller.text);
    final chars = ResultFormatter.charCount(_controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.text_snippet_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              "Step 2 · Recognition Result",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Chip(label: Text(widget.modelLabel, style: const TextStyle(fontSize: 12))),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatChip(icon: Icons.notes, label: '${lines.length} lines'),
            _StatChip(icon: Icons.short_text, label: '$words words'),
            _StatChip(icon: Icons.abc, label: '$chars characters'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: _editing
              ? TextField(
            controller: _controller,
            maxLines: null,
            style: const TextStyle(fontSize: 20, height: 1.9),
            decoration: const InputDecoration(
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          )
              : SelectableText(
            _controller.text,
            style: const TextStyle(fontSize: 20, height: 1.9),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _editing = !_editing),
              icon: Icon(_editing ? Icons.check : Icons.edit_outlined, size: 18),
              label: Text(_editing ? 'Done editing' : 'Edit text'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _controller.text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Share.share(_controller.text);
              },
              icon: const Icon(Icons.ios_share, size: 18),
              label: const Text('Share'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          onPressed: widget.onScanAnother,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Scan Another Document'),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }
}
