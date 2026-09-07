import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Local-only persistence. No network, no accounts, no API keys.
abstract class ZineStore {
  Future<List<ZineSummary>> list();
  Future<Zine> load(String id);
  Future<void> save(Zine zine, {Uint8List? thumbnail});
  Future<void> delete(String id);
  Future<Uint8List?> thumbnail(String id);
  Future<void> rename(String id, String title);

  /// In-memory store for tests.
  factory ZineStore.memory() = MemoryZineStore;

  static Future<ZineStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsZineStore(prefs);
  }
}

class MemoryZineStore implements ZineStore {
  MemoryZineStore();

  final Map<String, Zine> _zines = {};
  final Map<String, Uint8List> _thumbs = {};

  @override
  Future<List<ZineSummary>> list() async {
    final items = _zines.values.map(ZineSummary.fromZine).toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<Zine> load(String id) async {
    final zine = _zines[id];
    if (zine == null) {
      throw StateError('Zine $id not found');
    }
    return zine.copy();
  }

  @override
  Future<void> save(Zine zine, {Uint8List? thumbnail}) async {
    zine.updatedAt = DateTime.now();
    _zines[zine.id] = zine.copy();
    if (thumbnail != null) {
      _thumbs[zine.id] = Uint8List.fromList(thumbnail);
    }
  }

  @override
  Future<void> delete(String id) async {
    _zines.remove(id);
    _thumbs.remove(id);
  }

  @override
  Future<Uint8List?> thumbnail(String id) async => _thumbs[id];

  @override
  Future<void> rename(String id, String title) async {
    final zine = _zines[id];
    if (zine == null) return;
    zine.title = title;
    zine.updatedAt = DateTime.now();
  }
}

/// Device-local JSON via SharedPreferences (NSUserDefaults / Android
/// prefs / browser localStorage). Strokes stay as point data.
class PrefsZineStore implements ZineStore {
  PrefsZineStore(this._prefs);

  final SharedPreferences _prefs;
  static const _indexKey = 'petal_press_index';

  String _zineKey(String id) => 'petal_press_zine_$id';
  String _thumbKey(String id) => 'petal_press_thumb_$id';

  List<ZineSummary> _readIndex() {
    final raw = _prefs.getString(_indexKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ZineSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeIndex(List<ZineSummary> items) async {
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _prefs.setString(
      _indexKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<List<ZineSummary>> list() async => _readIndex();

  @override
  Future<Zine> load(String id) async {
    final raw = _prefs.getString(_zineKey(id));
    if (raw == null) {
      throw StateError('Zine $id not found');
    }
    return Zine.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(Zine zine, {Uint8List? thumbnail}) async {
    zine.updatedAt = DateTime.now();
    await _prefs.setString(_zineKey(zine.id), jsonEncode(zine.toJson()));
    if (thumbnail != null) {
      await _prefs.setString(_thumbKey(zine.id), base64Encode(thumbnail));
    }
    final index = _readIndex();
    index.removeWhere((s) => s.id == zine.id);
    index.add(ZineSummary.fromZine(zine));
    await _writeIndex(index);
  }

  @override
  Future<void> delete(String id) async {
    await _prefs.remove(_zineKey(id));
    await _prefs.remove(_thumbKey(id));
    final index = _readIndex()..removeWhere((s) => s.id == id);
    await _writeIndex(index);
  }

  @override
  Future<Uint8List?> thumbnail(String id) async {
    final raw = _prefs.getString(_thumbKey(id));
    if (raw == null) return null;
    return Uint8List.fromList(base64Decode(raw));
  }

  @override
  Future<void> rename(String id, String title) async {
    final zine = await load(id);
    zine.title = title;
    await save(zine);
  }
}
