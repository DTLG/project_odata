import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/customer_order_model.dart';

abstract class OrdersLocalDataSource {
  Future<void> saveOrder(CustomerOrderModel order);
  Future<List<CustomerOrderModel>> getOrders();
  Future<void> deleteOrder(String id);
  Future<void> clear();
}

class OrdersLocalDataSourceImpl implements OrdersLocalDataSource {
  static Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'customer_orders.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS orders (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL
          )
        ''');
        // Add migration to include is_sent flag inside JSON payload; no schema change needed
      },
    );
    return _db!;
  }

  @override
  Future<void> saveOrder(CustomerOrderModel order) async {
    final db = await _database;
    await db.insert('orders', {
      'id': order.id,
      'data': order.toJsonString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<CustomerOrderModel>> getOrders() async {
    final db = await _database;
    final rows = await db.query('orders', orderBy: 'id DESC');
    return rows
        .map((r) => CustomerOrderModel.fromJsonString(r['data'] as String))
        .toList();
  }

  @override
  Future<void> deleteOrder(String id) async {
    final db = await _database;
    await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clear() async {
    final db = await _database;
    await db.delete('orders');
  }
}
