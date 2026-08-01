import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/scan_history_item.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanHistoryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await HistoryService.getHistory();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                await HistoryService.clear();
                _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? _EmptyState(scheme: scheme)
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final item = _items[i];
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
            ),
            onDismissed: (_) async {
              await HistoryService.remove(item.id);
              setState(() => _items.removeAt(i));
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(item.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(item.modelLabel, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('${item.wordCount} words · ${item.lineCount} lines',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        const Spacer(),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: item.text));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.ios_share, size: 18),
                          onPressed: () => Share.share(item.text),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (sameDay) return 'Today · $h:$m';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} · $h:$m';
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme scheme;
  const _EmptyState({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No scans yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Recognized documents will show up here so you never lose a transcript.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
