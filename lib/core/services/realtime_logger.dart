import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'realtime_applier.dart';

class RealtimeLoggerService {
  static RealtimeChannel? _channel;

  static void start() {
    try {
      final client = Supabase.instance.client;
      final schema = SupabaseConfig.schema.isNotEmpty
          ? SupabaseConfig.schema
          : 'public';

      // Recreate channel each start to avoid stale subscriptions (hot reload/schema change)
      if (_channel != null) {
        try {
          client.removeChannel(_channel!);
        } catch (_) {}
        _channel = null;
      }
      _channel = client.channel('realtime-logger');
      print('🔔 Realtime logger started');
      print('🔔 Schema: $schema');

      // Subscribe to relevant tables
      final tables = [
        'nomenklatura',
        'barcodes',
        'prices',
        'kontragenty',
        'service_orders',
      ];
      for (final table in tables) {
        _channel!.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: schema,
          table: table,
          callback: (payload) {
            // ignore: avoid_print
            print(
              '🔔 DB Change [${payload.eventType}] ${payload.schema}.${payload.table} -> new: ${payload.newRecord} old: ${payload.oldRecord}',
            );
            // Apply to local SQLite
            RealtimeApplier.apply(payload);
          },
        );
      }
      print('🔗 Realtime bindings set for tables: ${tables.join(', ')}');
      _channel!.subscribe((status, [error]) {
        // ignore: avoid_print
        print(
          '📡 Realtime status: $status ${error != null ? 'error: $error' : ''}',
        );
        _logActiveChannels();
      });
    } catch (e) {
      // ignore: avoid_print
      print('❌ Failed to start realtime logger: $e');
    }
  }

  static Future<void> stop() async {
    try {
      if (_channel != null) {
        await Supabase.instance.client.removeChannel(_channel!);
        _channel = null;
      }
    } catch (_) {}
  }

  static void _logActiveChannels() {
    try {
      final channels = Supabase.instance.client.getChannels();
      // ignore: avoid_print
      print('🧭 Active channels: ${channels.length}');
      for (final ch in channels) {
        // ignore: avoid_print
        print(' • topic: ${ch.topic}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Failed to list channels: $e');
    }
  }
}
