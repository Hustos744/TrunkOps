import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:trunk_ops_app/models/asset.dart';
import 'package:trunk_ops_app/models/unit.dart';
import 'package:trunk_ops_app/services/asset_local_repository.dart';
import 'package:trunk_ops_app/services/unit_local_repository.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  final AssetLocalRepository _repo = AssetLocalRepository();
  final UnitLocalRepository _unitRepo = UnitLocalRepository();

  bool _isLoading = true;
  List<Asset> _allAssets = [];

  // Підрозділи з UnitsPage
  List<Unit> _units = [];
  bool _isUnitsLoading = true;

  // Фільтри / пошук
  String _searchQuery = '';
  String _typeFilter = 'Усі типи';
  String _statusFilter = 'Усі статуси';
  String _unitFilter = 'Усі підрозділи';

  // Для поля пошуку — стабільний контролер
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _loadAssets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);

    final assets = await _repo.getAll();

    setState(() {
      _allAssets = assets;
      _isLoading = false;
    });
  }

  Future<void> _loadUnits() async {
    final units = await _unitRepo.getAll();
    setState(() {
      _units = units;
      _isUnitsLoading = false;
    });
  }

  // Фільтровані засоби
  List<Asset> get _filteredAssets {
    return _allAssets.where((a) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final inSearch =
            a.invNumber.toLowerCase().contains(q) ||
            a.type.toLowerCase().contains(q) ||
            a.model.toLowerCase().contains(q) ||
            a.unit.toLowerCase().contains(q) ||
            a.location.toLowerCase().contains(q);
        if (!inSearch) return false;
      }

      if (_typeFilter != 'Усі типи' &&
          a.type.toLowerCase() != _typeFilter.toLowerCase()) {
        return false;
      }

      if (_statusFilter != 'Усі статуси' && a.status != _statusFilter) {
        return false;
      }

      if (_unitFilter != 'Усі підрозділи' &&
          a.unit.toLowerCase() != _unitFilter.toLowerCase()) {
        return false;
      }

      return true;
    }).toList();
  }

  // Метрики
  int get _totalAssets => _allAssets.length;
  int get _inServiceAssets =>
      _allAssets.where((a) => a.status == 'У строю').length;
  int get _maintenanceAssets =>
      _allAssets.where((a) => a.status == 'На ремонті').length;
  int get _reserveAssets =>
      _allAssets.where((a) => a.status == 'Резерв').length;

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.text = '';
      _typeFilter = 'Усі типи';
      _statusFilter = 'Усі статуси';
      _unitFilter = 'Усі підрозділи';
    });
  }

  // ───────────────── ІМПОРТ / ЕКСПОРТ В ТЕКСТОВИЙ ФАЙЛ ─────────────────

  Map<String, dynamic> _assetToMap(Asset a) {
    return {
      'id': a.id,
      'invNumber': a.invNumber,
      'type': a.type,
      'model': a.model,
      'unit': a.unit,
      'status': a.status,
      'location': a.location,
      'lastCheck': a.lastCheck,
      'txPowerW': a.txPowerW,
      'frequencyMHz': a.frequencyMHz,
      'antennaHeightM': a.antennaHeightM,
      'antennaGainDb': a.antennaGainDb,
    };
  }

  Asset _assetFromMap(Map<String, dynamic> m) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String && v.trim().isNotEmpty) {
        return double.tryParse(v.trim());
      }
      return null;
    }

    return Asset(
      id: (m['id'] ?? 0) as int,
      invNumber: (m['invNumber'] ?? '') as String,
      type: (m['type'] ?? 'Невизначено') as String,
      model: (m['model'] ?? 'Невизначено') as String,
      unit: (m['unit'] ?? 'Невизначено') as String,
      status: (m['status'] ?? 'У строю') as String,
      location: (m['location'] ?? 'Невизначено') as String,
      lastCheck: (m['lastCheck'] ?? '-') as String,
      txPowerW: toDouble(m['txPowerW']),
      frequencyMHz: toDouble(m['frequencyMHz']),
      antennaHeightM: toDouble(m['antennaHeightM']),
      antennaGainDb: toDouble(m['antennaGainDb']),
    );
  }

  Future<void> _exportAssets() async {
    if (_allAssets.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Немає даних для експорту')));
      return;
    }

    final list = _allAssets.map(_assetToMap).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(list);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));

    final now = DateTime.now();
    final ts = now
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-'); // щоб було без заборонених символів
    final fileName = 'trunk_ops_assets_$ts.txt';

    try {
      // Експорт прямо в папку Download на Android
      final downloadsDir = Directory('/storage/emulated/0/Download');

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Дані експортовано у файл:\nDownload/$fileName'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Помилка експорту: $e')));
      }
    }
  }

  Future<void> _importAssets() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // беремо будь-який, але перевіряємо розширення
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // користувач скасував
      }

      final file = result.files.first;
      final ext = (file.extension ?? '').toLowerCase();

      if (ext != 'txt' && ext != 'json') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Оберіть текстовий файл з розширенням .txt або .json',
            ),
          ),
        );
        return;
      }

      final fileBytes = file.bytes;
      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не вдалося прочитати файл (bytes == null)'),
          ),
        );
        return;
      }

      final raw = utf8.decode(fileBytes);
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Некоректний формат: очікується JSON-масив'),
          ),
        );
        return;
      }

      final list = <Asset>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          list.add(_assetFromMap(item));
        } else if (item is Map) {
          list.add(
            _assetFromMap(item.map((k, v) => MapEntry(k.toString(), v))),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Один з елементів масиву має некоректний формат'),
            ),
          );
          return;
        }
      }

      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл не містить жодного запису')),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Підтвердження імпорту'),
          content: Text(
            'Буде імпортовано ${list.length} запис(ів) із файлу '
            '"${file.name}". Поточні дані будуть замінені. Продовжити?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Імпортувати'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Перезаписуємо локальне сховище
      for (final a in _allAssets) {
        await _repo.delete(a.id);
      }
      for (final a in list) {
        await _repo.create(a);
      }
      await _loadAssets();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Дані успішно імпортовано з файлу')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Помилка імпорту: $e')));
      }
    }
  }

  Future<void> _showAssetDialog({Asset? asset}) async {
    final isEdit = asset != null;

    final invController = TextEditingController(text: asset?.invNumber ?? '');
    final typeController = TextEditingController(text: asset?.type ?? '');
    final modelController = TextEditingController(text: asset?.model ?? '');
    final txPowerController = TextEditingController(
      text: asset?.txPowerW?.toString() ?? '',
    );
    final freqController = TextEditingController(
      text: asset?.frequencyMHz?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: asset?.antennaHeightM?.toString() ?? '',
    );
    final gainController = TextEditingController(
      text: asset?.antennaGainDb?.toString() ?? '',
    );
    final locationController = TextEditingController(
      text: asset?.location ?? '',
    );
    final lastCheckController = TextEditingController(
      text: asset?.lastCheck ?? '',
    );

    String status = asset?.status ?? 'У строю';

    // УНІКАЛЬНИЙ список назв підрозділів + "Резерв"
    final Set<String> unitNamesSet = {'Резерв', ..._units.map((u) => u.name)};
    final List<String> allUnitNames = unitNamesSet.toList();

    // Початково вибраний підрозділ
    String? selectedUnitName;
    if (asset != null && allUnitNames.contains(asset.unit)) {
      selectedUnitName = asset.unit;
    } else {
      selectedUnitName = 'Резерв';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            final theme = Theme.of(ctx);
            final scheme = theme.colorScheme;
            final extra = theme.extension<AppExtraColors>();
            final screenWidth = MediaQuery.of(ctx).size.width;

            final scale = (screenWidth / 1200).clamp(0.8, 1.2);

            return AlertDialog(
              backgroundColor: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: 24 * scale,
                vertical: 16 * scale,
              ),
              title: Text(
                isEdit ? 'Редагувати засіб' : 'Новий засіб',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize:
                      (theme.textTheme.titleLarge?.fontSize ?? 20) * scale,
                ),
              ),
              content: SizedBox(
                width: math.min(MediaQuery.of(ctx).size.width * 0.9, 500),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: invController,
                        decoration: const InputDecoration(
                          labelText: 'Інвентарний номер',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: typeController,
                        decoration: const InputDecoration(
                          labelText: 'Тип засобу',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: modelController,
                        decoration: const InputDecoration(labelText: 'Модель'),
                      ),
                      const SizedBox(height: 8),

                      // ───────── Підрозділ із UnitsPage + "Резерв" ─────────
                      if (_isUnitsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: LinearProgressIndicator(),
                        )
                      else
                        DropdownButtonFormField<String>(
                          // гарантуємо, що value є серед allUnitNames
                          value: allUnitNames.contains(selectedUnitName)
                              ? selectedUnitName
                              : 'Резерв',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Підрозділ',
                          ),
                          items: allUnitNames
                              .map(
                                (name) => DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setStateDialog(() {
                              selectedUnitName = v;
                            });
                          },
                        ),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        value: status,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Статус'),
                        items: const [
                          DropdownMenuItem(
                            value: 'У строю',
                            child: Text('У строю'),
                          ),
                          DropdownMenuItem(
                            value: 'На ремонті',
                            child: Text('На ремонті'),
                          ),
                          DropdownMenuItem(
                            value: 'Резерв',
                            child: Text('Резерв'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setStateDialog(() {
                              status = v;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Радіопараметри (для зон покриття)',
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: txPowerController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Потужність передавача, Вт',
                          hintText: 'Напр. 25',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: freqController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Робоча частота, МГц',
                          hintText: 'Напр. 450',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Висота антени, м',
                          hintText: 'Напр. 30',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: gainController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Підсилення антени, дБ',
                          hintText: 'Напр. 6',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Місцезнаходження',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: lastCheckController,
                        decoration: const InputDecoration(
                          labelText: 'Остання перевірка (дата)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 8 * scale,
              ),
              actionsAlignment: MainAxisAlignment.end,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Скасувати'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: extra?.accent ?? scheme.primary,
                  ),
                  onPressed: () async {
                    final inv = invController.text.trim();
                    if (inv.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Інвентарний номер обовʼязковий'),
                        ),
                      );
                      return;
                    }

                    double? parseDouble(String s) =>
                        s.trim().isEmpty ? null : double.tryParse(s.trim());

                    final newAsset = Asset(
                      id: asset?.id ?? 0,
                      invNumber: inv,
                      type: typeController.text.trim().isEmpty
                          ? 'Невизначено'
                          : typeController.text.trim(),
                      model: modelController.text.trim().isEmpty
                          ? 'Невизначено'
                          : modelController.text.trim(),
                      unit:
                          (allUnitNames.contains(selectedUnitName)
                              ? selectedUnitName
                              : 'Резерв') ??
                          'Резерв',
                      status: status,
                      location: locationController.text.trim().isEmpty
                          ? 'Невизначено'
                          : locationController.text.trim(),
                      lastCheck: lastCheckController.text.trim().isEmpty
                          ? '-'
                          : lastCheckController.text.trim(),
                      txPowerW: parseDouble(txPowerController.text),
                      frequencyMHz: parseDouble(freqController.text),
                      antennaHeightM: parseDouble(heightController.text),
                      antennaGainDb: parseDouble(gainController.text),
                    );

                    if (isEdit) {
                      await _repo.update(newAsset);
                    } else {
                      await _repo.create(newAsset);
                    }

                    await _loadAssets();
                    if (context.mounted) {
                      Navigator.of(ctx).pop(true);
                    }
                  },
                  child: Text(isEdit ? 'Зберегти' : 'Створити'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      // вже перезавантажили
    }
  }

  Future<void> _confirmDelete(Asset asset) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Видалити засіб'),
          content: Text(
            'Ви впевнені, що хочете видалити "${asset.invNumber}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Скасувати'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Видалити'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _repo.delete(asset.id);
      await _loadAssets();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // Плавний scale для текстів / елементів
        final scale = (maxWidth / 1200).clamp(0.8, 1.2);
        final titleFontSize = 24.0 * scale;
        final subtitleFontSize = 13.0 * scale;

        // Динамічна кількість карток у рядку
        const spacing = 16.0;
        final minCardWidth = maxWidth * 0.22; // ~4 картки на широкий екран
        final cardsPerRowRaw = (maxWidth / (minCardWidth + spacing)).floor();
        final cardsPerRow = cardsPerRowRaw.clamp(1, 4);
        final cardWidth =
            (maxWidth - spacing * (cardsPerRow - 1)) / cardsPerRow;

        // На великих екранах — таблиця, на маленьких — список карток
        final bool useDesktopTable = maxWidth >= 900;

        return Scrollbar(
          thumbVisibility: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ───────── Заголовок + кнопки ─────────
                  LayoutBuilder(
                    builder: (context, headerConstraints) {
                      final headerWidth = headerConstraints.maxWidth;
                      final isNarrowHeader = headerWidth < 700;

                      final titleBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Облік засобів',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Облік, стан та розподіл засобів транкінгового звʼязку по підрозділах',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: subtitleFontSize,
                              color:
                                  theme.textTheme.bodySmall?.color ??
                                  scheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      );

                      final actions = Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: isNarrowHeader
                            ? WrapAlignment.start
                            : WrapAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _importAssets,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color:
                                    extra?.borderDefault ??
                                    scheme.outline.withOpacity(0.6),
                              ),
                              foregroundColor: scheme.onSurface,
                              backgroundColor:
                                  extra?.surfaceSubtle ?? scheme.surface,
                            ),
                            icon: const Icon(
                              Icons.file_upload_outlined,
                              size: 18,
                            ),
                            label: const Text(
                              'Імпорт',
                              style: TextStyle(fontFamily: 'Inter'),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _exportAssets,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color:
                                    extra?.borderDefault ??
                                    scheme.outline.withOpacity(0.6),
                              ),
                              foregroundColor: scheme.onSurface,
                              backgroundColor:
                                  extra?.surfaceSubtle ?? scheme.surface,
                            ),
                            icon: const Icon(
                              Icons.file_download_outlined,
                              size: 18,
                            ),
                            label: const Text(
                              'Експорт',
                              style: TextStyle(fontFamily: 'Inter'),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _showAssetDialog(),
                            style: FilledButton.styleFrom(
                              backgroundColor: extra?.accent ?? scheme.primary,
                              foregroundColor: scheme.onPrimary,
                            ),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text(
                              'Додати засіб',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );

                      if (isNarrowHeader) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleBlock,
                            const SizedBox(height: 12),
                            actions,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: titleBlock),
                          const SizedBox(width: 16),
                          actions,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ───────── Метрики ─────────
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _MetricCard(
                          title: 'Усього засобів',
                          value: '$_totalAssets',
                          trendLabel: 'Локально збережені',
                          trendPositive: true,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _MetricCard(
                          title: 'У строю',
                          value: '$_inServiceAssets',
                          trendLabel: 'Стан "У строю"',
                          trendPositive: true,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _MetricCard(
                          title: 'На ремонті',
                          value: '$_maintenanceAssets',
                          trendLabel: 'Потребують уваги',
                          trendPositive: false,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _MetricCard(
                          title: 'Резерв / склад',
                          value: '$_reserveAssets',
                          trendLabel: 'Статус "Резерв"',
                          trendPositive: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ───────── Фільтри ─────────
                  _AssetsFiltersBar(
                    searchController: _searchController,
                    onSearchChanged: (v) {
                      setState(() => _searchQuery = v);
                    },
                    typeFilter: _typeFilter,
                    statusFilter: _statusFilter,
                    unitFilter: _unitFilter,
                    availableTypes: [
                      'Усі типи',
                      ...{for (final a in _allAssets) a.type},
                    ],
                    availableUnits: [
                      'Усі підрозділи',
                      ...{for (final a in _allAssets) a.unit},
                    ],
                    onTypeChanged: (v) =>
                        setState(() => _typeFilter = v ?? 'Усі типи'),
                    onStatusChanged: (v) =>
                        setState(() => _statusFilter = v ?? 'Усі статуси'),
                    onUnitChanged: (v) =>
                        setState(() => _unitFilter = v ?? 'Усі підрозділи'),
                    onResetFilters: _resetFilters,
                  ),

                  const SizedBox(height: 16),

                  // ───────── Реєстр ─────────
                  Container(
                    decoration: BoxDecoration(
                      color: extra?.surfaceElevated ?? scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            extra?.borderDefault ??
                            scheme.outline.withOpacity(0.6),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: extra?.surfaceSubtle ?? scheme.surface,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    extra?.borderDefault ??
                                    scheme.outline.withOpacity(0.6),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Реєстр засобів',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _loadAssets,
                                icon: Icon(
                                  Icons.refresh,
                                  size: 20,
                                  color:
                                      theme.textTheme.bodySmall?.color ??
                                      scheme.onSurface.withOpacity(0.8),
                                ),
                                tooltip: 'Оновити',
                              ),
                            ],
                          ),
                        ),

                        if (_filteredAssets.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'Засоби відсутні. Додайте перший засіб.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        else if (useDesktopTable)
                          _DesktopAssetsTable(
                            assets: _filteredAssets,
                            onEdit: (a) => _showAssetDialog(asset: a),
                            onDelete: _confirmDelete,
                          )
                        else
                          _MobileAssetsList(
                            assets: _filteredAssets,
                            onEdit: (a) => _showAssetDialog(asset: a),
                            onDelete: _confirmDelete,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

//
// ───────────────── КАРТКИ-МЕТРИКИ ─────────────────
//

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String trendLabel;
  final bool trendPositive;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.trendLabel,
    required this.trendPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();
    final screenWidth = MediaQuery.of(context).size.width;

    final scale = (screenWidth / 1200).clamp(0.8, 1.2);
    final valueFontSize = 22.0 * scale;
    final titleFontSize = 13.0 * scale;

    final Color trendColor = trendPositive
        ? (extra?.success ?? scheme.primary)
        : scheme.error;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: extra?.surfaceElevated ?? scheme.surface,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: extra?.borderDefault ?? scheme.outline.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Inter',
              fontSize: titleFontSize,
              color:
                  theme.textTheme.bodySmall?.color ??
                  scheme.onSurface.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFamily: 'Inter',
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 4 * scale),
          Row(
            children: [
              Icon(
                trendPositive ? Icons.trending_up : Icons.trending_down,
                size: 16 * scale,
                color: trendColor,
              ),
              SizedBox(width: 4 * scale),
              Flexible(
                child: Text(
                  trendLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Inter',
                    color: trendColor,
                    fontSize:
                        (theme.textTheme.bodySmall?.fontSize ?? 11) * scale,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//
// ───────────────── ПАНЕЛЬ ФІЛЬТРІВ ─────────────────
//

class _AssetsFiltersBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  final String typeFilter;
  final String statusFilter;
  final String unitFilter;

  final List<String> availableTypes;
  final List<String> availableUnits;

  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onUnitChanged;
  final VoidCallback onResetFilters;

  const _AssetsFiltersBar({
    required this.searchController,
    required this.onSearchChanged,
    required this.typeFilter,
    required this.statusFilter,
    required this.unitFilter,
    required this.availableTypes,
    required this.availableUnits,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onUnitChanged,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final bool isVeryNarrow = maxWidth < 700;
        final bool isNarrowRow = maxWidth < 1100;

        final searchField = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
          ).copyWith(color: scheme.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color:
                  theme.textTheme.bodySmall?.color ??
                  scheme.onSurface.withOpacity(0.7),
            ),
            hintText: 'Пошук за інв. номером, моделлю або підрозділом',
            hintStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color:
                  theme.textTheme.bodySmall?.color ??
                  scheme.onSurface.withOpacity(0.6),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: extra?.surfaceSubtle ?? scheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: extra?.borderDefault ?? scheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: extra?.borderDefault ?? scheme.outline.withOpacity(0.5),
              ),
            ),
          ),
        );

        final typeDropdown = DropdownButtonFormField<String>(
          initialValue: typeFilter,
          isExpanded: true,
          decoration: _dropdownDecoration(context, label: 'Тип засобу'),
          items: availableTypes
              .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
              .toList(),
          onChanged: onTypeChanged,
        );

        final statusDropdown = DropdownButtonFormField<String>(
          initialValue: statusFilter,
          isExpanded: true,
          decoration: _dropdownDecoration(context, label: 'Статус'),
          items: const ['Усі статуси', 'У строю', 'На ремонті', 'Резерв']
              .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
              .toList(),
          onChanged: onStatusChanged,
        );

        final unitDropdown = DropdownButtonFormField<String>(
          initialValue: unitFilter,
          isExpanded: true,
          decoration: _dropdownDecoration(context, label: 'Підрозділ'),
          items: availableUnits
              .map((u) => DropdownMenuItem<String>(value: u, child: Text(u)))
              .toList(),
          onChanged: onUnitChanged,
        );

        final resetFull = TextButton.icon(
          onPressed: onResetFilters,
          icon: const Icon(Icons.filter_alt_off, size: 18),
          label: const Text(
            'Скинути фільтри',
            style: TextStyle(fontFamily: 'Inter'),
          ),
        );

        final resetShort = TextButton.icon(
          onPressed: onResetFilters,
          icon: const Icon(Icons.filter_alt_off, size: 18),
          label: const Text('Скинути', style: TextStyle(fontFamily: 'Inter')),
        );

        if (isVeryNarrow) {
          // Все в колонку
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchField,
              const SizedBox(height: 8),
              typeDropdown,
              const SizedBox(height: 8),
              statusDropdown,
              const SizedBox(height: 8),
              unitDropdown,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: resetFull),
            ],
          );
        }

        if (isNarrowRow) {
          // Пошук окремо, фільтри в 2 рядки, кнопка скидання окремим рядком
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchField,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: typeDropdown),
                  const SizedBox(width: 12),
                  Expanded(child: statusDropdown),
                ],
              ),
              const SizedBox(height: 8),
              unitDropdown,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: resetFull),
            ],
          );
        }

        // Широкий екран — все в один ряд
        final row = Row(
          children: [
            Flexible(flex: 3, child: searchField),
            const SizedBox(width: 12),
            Flexible(flex: 2, child: typeDropdown),
            const SizedBox(width: 12),
            Flexible(flex: 2, child: statusDropdown),
            const SizedBox(width: 12),
            Flexible(flex: 2, child: unitDropdown),
          ],
        );

        return Row(
          children: [
            Expanded(child: row),
            const SizedBox(width: 12),
            resetShort,
          ],
        );
      },
    );
  }

  InputDecoration _dropdownDecoration(
    BuildContext context, {
    required String label,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color:
            theme.textTheme.bodySmall?.color ??
            scheme.onSurface.withOpacity(0.7),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: extra?.surfaceSubtle ?? scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: extra?.borderDefault ?? scheme.outline.withOpacity(0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: extra?.borderDefault ?? scheme.outline.withOpacity(0.5),
        ),
      ),
    );
  }
}

