import 'package:flutter/material.dart';
import 'package:generic_networking/generic_networking.dart';

import '../network/network_providers.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final type = error is ApiException ? (error as ApiException).type : null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == NetworkErrorType.noConnection ? Icons.wifi_off : Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(errorMessage(error), textAlign: TextAlign.center),
            if (type != null) ...[
              const SizedBox(height: 4),
              Text(
                '${type.name} · ${(error as ApiException).statusCode ?? 'no status'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
