import 'dart:math';

import '../models/asset.dart';
import 'local_storage_service.dart';

class AssetLocalRepository {
  static const String _storageKey = 'local_assets';

  final LocalStorageService _storage;

  AssetLocalRepository({LocalStorageService? storage})
    : _storage = storage ?? LocalStorageService();

  /// Отримати всі засоби.
  Future<List<Asset>> getAll() async {
    final jsonList = await _storage.loadJsonList(_storageKey);
    return jsonList.map((e) => Asset.fromJson(e)).toList();
  }

  Future<void> _saveAll(List<Asset> assets) async {
    final jsonList = assets.map((a) => a.toJson()).toList();
    await _storage.saveJsonList(_storageKey, jsonList);
  }

  /// Додати новий засіб (ID генерується локально).
  Future<Asset> create(Asset asset) async {
    final assets = await getAll();
    final currentMaxId = assets.isEmpty
        ? 0
        : assets.map((a) => a.id).reduce(max);

    final newAsset = asset.copyWith(id: currentMaxId + 1);

    assets.add(newAsset);
    await _saveAll(assets);
    return newAsset;
  }

  /// Оновити існуючий засіб.
  Future<Asset> update(Asset asset) async {
    final assets = await getAll();
    final index = assets.indexWhere((a) => a.id == asset.id);
    if (index == -1) {
      throw Exception('Asset with id=${asset.id} not found');
    }

    assets[index] = asset;
    await _saveAll(assets);
    return asset;
  }

  /// Видалити засіб за ID.
  Future<void> delete(int id) async {
    final assets = await getAll();
    assets.removeWhere((a) => a.id == id);
    await _saveAll(assets);
  }

  /// Очистити локальні засоби (опційно).
  Future<void> clear() async {
    await _storage.clearKey(_storageKey);
  }
}
