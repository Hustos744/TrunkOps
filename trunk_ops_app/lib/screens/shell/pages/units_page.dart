import 'package:flutter/material.dart';
import 'package:trunk_ops_app/models/unit.dart';
import 'package:trunk_ops_app/services/unit_local_repository.dart';
import 'package:trunk_ops_app/theme/app_colors.dart'; // AppExtraColors

class UnitsPage extends StatefulWidget {
  const UnitsPage({super.key});

  @override
  State<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends State<UnitsPage> {
  final UnitLocalRepository _repo = UnitLocalRepository();

  final TextEditingController _searchController = TextEditingController();

  List<Unit> _allUnits = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _typeFilter = 'Усі типи';
  String _statusFilter = 'Усі стани';
  String _areaFilter = 'Усі зони';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);
    final units = await _repo.getAll();

    setState(() {
      _allUnits = units;
      _isLoading = false;
    });
  }

  List<Unit> get _filteredUnits {
    return _allUnits.where((u) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        final inSearch =
            u.name.toLowerCase().contains(query) ||
            u.type.toLowerCase().contains(query) ||
            u.area.toLowerCase().contains(query) ||
            u.statusLabel.toLowerCase().contains(query);
        if (!inSearch) return false;
      }

      if (_typeFilter != 'Усі типи' &&
          u.type.toLowerCase() != _typeFilter.toLowerCase()) {
        return false;
      }

      if (_statusFilter != 'Усі стани') {
        switch (_statusFilter) {
          case 'Стабільний':
            if (u.status != 'OK') return false;
            break;
          case 'Попередження':
            if (u.status != 'Warning') return false;
            break;
          case 'Критичний':
            if (u.status != 'Critical') return false;
            break;
        }
      }

      if (_areaFilter != 'Усі зони' &&
          !u.area.toLowerCase().contains(_areaFilter.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();
  }

  int get _totalUnits => _allUnits.length;

  int get _activeUnits => _allUnits.where((u) => u.status == 'OK').length;

  int get _problemUnits => _allUnits
      .where((u) => u.status == 'Warning' || u.status == 'Critical')
      .length;

  int get _reserveUnits => _allUnits
      .where(
        (u) =>
            u.activity.toLowerCase().contains('резерв') ||
            u.activity.toLowerCase().contains('відключ'),
      )
      .length;

  Future<void> _showUnitDialog({Unit? unit}) async {
    final isEdit = unit != null;

    final nameController = TextEditingController(text: unit?.name ?? '');
    final typeController = TextEditingController(text: unit?.type ?? '');
    final areaController = TextEditingController(text: unit?.area ?? '');
    final statusLabelController = TextEditingController(
      text: unit?.statusLabel ?? '',
    );
    final activityController = TextEditingController(
      text: unit?.activity ?? '',
    );

    String status = unit?.status ?? 'OK';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final textTheme = theme.textTheme;
        final colorScheme = theme.colorScheme;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650, // 🔥 РОЗШИРЕНЕ ВІКНО
              minWidth: 500, // 🔥 МІНІМАЛЬНА ШИРИНА
              maxHeight: 700, // 🔥 Високе вікно + скрол
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? 'Редагувати підрозділ' : 'Новий підрозділ',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // дозволяємо прокрутку великої форми
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Назва підрозділу',
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: typeController,
                            decoration: const InputDecoration(
                              labelText: 'Тип (рота, штаб, вузол...)',
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: areaController,
                            decoration: const InputDecoration(
                              labelText: 'Район / зона',
                            ),
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: const InputDecoration(
                              labelText: 'Стан звʼязку',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'OK',
                                child: Text('OK (стабільний)'),
                              ),
                              DropdownMenuItem(
                                value: 'Warning',
                                child: Text('Warning (попередження)'),
                              ),
                              DropdownMenuItem(
                                value: 'Critical',
                                child: Text('Critical (критичний)'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) status = v;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: statusLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Опис стану (label)',
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: activityController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Активність (активна, резерв, проблемний...)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Скасувати'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Назва підрозділу обовʼязкова'),
                              ),
                            );
                            return;
                          }

                          final newUnit = Unit(
                            id: unit?.id ?? 0,
                            name: name,
                            type: typeController.text.trim().isEmpty
                                ? 'Невизначено'
                                : typeController.text.trim(),
                            area: areaController.text.trim().isEmpty
                                ? 'Невизначено'
                                : areaController.text.trim(),
                            status: status,
                            statusLabel:
                                statusLabelController.text.trim().isEmpty
                                ? 'Без опису'
                                : statusLabelController.text.trim(),
                            activity: activityController.text.trim().isEmpty
                                ? 'Активна'
                                : activityController.text.trim(),
                          );

                          if (isEdit) {
                            await _repo.update(newUnit);
                          } else {
                            await _repo.create(newUnit);
                          }

                          await _loadUnits();
                          if (context.mounted) Navigator.of(ctx).pop(true);
                        },
                        child: Text(isEdit ? 'Зберегти' : 'Створити'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == true) {
      // уже перезавантажили в діалозі
    }
  }

  Future<void> _confirmDelete(Unit unit) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Видалити підрозділ'),
          content: Text('Ви впевнені, що хочете видалити "${unit.name}"?'),
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
      await _repo.delete(unit.id);
      await _loadUnits();
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _typeFilter = 'Усі типи';
      _statusFilter = 'Усі стани';
      _areaFilter = 'Усі зони';
    });
  }

  Future<void> _pickTypeFilter() async {
    final options = <String>[
      'Усі типи',
      ...{for (final u in _allUnits) u.type},
    ].toList();

    final selected = await _showSimplePicker(
      title: 'Тип підрозділу',
      options: options,
      current: _typeFilter,
    );

    if (selected != null) {
      setState(() => _typeFilter = selected);
    }
  }

  Future<void> _pickStatusFilter() async {
    const options = <String>[
      'Усі стани',
      'Стабільний',
      'Попередження',
      'Критичний',
    ];

    final selected = await _showSimplePicker(
      title: 'Стан звʼязку',
      options: options,
      current: _statusFilter,
    );

    if (selected != null) {
      setState(() => _statusFilter = selected);
    }
  }

  Future<void> _pickAreaFilter() async {
    final options = <String>[
      'Усі зони',
      ...{for (final u in _allUnits) u.area},
    ].toList();

    final selected = await _showSimplePicker(
      title: 'Зона / район',
      options: options,
      current: _areaFilter,
    );

    if (selected != null) {
      setState(() => _areaFilter = selected);
    }
  }

  Future<String?> _showSimplePicker({
    required String title,
    required List<String> options,
    required String current,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(title, style: theme.textTheme.titleMedium)),
              const Divider(height: 1),
              ...options.map(
                (o) => RadioListTile<String>(
                  value: o,
                  groupValue: current,
                  onChanged: (v) => Navigator.of(ctx).pop(v),
                  title: Text(o),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const spacing = 16.0;

        int cardsPerRow;
        if (maxWidth >= 1500) {
          cardsPerRow = 4;
        } else if (maxWidth >= 1200) {
          cardsPerRow = 3;
        } else if (maxWidth >= 900) {
          cardsPerRow = 2;
        } else {
          cardsPerRow = 1;
        }

        final totalSpacing = spacing * (cardsPerRow + 1);
        final cardWidth =
            (maxWidth - totalSpacing).clamp(220.0, maxWidth) / cardsPerRow;

        final subtitleColor =
            textTheme.bodySmall?.color ??
            colorScheme.onSurface.withOpacity(0.7);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок сторінки + кнопка "додати"
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Підрозділи',
                            style: textTheme.headlineLarge?.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Структура підрозділів та їхній стан з точки зору забезпечення транкінговим звʼязком',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Align(
                      alignment: Alignment.topRight,
                      child: FilledButton.icon(
                        onPressed: () => _showUnitDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Додати підрозділ'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Верхні статистичні картки (на основі реальних даних)
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _UnitStatCard(
                        title: 'Загальна кількість підрозділів',
                        value: '$_totalUnits',
                        subtitle: 'по обраному ОТУ (локальні дані)',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _UnitStatCard(
                        title: 'Підрозділи з активним звʼязком',
                        value: '$_activeUnits',
                        subtitle: 'стан OK',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _UnitStatCard(
                        title: 'Проблемні підрозділи',
                        value: '$_problemUnits',
                        subtitle: 'Warning / Critical',
                        highlight: true,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _UnitStatCard(
                        title: 'У резерві / відключені',
                        value: '$_reserveUnits',
                        subtitle: 'за ознакою активності',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Панель фільтрів + пошук
                _UnitsFilterBar(
                  searchController: _searchController,
                  typeFilterLabel: _typeFilter,
                  statusFilterLabel: _statusFilter,
                  areaFilterLabel: _areaFilter,
                  onTypeFilterTap: _pickTypeFilter,
                  onStatusFilterTap: _pickStatusFilter,
                  onAreaFilterTap: _pickAreaFilter,
                  onReset: _resetFilters,
                ),

                const SizedBox(height: 20),

                // Таблиця / список підрозділів (адаптивно)
                _UnitsTable(
                  units: _filteredUnits,
                  onEdit: (u) => _showUnitDialog(unit: u),
                  onDelete: _confirmDelete,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ───────────────── КАРТКИ-СТАТИСТИКА ─────────────────

class _UnitStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool highlight;

  const _UnitStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final extra = theme.extension<AppExtraColors>();

    final borderColor = highlight
        ? (extra?.warning ?? colorScheme.secondary)
        : (extra?.borderDefault ?? colorScheme.outline.withOpacity(0.7));

    final valueColor = highlight
        ? (extra?.warning ?? colorScheme.secondary)
        : colorScheme.onSurface;

    final subtitleColor =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: highlight ? 1.3 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────── ПАНЕЛЬ ФІЛЬТРІВ ─────────────────

class _UnitsFilterBar extends StatelessWidget {
  final TextEditingController searchController;

  final String typeFilterLabel;
  final String statusFilterLabel;
  final String areaFilterLabel;

  final VoidCallback onTypeFilterTap;
  final VoidCallback onStatusFilterTap;
  final VoidCallback onAreaFilterTap;
  final VoidCallback onReset;

  const _UnitsFilterBar({
    required this.searchController,
    required this.typeFilterLabel,
    required this.statusFilterLabel,
    required this.areaFilterLabel,
    required this.onTypeFilterTap,
    required this.onStatusFilterTap,
    required this.onAreaFilterTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = theme.extension<AppExtraColors>();
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final resetColor = extra?.warning ?? colorScheme.secondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 800;

        final searchField = Expanded(
          child: TextField(
            controller: searchController,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Пошук підрозділу, позивного або індексу',
              hintStyle: textTheme.bodySmall?.copyWith(fontSize: 13),
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color:
                    textTheme.bodySmall?.color ??
                    colorScheme.onSurface.withOpacity(0.7),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: colorScheme.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color:
                      extra?.borderDefault ??
                      colorScheme.outline.withOpacity(0.7),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: extra?.success ?? colorScheme.primary,
                  width: 1.2,
                ),
              ),
            ),
          ),
        );

        final filters = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _FilterChipButton(
              label: 'Тип підрозділу',
              value: typeFilterLabel,
              onTap: onTypeFilterTap,
            ),
            _FilterChipButton(
              label: 'Стан звʼязку',
              value: statusFilterLabel,
              onTap: onStatusFilterTap,
            ),
            _FilterChipButton(
              label: 'Зона / район',
              value: areaFilterLabel,
              onTap: onAreaFilterTap,
            ),
          ],
        );

        final resetButton = TextButton(
          onPressed: onReset,
          child: Text(
            'Скинути',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: resetColor,
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              filters,
              const SizedBox(height: 12),
              Row(
                children: [searchField, const SizedBox(width: 8), resetButton],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: filters),
              const SizedBox(width: 12),
              searchField,
              const SizedBox(width: 8),
              resetButton,
            ],
          );
        }
      },
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();
    final textTheme = theme.textTheme;

    final muted =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.7),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label:',
              style: textTheme.bodySmall?.copyWith(fontSize: 12, color: muted),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: muted),
          ],
        ),
      ),
    );
  }
}

