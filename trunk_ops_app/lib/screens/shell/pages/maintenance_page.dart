import 'package:flutter/material.dart';
import 'package:trunk_ops_app/models/asset.dart';
import 'package:trunk_ops_app/services/asset_local_repository.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

/// Сторінка планування та моніторингу технічного обслуговування.
/// Дані беруться з локального репозиторію засобів (AssetLocalRepository).
class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final AssetLocalRepository _repo = AssetLocalRepository();

  bool _isLoading = true;
  List<Asset> _assets = [];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    final assets = await _repo.getAll();
    setState(() {
      _assets = assets;
      _isLoading = false;
    });
  }

  // ───────────── Розрахунок метрик ─────────────

  bool _hasLastCheck(Asset a) {
    final v = a.lastCheck.trim();
    return v.isNotEmpty && v != '-';
  }

  int get _plannedCount =>
      _assets.where((a) => a.status == 'На ремонті').length;

  int get _doneCount =>
      _assets.where((a) => a.status == 'У строю' && _hasLastCheck(a)).length;

  int get _criticalCount => _assets
      .where(
        (a) =>
            a.status == 'На ремонті' &&
            (a.lastCheck.trim().isEmpty || a.lastCheck.trim() == '-'),
      )
      .length;

  int get _deferredCount => _assets.where((a) => a.status == 'Резерв').length;

  /// Формуємо список задач ТО на основі засобів.
  List<_MaintenanceTask> get _tasks {
    final List<_MaintenanceTask> result = [];

    for (final a in _assets) {
      if (a.status != 'На ремонті' && a.status != 'Резерв') continue;

      final String title = '${a.type} ${a.model}'.trim().isEmpty
          ? a.invNumber
          : '${a.type} ${a.model}';

      final String date =
          a.lastCheck.trim().isEmpty || a.lastCheck.trim() == '-'
          ? '—'
          : a.lastCheck.trim();

      String status;
      if (a.status == 'На ремонті') {
        status = 'Critical';
      } else if (a.status == 'Резерв') {
        status = 'Warning';
      } else {
        status = 'OK';
      }

      final description =
          'Інв. № ${a.invNumber}, підрозділ: ${a.unit}, місце: ${a.location}';

      result.add(
        _MaintenanceTask(
          assetId: a.id,
          title: title,
          date: date,
          status: status,
          statusLabel: a.status,
          description: description,
        ),
      );
    }

    return result;
  }

  Asset? _findAssetById(int id) {
    try {
      return _assets.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  // ───────────── CRUD ЗАДАЧ ТО ─────────────

  Future<void> _openCreateTaskDialog() async {
    if (_assets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Немає засобів для створення задачі ТО')),
      );
      return;
    }

    final theme = Theme.of(context);
    final assets = List<Asset>.from(_assets)
      ..sort((a, b) => a.invNumber.compareTo(b.invNumber));

    int? selectedAssetId = assets.first.id;
    String status = 'На ремонті';
    final dateController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = theme.colorScheme;
        final extra = theme.extension<AppExtraColors>();

        return AlertDialog(
          title: const Text('Нова задача ТО'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedAssetId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Засіб'),
                  items: assets
                      .map(
                        (a) => DropdownMenuItem<int>(
                          value: a.id,
                          child: Text(
                            '${a.invNumber} • ${a.type} ${a.model}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => selectedAssetId = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Статус задачі'),
                  items: const [
                    DropdownMenuItem(
                      value: 'На ремонті',
                      child: Text('На ремонті'),
                    ),
                    DropdownMenuItem(value: 'Резерв', child: Text('Резерв')),
                  ],
                  onChanged: (v) {
                    if (v != null) status = v;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Планова / остання дата (текстом)',
                    hintText: 'Напр. 20.11.2025',
                  ),
                ),
              ],
            ),
          ),
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
                if (selectedAssetId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Оберіть засіб')),
                  );
                  return;
                }

                final asset = _findAssetById(selectedAssetId!);
                if (asset == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Не вдалося знайти обраний засіб'),
                    ),
                  );
                  return;
                }

                final updated = asset.copyWith(
                  status: status,
                  lastCheck: dateController.text.trim().isEmpty
                      ? asset.lastCheck
                      : dateController.text.trim(),
                );

                await _repo.update(updated);
                await _loadAssets();

                if (context.mounted) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('Створити'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // вже оновилися
    }
  }

  Future<void> _openEditTaskDialog(_MaintenanceTask task) async {
    final asset = _findAssetById(task.assetId);
    if (asset == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Відповідний засіб не знайдено')),
      );
      return;
    }

    String status = asset.status;
    final dateController = TextEditingController(
      text: asset.lastCheck == '-' ? '' : asset.lastCheck,
    );

    final theme = Theme.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = theme.colorScheme;
        final extra = theme.extension<AppExtraColors>();

        return AlertDialog(
          title: const Text('Редагувати задачу ТО'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Інв. № ${asset.invNumber}\n${asset.type} ${asset.model}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Статус засобу / задачі',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'У строю', child: Text('У строю')),
                    DropdownMenuItem(
                      value: 'На ремонті',
                      child: Text('На ремонті'),
                    ),
                    DropdownMenuItem(value: 'Резерв', child: Text('Резерв')),
                  ],
                  onChanged: (v) {
                    if (v != null) status = v;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Планова / остання дата (текстом)',
                    hintText: 'Напр. 20.11.2025',
                  ),
                ),
              ],
            ),
          ),
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
                final updated = asset.copyWith(
                  status: status,
                  lastCheck: dateController.text.trim().isEmpty
                      ? '-'
                      : dateController.text.trim(),
                );

                await _repo.update(updated);
                await _loadAssets();

                if (context.mounted) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('Зберегти'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // оновлення вже виконано
    }
  }

  Future<void> _confirmDeleteTask(_MaintenanceTask task) async {
    final asset = _findAssetById(task.assetId);
    if (asset == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Відповідний засіб не знайдено')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити задачу ТО'),
        content: Text(
          'Задача ТО для засобу:\n'
          'Інв. № ${asset.invNumber}, ${asset.type} ${asset.model}\n\n'
          'Буде видалена, а статус засобу змінено на "У строю".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Підтвердити'),
          ),
        ],
      ),
    );

    if (result == true) {
      final updated = asset.copyWith(status: 'У строю');
      await _repo.update(updated);
      await _loadAssets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final subtitleColor =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const spacing = 16.0;

        // Скільки карток в ряд залежно від ширини.
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

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок сторінки
              Text(
                'Технічне обслуговування',
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Планування та моніторинг задач з технічного обслуговування',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),

              const SizedBox(height: 24),

              // Кнопка оновлення + статус завантаження
              Row(
                children: [
                  IconButton(
                    tooltip: 'Оновити дані',
                    onPressed: _loadAssets,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  if (_isLoading)
                    Text(
                      'Завантаження даних...',
                      style: textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                    )
                  else
                    Text(
                      'Засобів у системі: ${_assets.length}',
                      style: textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Картки-метрики
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      title: 'Заплановані задачі',
                      value: _plannedCount.toString(),
                      subtitle: 'засоби зі статусом "На ремонті"',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      title: 'Виконані задачі',
                      value: _doneCount.toString(),
                      subtitle: 'засоби "У строю" з вказаною датою перевірки',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      title: 'Критичні задачі',
                      value: _criticalCount.toString(),
                      subtitle: 'ремонт без дати останньої перевірки',
                      highlight: true,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MaintenanceStatCard(
                      title: 'Відкладені задачі',
                      value: _deferredCount.toString(),
                      subtitle: 'засоби зі статусом "Резерв"',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Таблиця / список задач ТО
              _MaintenanceTaskList(
                tasks: _tasks,
                isLoading: _isLoading,
                onCreateTask: _openCreateTaskDialog,
                onEditTask: _openEditTaskDialog,
                onDeleteTask: _confirmDeleteTask,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Невелика картка для відображення статистики по задачах ТО.
class _MaintenanceStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool highlight;

  const _MaintenanceStatCard({
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

/// Таблиця задач ТО. Рендерить рядки на основі списку `_MaintenanceTask`.
class _MaintenanceTaskList extends StatelessWidget {
  final List<_MaintenanceTask> tasks;
  final bool isLoading;
  final VoidCallback onCreateTask;
  final ValueChanged<_MaintenanceTask> onEditTask;
  final ValueChanged<_MaintenanceTask> onDeleteTask;

  const _MaintenanceTaskList({
    required this.tasks,
    required this.isLoading,
    required this.onCreateTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();
    final textTheme = theme.textTheme;

    final dividerColor =
        extra?.borderDefault ?? colorScheme.outline.withOpacity(0.7);

    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        padding: const EdgeInsets.all(24),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (tasks.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        padding: const EdgeInsets.all(24),
        child: Text(
          'Немає задач технічного обслуговування (засоби зі статусом '
          '"На ремонті" або "Резерв" відсутні).',
          style: textTheme.bodyMedium,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          // Заголовок таблиці + кнопка "Додати"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color:
                  colorScheme.surfaceContainerHighest ??
                  colorScheme.surface.withOpacity(1.02),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: _TaskHeaderCell(flex: 2, label: 'Задача'),
                ),
                const Expanded(
                  flex: 1,
                  child: _TaskHeaderCell(
                    flex: 1,
                    label: 'Планова / остання дата',
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: _TaskHeaderCell(flex: 1, label: 'Статус'),
                ),
                const Expanded(
                  flex: 2,
                  child: _TaskHeaderCell(flex: 2, label: 'Опис'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Додати задачу ТО',
                  onPressed: onCreateTask,
                  icon: const Icon(Icons.add_task),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, thickness: 1, color: dividerColor),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _MaintenanceTaskRow(
                task: task,
                onEdit: () => onEditTask(task),
                onDelete: () => onDeleteTask(task),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TaskHeaderCell extends StatelessWidget {
  final int flex;
  final String label;

  const _TaskHeaderCell({required this.flex, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final color =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);
    return Text(
      label,
      style: textTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

class _MaintenanceTaskRow extends StatelessWidget {
  final _MaintenanceTask task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaintenanceTaskRow({
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    final extra = theme.extension<AppExtraColors>();
    final colorScheme = theme.colorScheme;
    switch (task.status) {
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
    final muted =
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
                task.title,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                task.date,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: muted,
                ),
              ),
            ),
            Expanded(
              flex: 1,
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
                  Expanded(
                    child: Text(
                      task.statusLabel,
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
              child: Text(
                task.description,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: muted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Редагувати задачу',
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Видалити задачу',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Модель даних задачі ТО.
class _MaintenanceTask {
  final int assetId;
  final String title;
  final String date;
  final String status; // OK / Warning / Critical (для кольорів)
  final String statusLabel; // Текстовий статус для відображення
  final String description;

  _MaintenanceTask({
    required this.assetId,
    required this.title,
    required this.date,
    required this.status,
    required this.statusLabel,
    required this.description,
  });
}
