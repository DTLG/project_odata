import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'inventory_local_data_source.dart';
import '../models/inventory_document_model.dart';
import '../models/inventory_item_model.dart';

/// Implementation of local data source for inventory
class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  static const String _documentsKey = 'cached_inventory_documents';
  static const String _itemsKeyPrefix = 'cached_inventory_items_';

  @override
  Future<void> cacheDocuments(List<InventoryDocumentModel> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final documentsJson = documents.map((doc) => doc.toJson()).toList();
    await prefs.setString(_documentsKey, jsonEncode(documentsJson));
  }

  @override
  Future<List<InventoryDocumentModel>> getCachedDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final documentsJsonString = prefs.getString(_documentsKey);

    if (documentsJsonString == null) {
      return [];
    }

    final documentsJson = jsonDecode(documentsJsonString) as List;
    return documentsJson
        .map((json) => InventoryDocumentModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> cacheDocumentItems(
    String documentId,
    List<InventoryItemModel> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = items.map((item) => item.toJson()).toList();
    await prefs.setString('$_itemsKeyPrefix$documentId', jsonEncode(itemsJson));
  }

  @override
  Future<List<InventoryItemModel>> getCachedDocumentItems(
    String documentId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJsonString = prefs.getString('$_itemsKeyPrefix$documentId');

    if (itemsJsonString == null) {
      return [];
    }

    final itemsJson = jsonDecode(itemsJsonString) as List;
    return itemsJson.map((json) => InventoryItemModel.fromJson(json)).toList();
  }

  @override
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_documentsKey);

    // Clear all cached items
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_itemsKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
