import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// import removed: order_config is unused in Supabase flow
import '../config/supabase_config.dart';

/// Service for creating orders in the database
class OrderCreationService {
  final SupabaseClient? supabase;

  OrderCreationService({this.supabase});

  /// Create order in the database
  Future<void> createOrder(
    String clientGuid,
    List<Map<String, dynamic>> goodsList,
  ) async {
    if (supabase == null) {
      throw Exception('Supabase client is not initialized');
    }
    try {
      // Use schema stored in SharedPreferences
      final schema = SupabaseConfig.schema.isNotEmpty
          ? SupabaseConfig.schema
          : 'public';
      final payload = {
        'kontragent': clientGuid,
        'tovaru': goodsList,
        'created_at': DateTime.now().toIso8601String(),
      };
      await supabase!.schema(schema).from('orders').insert(payload);
      // Mark local orders as sent instead of clearing DB entirely
      await _markLocalOrdersAsSent();
    } catch (e) {
      throw Exception('Supabase insert failed: $e');
    }
  }

  // Legacy OData helpers removed in Supabase build

  /// Mark orders as sent inside JSON payloads
  Future<void> _markLocalOrdersAsSent() async {
    try {
      // Open the same DB file path as OrdersLocalDataSourceImpl
      final dbDir = await getDatabasesPath();
      final dbPath = join(dbDir, 'customer_orders.db');
      final db = await openDatabase(dbPath);
      final rows = await db.query('orders');
      for (final r in rows) {
        final id = r['id'] as String;
        final data = r['data'] as String;
        try {
          final map = jsonDecode(data) as Map<String, dynamic>;
          map['is_sent'] = true;
          await db.update(
            'orders',
            {'data': jsonEncode(map)},
            where: 'id = ?',
            whereArgs: [id],
          );
        } catch (_) {
          // Skip malformed entries
        }
      }
      // Do not close here to avoid interfering with shared connections
    } catch (e) {
      print('Warning: Failed to mark local orders as sent: $e');
    }
  }

  /// This service now uses per-call HTTP clients; no global client to dispose.
  void dispose() {}
}
