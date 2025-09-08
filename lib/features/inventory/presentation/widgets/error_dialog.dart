import 'package:flutter/material.dart';

/// Widget for displaying error dialogs
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryText;

  const ErrorDialog({
    super.key,
    this.title = 'Помилка',
    required this.message,
    this.onRetry,
    this.retryText = 'Спробувати знову',
  });

  /// Show error dialog
  static void show(
    BuildContext context, {
    String title = 'Помилка',
    required String message,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
        retryText: retryText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        if (onRetry != null) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: Text(retryText!),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
