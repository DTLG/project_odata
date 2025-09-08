import '../../../../common/printer/connect_printer.dart';
import '../../domain/label_brand.dart';
import '../../domain/label_repository.dart';

class LabelsController {
  final LabelRepository repository;
  final PrinterConnect printer;

  LabelsController({required this.repository, required this.printer});

  /// Prints a label and returns a human-readable result message.
  /// Throws no exception; maps errors to messages.
  Future<String> printLabel(LabelBrand brand) async {
    try {
      final zpl = await repository.buildZpl(brand);
      await printer.connectToPrinter(zpl);
      return 'Етикетку успішно надіслано на друк';
    } catch (e) {
      final msg = _mapErrorToMessage(e);
      return msg;
    }
  }

  /// Prints the label multiple times. Aggregates successes/failures.
  Future<String> printLabelCount(LabelBrand brand, int count) async {
    if (count <= 0) {
      return 'Кількість має бути більшою за 0';
    }
    try {
      final zpl = await repository.buildZpl(brand);
      await printer.connectToPrinterMultiple(zpl, count);
      return 'Успішно надіслано $count етикеток на друк';
    } catch (e) {
      return _mapErrorToMessage(e);
    }
  }

  String _mapErrorToMessage(Object e) {
    final text = e.toString().toLowerCase();
    if (text.contains('bluetooth') && text.contains('off')) {
      return 'Bluetooth вимкнено. Увімкніть Bluetooth і повторіть спробу';
    }
    if (text.contains('permission')) {
      return 'Немає дозволів на підключення до принтера';
    }
    if (text.contains('timeout')) {
      return 'Час підключення до принтера вийшов';
    }
    if (text.contains('not found') || text.contains('unavailable')) {
      return 'Принтер не знайдено. Перевірте живлення та підключення';
    }
    if (text.contains('zpl') ||
        text.contains('build') ||
        text.contains('format')) {
      return 'Помилка формування ZPL. Перевірте шаблон етикетки';
    }
    return 'Помилка друку: $e';
  }
}
