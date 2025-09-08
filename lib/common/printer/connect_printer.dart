import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterConnect {
  Future<void> connectToPrinter(String label) async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('printer_host') ?? '';
    final portStr = prefs.getString('printer_port') ?? '9100';

    if (host.isEmpty) {
      throw Exception('Хост принтера не налаштований');
    }

    int port;
    try {
      port = int.parse(portStr);
    } catch (_) {
      throw Exception('Некоректний порт принтера: "$portStr"');
    }

    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.write(label);
      await socket.flush();
      await socket.close();
      await socket.done;
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 110 ||
          e.message.toLowerCase().contains('timed')) {
        throw Exception('Час підключення до принтера вийшов');
      }
      throw Exception('Не вдалося підключитися до принтера: ${e.message}');
    } catch (e) {
      throw Exception('Помилка надсилання на друк: $e');
    }
  }

  /// Connect once and send the same label [count] times.
  Future<void> connectToPrinterMultiple(String label, int count) async {
    if (count <= 0) {
      throw Exception('Кількість має бути більшою за 0');
    }

    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('printer_host') ?? '';
    final portStr = prefs.getString('printer_port') ?? '9100';

    if (host.isEmpty) {
      throw Exception('Хост принтера не налаштований');
    }

    int port;
    try {
      port = int.parse(portStr);
    } catch (_) {
      throw Exception('Некоректний порт принтера: "$portStr"');
    }

    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      for (int i = 0; i < count; i++) {
        socket.write(label);
      }
      await socket.flush();
      await socket.close();
      await socket.done;
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 110 ||
          e.message.toLowerCase().contains('timed')) {
        throw Exception('Час підключення до принтера вийшов');
      }
      throw Exception('Не вдалося підключитися до принтера: ${e.message}');
    } catch (e) {
      throw Exception('Помилка надсилання на друк: $e');
    }
  }
}
