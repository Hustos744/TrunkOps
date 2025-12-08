import 'dart:math';

import '../models/unit.dart';
import 'local_storage_service.dart';

class UnitLocalRepository {
  static const String _storageKey = 'local_units';

  final LocalStorageService _storage;

  UnitLocalRepository({LocalStorageService? storage})
    : _storage = storage ?? LocalStorageService();

  /// Отримати всі підрозділи.
  Future<List<Unit>> getAll() async {
    final jsonList = await _storage.loadJsonList(_storageKey);
    return jsonList.map((e) => Unit.fromJson(e)).toList();
  }

  Future<void> _saveAll(List<Unit> units) async {
    final jsonList = units.map((u) => u.toJson()).toList();
    await _storage.saveJsonList(_storageKey, jsonList);
  }

  /// Додати новий підрозділ (ID генерується локально).
  Future<Unit> create(Unit unit) async {
    final units = await getAll();
    final currentMaxId = units.isEmpty ? 0 : units.map((u) => u.id).reduce(max);

    final newUnit = Unit(
      id: currentMaxId + 1,
      name: unit.name,
      type: unit.type,
      area: unit.area,
      status: unit.status,
      statusLabel: unit.statusLabel,
      activity: unit.activity,
    );

    units.add(newUnit);
    await _saveAll(units);
    return newUnit;
  }

  /// Оновити існуючий підрозділ.
  Future<Unit> update(Unit unit) async {
    final units = await getAll();
    final index = units.indexWhere((u) => u.id == unit.id);
    if (index == -1) {
      throw Exception('Unit with id=${unit.id} not found');
    }

    units[index] = unit;
    await _saveAll(units);
    return unit;
  }

  /// Видалити підрозділ за ID.
  Future<void> delete(int id) async {
    final units = await getAll();
    units.removeWhere((u) => u.id == id);
    await _saveAll(units);
  }

  /// Очистити всі локальні підрозділи (опційно, наприклад, при logout).
  Future<void> clear() async {
    await _storage.clearKey(_storageKey);
  }
}