/// ───────────────── ТАБЛИЦЯ / СПИСОК ПІДРОЗДІЛІВ ─────────────────

class _UnitsTable extends StatelessWidget {
  final List<Unit> units;
  final ValueChanged<Unit> onEdit;
  final ValueChanged<Unit> onDelete;

  const _UnitsTable({
    required this.units,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Для вузьких екранів показуємо card-список замість таблиці
        if (constraints.maxWidth < 720) {
          return _UnitsListMobile(
            units: units,
            onEdit: onEdit,
            onDelete: onDelete,
          );
        }

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final extra = theme.extension<AppExtraColors>();
        final textTheme = theme.textTheme;

        final headerBg =
            colorScheme.surfaceContainerHighest ??
            colorScheme.surface.withOpacity(1.02);

        final headerTextColor =
            textTheme.bodySmall?.color ??
            colorScheme.onSurface.withOpacity(0.7);

        final dividerColor =
            extra?.borderDefault ?? colorScheme.outline.withOpacity(0.7);

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dividerColor),
          ),
          child: Column(
            children: [
              // Заголовки колонок
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: headerBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const _HeaderCell(flex: 2, label: 'Підрозділ'),
                    const _HeaderCell(flex: 2, label: 'Тип'),
                    const _HeaderCell(flex: 2, label: 'Район / зона'),
                    const _HeaderCell(flex: 2, label: 'Стан звʼязку'),
                    const _HeaderCell(flex: 1, label: 'Активність'),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Дії',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: headerTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, thickness: 1, color: dividerColor),

              // Рядки
              if (units.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Підрозділи відсутні. Додайте перший підрозділ.',
                    style: textTheme.bodyMedium,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: units.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, thickness: 1, color: dividerColor),
                  itemBuilder: (context, index) {
                    final unit = units[index];
                    return _UnitRow(
                      unit: unit,
                      onEdit: () => onEdit(unit),
                      onDelete: () => onDelete(unit),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _UnitsListMobile extends StatelessWidget {
  final List<Unit> units;
  final ValueChanged<Unit> onEdit;
  final ValueChanged<Unit> onDelete;

  const _UnitsListMobile({
    required this.units,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = theme.extension<AppExtraColors>();
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final cardBorder =
        extra?.borderDefault ?? colorScheme.outline.withOpacity(0.7);

    if (units.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Підрозділи відсутні. Додайте перший підрозділ.',
          style: textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      children: [
        for (final unit in units)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: _UnitCardMobile(
              unit: unit,
              onEdit: () => onEdit(unit),
              onDelete: () => onDelete(unit),
            ),
          ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final int flex;
  final String label;

  const _HeaderCell({required this.flex, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final color =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  final Unit unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UnitRow({
    required this.unit,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    final extra = theme.extension<AppExtraColors>();
    final colorScheme = theme.colorScheme;

    switch (unit.status) {
      case 'OK':
        return extra?.success ?? colorScheme.primary;
      case 'Warning':
        return extra?.warning ?? colorScheme.secondary;
      case 'Critical':
        return colorScheme.error;
      default:
        return theme.textTheme.bodySmall?.color ??
            colorScheme.onSurface.withOpacity(0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final statusColor = _statusColor(context);
    final secondaryText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                unit.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                unit.type,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: secondaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                unit.area,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: secondaryText,
                ),
                overflow: TextOverflow.ellipsis,
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
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      unit.statusLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: statusColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  unit.activity,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: secondaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
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
          ],
        ),
      ),
    );
  }
}

class _UnitCardMobile extends StatelessWidget {
  final Unit unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UnitCardMobile({
    required this.unit,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    final extra = theme.extension<AppExtraColors>();
    final colorScheme = theme.colorScheme;

    switch (unit.status) {
      case 'OK':
        return extra?.success ?? colorScheme.primary;
      case 'Warning':
        return extra?.warning ?? colorScheme.secondary;
      case 'Critical':
        return colorScheme.error;
      default:
        return theme.textTheme.bodySmall?.color ??
            colorScheme.onSurface.withOpacity(0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final statusColor = _statusColor(context);
    final secondaryText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          unit.name,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          unit.type,
          style: textTheme.bodySmall?.copyWith(color: secondaryText),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.place, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                unit.area,
                style: textTheme.bodySmall?.copyWith(color: secondaryText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                unit.statusLabel,
                style: textTheme.bodyMedium?.copyWith(color: statusColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Активність: ${unit.activity}',
          style: textTheme.bodySmall?.copyWith(color: secondaryText),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Редагувати',
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Видалити',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}
