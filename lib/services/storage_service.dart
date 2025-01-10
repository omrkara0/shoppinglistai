import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoppinglistai/models/urun.dart';

class StorageService {
  static const String _storageKey = 'shopping_list';
  late final SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<Urun>> loadItems() async {
    final String? savedItems = _prefs.getString(_storageKey);
    if (savedItems != null) {
      final List<dynamic> decodedItems = jsonDecode(savedItems);
      return decodedItems.map((item) => Urun.fromMap(item)).toList();
    }
    return [];
  }

  Future<void> saveItems(List<Urun> items) async {
    final String encodedItems =
        jsonEncode(items.map((e) => e.toMap()).toList());
    await _prefs.setString(_storageKey, encodedItems);
  }
}
