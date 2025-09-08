import 'package:flutter/material.dart';
import '../../../../common/printer/connect_printer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/label_brand.dart';
import '../../data/label_repository_impl.dart';
import '../controller/labels_controller.dart';

class LablePrintPage extends StatelessWidget {
  const LablePrintPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LabelsController(
      repository: LabelRepositoryImpl(),
      printer: PrinterConnect(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Друк етикеток')),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _button(
                context,
                'TOYA',
                () => _handlePrint(context, controller, LabelBrand.toya),
                onLongPress: () =>
                    _handlePrintCount(context, controller, LabelBrand.toya),
              ),
              const SizedBox(height: 15),
              _button(
                context,
                'MAROLEX',
                () => _handlePrint(context, controller, LabelBrand.marolex),
                onLongPress: () =>
                    _handlePrintCount(context, controller, LabelBrand.marolex),
              ),
              const SizedBox(height: 15),
              _button(
                context,
                'SAINT-GOBAIN',
                () => _handlePrint(context, controller, LabelBrand.gobain),
                onLongPress: () =>
                    _handlePrintCount(context, controller, LabelBrand.gobain),
              ),
              const SizedBox(height: 15),
              _button(
                context,
                'USH',
                () => _handlePrint(context, controller, LabelBrand.ush),
                onLongPress: () =>
                    _handlePrintCount(context, controller, LabelBrand.ush),
              ),
              const SizedBox(height: 15),
              _button(
                context,
                'STANLEY',
                () => _handlePrint(context, controller, LabelBrand.stanley),
                onLongPress: () =>
                    _handlePrintCount(context, controller, LabelBrand.stanley),
              ),
              const SizedBox(height: 15),
              _button(
                context,
                'NWS',
                () => _handlePrint(context, controller, LabelBrand.nws),
                onLongPress: () =>
                    _handlePrintCount(context, controller, LabelBrand.nws),
              ),
              const SizedBox(height: 15),
              _button(
                context,
                'STABILA',
                () => _handlePrint(context, controller, LabelBrand.stabila),
                onLongPress: () =>
                    _handlePrintCount(context, controller, LabelBrand.stabila),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(
    BuildContext context,
    String text,
    VoidCallback onPressed, {
    VoidCallback? onLongPress,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      child: SizedBox(
        height: 60,
        child: Center(
          child: Text(
            text.isNotEmpty ? text : 'test',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrint(
    BuildContext context,
    LabelsController controller,
    LabelBrand brand,
  ) async {
    final result = await controller.printLabel(brand);
    final isSuccess = result.toLowerCase().contains('успіш');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handlePrintCount(
    BuildContext context,
    LabelsController controller,
    LabelBrand brand,
  ) async {
    final controllerText = TextEditingController(text: '1');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Кількість етикеток'),
        content: TextField(
          controller: controllerText,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Введіть кількість'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Друкувати'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final count = int.tryParse(controllerText.text.trim()) ?? 0;
      final result = await controller.printLabelCount(brand, count);
      final isSuccess = result.toLowerCase().contains('успіш');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
