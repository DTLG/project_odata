import 'package:flutter/material.dart';

Future<void> askSchema(BuildContext context, Function(String) setSchema) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Схема бази даних'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Введіть назву схеми'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Скасувати'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: const Text('Продовжити'),
        ),
      ],
    ),
  );
  if (result != null) {
    setSchema(result.trim().isEmpty ? 'public' : result.trim());
  }
}
