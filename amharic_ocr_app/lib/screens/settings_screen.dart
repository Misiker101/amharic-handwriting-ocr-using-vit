import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../models/ocr_model_option.dart';
import '../services/settings_service.dart';
import '../widgets/model_selector_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  OcrModelOption _model = OcrModelOption.defaultOption;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final url = await SettingsService.getServerUrl();
    final model = await SettingsService.getSelectedModel();
    setState(() {
      _urlController.text = url;
      _model = model;
      _loading = false;
    });
  }

  Future<void> _saveUrl() async {
    final value = _urlController.text.trim();
    if (value.isEmpty) return;
    await SettingsService.setServerUrl(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server address saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Backend Server', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'The FastAPI + Uvicorn server running on your PC. If using an '
                'Android emulator use 10.0.2.2; on a physical device use your '
                "PC's IPv4 address on the same Wi-Fi network.",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: AppConstants.defaultServerUrl,
              prefixIcon: Icon(Icons.dns_outlined),
            ),
            onSubmitted: (_) => _saveUrl(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(onPressed: _saveUrl, child: const Text('Save')),
          ),
          const SizedBox(height: 28),
          Text('Recognizer Model', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Selecting a model here is remembered across sessions. '
                'Requires backend support to actually switch checkpoints '
                '(see TODO in code) — today the server always runs the '
                'bundled Hybrid ViT checkpoint regardless of this choice.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: const Icon(Icons.psychology_outlined),
              title: Text(_model.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(_model.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final chosen = await showModelSelectorSheet(context, current: _model);
                if (chosen != null) {
                  await SettingsService.setSelectedModel(chosen);
                  setState(() => _model = chosen);
                }
              },
            ),
          ),
          const SizedBox(height: 28),
          Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Multi-Line Amharic Handwritten Document OCR Using Hybrid '
                    'Vision Transformers (ViT).\n\n'
                    'Frontend: Flutter + Google ML Kit Document Scanner\n'
                    'Backend: FastAPI + Hybrid A* Segmentation + PyTorch',
                style: TextStyle(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