//
// ───────────────── ДЕСКТОПНА ТАБЛИЦЯ ─────────────────
//

class _DesktopAssetsTable extends StatelessWidget {
  final List<Asset> assets;
  final ValueChanged<Asset> onEdit;
  final ValueChanged<Asset> onDelete;

  const _DesktopAssetsTable({
    required this.assets,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extra = Theme.of(context).extension<AppExtraColors>();

    final dividerColor =
        extra?.borderDefault ?? scheme.outline.withOpacity(0.7);

    const minTableWidth = 1100.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(constraints.maxWidth, minTableWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minTableWidth,
              maxWidth: tableWidth,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    color: extra?.surfaceSubtle ?? scheme.surface,
                  ),
                  child: Row(
                    children: const [
                      _AssetsHeaderCell(flex: 2, label: 'Інв. №'),
                      _AssetsHeaderCell(flex: 2, label: 'Тип засобу'),
                      _AssetsHeaderCell(flex: 2, label: 'Модель'),
                      _AssetsHeaderCell(flex: 2, label: 'Підрозділ'),
                      _AssetsHeaderCell(flex: 2, label: 'Статус'),
                      _AssetsHeaderCell(flex: 2, label: 'Місцезнаходження'),
                      _AssetsHeaderCell(flex: 2, label: 'Остання перевірка'),
                      _AssetsHeaderCell(flex: 2, label: 'Дії'),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: dividerColor),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assets.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, thickness: 1, color: dividerColor),
                  itemBuilder: (context, index) {
                    final a = assets[index];
                    return _DesktopAssetRow(
                      asset: a,
                      onEdit: () => onEdit(a),
                      onDelete: () => onDelete(a),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AssetsHeaderCell extends StatelessWidget {
  final int flex;
  final String label;

  const _AssetsHeaderCell({required this.flex, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final color =
        textTheme.bodySmall?.color ?? scheme.onSurface.withOpacity(0.7);

    return Expanded(
      flex: flex,
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _DesktopAssetRow extends StatelessWidget {
  final Asset asset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DesktopAssetRow({
    required this.asset,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    switch (asset.status) {
      case 'У строю':
        return extra?.success ?? scheme.primary;
      case 'На ремонті':
        return scheme.error;
      case 'Резерв':
        return extra?.warning ?? const Color(0xFFFFC107);
      default:
        return theme.textTheme.bodySmall?.color ??
            scheme.onSurface.withOpacity(0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    final statusColor = _statusColor(context);
    final secondary =
        textTheme.bodySmall?.color ?? scheme.onSurface.withOpacity(0.7);

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                asset.invNumber,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                asset.type,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: secondary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                asset.model,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: secondary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                asset.unit,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: secondary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      asset.status,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: secondary,
                    ),
                  ),
                  if (asset.txPowerW != null || asset.frequencyMHz != null)
                    Text(
                      'P=${asset.txPowerW ?? '-'} Вт, f=${asset.frequencyMHz ?? '-'} МГц',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: secondary.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                asset.lastCheck,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: secondary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Редагувати',
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      tooltip: 'Видалити',
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ───────────────── МОБІЛЬНИЙ СПИСОК (КАРТКИ) ─────────────────
//

class _MobileAssetsList extends StatelessWidget {
  final List<Asset> assets;
  final ValueChanged<Asset> onEdit;
  final ValueChanged<Asset> onDelete;

  const _MobileAssetsList({
    required this.assets,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: assets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final a = assets[index];
        return _MobileAssetCard(
          asset: a,
          onEdit: () => onEdit(a),
          onDelete: () => onDelete(a),
        );
      },
    );
  }
}

class _MobileAssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MobileAssetCard({
    required this.asset,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    switch (asset.status) {
      case 'У строю':
        return extra?.success ?? scheme.primary;
      case 'На ремонті':
        return scheme.error;
      case 'Резерв':
        return extra?.warning ?? const Color(0xFFFFC107);
      default:
        return theme.textTheme.bodySmall?.color ??
            scheme.onSurface.withOpacity(0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();
    final textTheme = theme.textTheme;

    final statusColor = _statusColor(context);

    return Container(
      decoration: BoxDecoration(
        color: extra?.surfaceElevated ?? scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: extra?.borderDefault ?? scheme.outline.withOpacity(0.5),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Верхній рядок: Інв. № + статус
          Row(
            children: [
              Expanded(
                child: Text(
                  asset.invNumber,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      asset.status,
                      style: textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            '${asset.type} • ${asset.model}',
            style: textTheme.bodyMedium?.copyWith(
              color:
                  textTheme.bodySmall?.color ??
                  scheme.onSurface.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Підрозділ: ${asset.unit}',
            style: textTheme.bodySmall?.copyWith(
              color:
                  textTheme.bodySmall?.color ??
                  scheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            'Місцезнаходження: ${asset.location}',
            style: textTheme.bodySmall?.copyWith(
              color:
                  textTheme.bodySmall?.color ??
                  scheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            'Остання перевірка: ${asset.lastCheck}',
            style: textTheme.bodySmall?.copyWith(
              color:
                  textTheme.bodySmall?.color ??
                  scheme.onSurface.withOpacity(0.7),
            ),
          ),

          if (asset.txPowerW != null ||
              asset.frequencyMHz != null ||
              asset.antennaHeightM != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'P=${asset.txPowerW ?? '-'} Вт, f=${asset.frequencyMHz ?? '-'} МГц, h=${asset.antennaHeightM ?? '-'} м',
                style: textTheme.bodySmall?.copyWith(
                  color:
                      textTheme.bodySmall?.color ??
                      scheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Редагувати'),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Видалити'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
