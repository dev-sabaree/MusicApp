import 'package:flutter/material.dart';

class CustomErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const CustomErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.redAccent.shade100),
            const SizedBox(height: 16),
            Text(
              "Something went wrong",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text("Try Again"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
