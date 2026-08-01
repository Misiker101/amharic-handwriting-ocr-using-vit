import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onStartOver;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onStartOver,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: scheme.error),
              const SizedBox(width: 8),
              Text('Something went wrong',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, color: scheme.onErrorContainer)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: scheme.onErrorContainer, height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: onStartOver, child: const Text('Start Over')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
