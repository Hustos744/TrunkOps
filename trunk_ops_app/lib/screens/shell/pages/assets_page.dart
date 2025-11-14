import 'package:flutter/material.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

class AssetsPage extends StatelessWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final titleFontSize = screenWidth < 900 ? 20.0 : 24.0;
        final subtitleFontSize = screenWidth < 900 ? 12.0 : 14.0;

        return Scrollbar(
          thumbVisibility: false, // один вертикальний скрол на всю сторінку
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ───────────── Заголовок + кнопки ─────────────
                  LayoutBuilder(
                    builder: (context, headerConstraints) {
                      final isNarrow = headerConstraints.maxWidth < 900;

                      final title = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Облік засобів',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: scheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Облік, стан та розподіл засобів транкінгового звʼязку по підрозділах',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: subtitleFontSize,
                              color:
                                  theme.textTheme.bodySmall?.color ??
                                  scheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                        ],
                      );

                      final actions = Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: isNarrow
                            ? WrapAlignment.start
                            : WrapAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: імпорт з Excel/CSV
                            },
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
                            onPressed: () {
                              // TODO: експорт
                            },
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
                            onPressed: () {
                              // TODO: додати новий засіб
                            },
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

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            const SizedBox(height: 12),
                            actions,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: title),
                          const SizedBox(width: 16),
                          actions,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ───────────── Карточки-метрики ─────────────
                  LayoutBuilder(
                    builder: (context, metricsConstraints) {
                      final maxWidth = metricsConstraints.maxWidth;
                      int columns;
                      if (maxWidth >= 1300) {
                        columns = 4;
                      } else if (maxWidth >= 900) {
                        columns = 3;
                      } else if (maxWidth >= 600) {
                        columns = 2;
                      } else {
                        columns = 1;
                      }

                      const spacing = 12.0;
                      final itemWidth =
                          (maxWidth - spacing * (columns - 1)) / columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: const _MetricCard(
                              title: 'Усього засобів',
                              value: '248',
                              trendLabel: '+12 за місяць',
                              trendPositive: true,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: const _MetricCard(
                              title: 'У строю',
                              value: '201',
                              trendLabel: '+4 за тиждень',
                              trendPositive: true,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: const _MetricCard(
                              title: 'На ремонті',
                              value: '31',
                              trendLabel: '+3 заявки',
                              trendPositive: false,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: const _MetricCard(
                              title: 'Резерв / склад',
                              value: '16',
                              trendLabel: 'оновлено 2 дні тому',
                              trendPositive: true,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ───────────── Фільтри ─────────────
                  const _AssetsFiltersBar(),

                  const SizedBox(height: 12),

                  // ───────────── Таблиця ─────────────
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
                            color:
                                extra?.surfaceSubtle ?? scheme.surfaceVariant,
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
                                onPressed: () {
                                  // TODO: оновити дані
                                },
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

                        // Горизонтальний скрол таблиці, вертикаль — у всієї сторінки
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingTextStyle: theme.textTheme.labelMedium
                                ?.copyWith(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                            dataTextStyle: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'Inter',
                              color: scheme.onSurface.withOpacity(0.9),
                            ),
                            columnSpacing: screenWidth < 900 ? 20 : 32,
                            dividerThickness: 0.6,
                            columns: const [
                              DataColumn(label: Text('Інв. №')),
                              DataColumn(label: Text('Тип засобу')),
                              DataColumn(label: Text('Модель')),
                              DataColumn(label: Text('Підрозділ')),
                              DataColumn(label: Text('Статус')),
                              DataColumn(label: Text('Місцезнаходження')),
                              DataColumn(label: Text('Остання перевірка')),
                            ],
                            rows: [
                              _assetRow(
                                context,
                                inv: 'TRK-0001',
                                type: 'Радіостанція портативна',
                                model: 'Motorola DP4801e',
                                unit: '1 рота / 1 взвод',
                                status: 'У строю',
                                location: 'Польовий КП',
                                lastCheck: '12.11.2025',
                              ),
                              _assetRow(
                                context,
                                inv: 'TRK-0034',
                                type: 'Радіостанція автомобільна',
                                model: 'Hytera MD785G',
                                unit: 'Рота звʼязку',
                                status: 'На ремонті',
                                location: 'Рембаза №2',
                                lastCheck: '05.11.2025',
                              ),
                              _assetRow(
                                context,
                                inv: 'TRK-0112',
                                type: 'Ретранслятор',
                                model: 'Motorola SLR 5500',
                                unit: 'Батальйонний вузол',
                                status: 'У строю',
                                location: 'Позиція Р-3',
                                lastCheck: '29.10.2025',
                              ),
                              _assetRow(
                                context,
                                inv: 'TRK-0178',
                                type: 'Радіостанція портативна',
                                model: 'Harris RF-7850',
                                unit: 'Резерв',
                                status: 'Резерв',
                                location: 'Склад №4',
                                lastCheck: '01.11.2025',
                              ),
                            ],
                          ),
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

// ───────────────── Карточка метрики ─────────────────

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

    final valueFontSize = screenWidth < 900 ? 20.0 : 24.0;
    final titleFontSize = screenWidth < 900 ? 12.0 : 14.0;

    final Color trendColor = trendPositive
        ? (extra?.success ?? scheme.primary)
        : scheme.error;

    return Container(
      decoration: BoxDecoration(
        color: extra?.surfaceElevated ?? scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: extra?.borderDefault ?? scheme.outline.withOpacity(0.6),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFamily: 'Inter',
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                trendPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: trendColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  trendLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Inter',
                    color: trendColor,
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

// ───────────────── Панель фільтрів ─────────────────

class _AssetsFiltersBar extends StatelessWidget {
  const _AssetsFiltersBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool isNarrowRow = maxWidth < 900;
        final bool isVeryNarrow = maxWidth < 700;

        final searchField = TextField(
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: scheme.onSurface,
          ),
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
          value: null,
          decoration: _dropdownDecoration(context, label: 'Тип засобу'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Усі типи')),
            DropdownMenuItem(value: 'portable', child: Text('Портативні')),
            DropdownMenuItem(value: 'mobile', child: Text('Автомобільні')),
            DropdownMenuItem(value: 'repeater', child: Text('Ретранслятори')),
          ],
          onChanged: (_) {},
        );

        final statusDropdown = DropdownButtonFormField<String>(
          value: null,
          decoration: _dropdownDecoration(context, label: 'Статус'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Усі статуси')),
            DropdownMenuItem(value: 'active', child: Text('У строю')),
            DropdownMenuItem(value: 'maintenance', child: Text('На ремонті')),
            DropdownMenuItem(value: 'reserve', child: Text('Резерв')),
          ],
          onChanged: (_) {},
        );

        final unitDropdown = DropdownButtonFormField<String>(
          value: null,
          decoration: _dropdownDecoration(context, label: 'Підрозділ'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Усі підрозділи')),
            DropdownMenuItem(value: 'unit1', child: Text('1 рота')),
            DropdownMenuItem(value: 'unit2', child: Text('Рота звʼязку')),
          ],
          onChanged: (_) {},
        );

        final resetButtonFull = TextButton.icon(
          onPressed: () {
            // TODO: скинути фільтри
          },
          icon: const Icon(Icons.filter_alt_off, size: 18),
          label: const Text(
            'Скинути фільтри',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          style: TextButton.styleFrom(
            foregroundColor: scheme.onBackground.withOpacity(0.8),
          ),
        );

        final resetButtonShort = TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_alt_off, size: 18),
          label: const Text('Скинути', style: TextStyle(fontFamily: 'Inter')),
          style: TextButton.styleFrom(
            foregroundColor: scheme.onBackground.withOpacity(0.8),
          ),
        );

        if (isVeryNarrow) {
          // Дуже вузький екран — усе у стовпчик
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
              Align(alignment: Alignment.centerRight, child: resetButtonFull),
            ],
          );
        }

        if (isNarrowRow) {
          // Середня ширина (700–900) — пошук окремо, дропдауни в два рядки
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1) Пошук на всю ширину
              searchField,
              const SizedBox(height: 8),

              // 2) Перший ряд — тип + статус
              Row(
                children: [
                  Expanded(child: typeDropdown),
                  const SizedBox(width: 12),
                  Expanded(child: statusDropdown),
                ],
              ),
              const SizedBox(height: 8),

              // 3) Другий ряд — підрозділ + кнопка "Скинути фільтри"
              Row(
                children: [
                  Expanded(child: unitDropdown),
                  const SizedBox(width: 12),
                  resetButtonFull,
                ],
              ),
            ],
          );
        }

        // 🔹 Широкі екрани — все в один ряд + коротка кнопка "Скинути"
        final filtersRow = Row(
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
            Expanded(child: filtersRow),
            const SizedBox(width: 12),
            resetButtonShort,
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

// ───────────────── Хелпер для DataRow ─────────────────

DataRow _assetRow(
  BuildContext context, {
  required String inv,
  required String type,
  required String model,
  required String unit,
  required String status,
  required String location,
  required String lastCheck,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final extra = theme.extension<AppExtraColors>();

  Color statusColor;
  switch (status) {
    case 'У строю':
      statusColor = extra?.success ?? const Color(0xFF7DD58C);
      break;
    case 'На ремонті':
      statusColor = scheme.error;
      break;
    case 'Резерв':
      statusColor = extra?.warning ?? const Color(0xFFFFC107);
      break;
    default:
      statusColor =
          theme.textTheme.bodySmall?.color ?? scheme.onSurface.withOpacity(0.6);
  }

  return DataRow(
    cells: [
      DataCell(Text(inv)),
      DataCell(Text(type)),
      DataCell(Text(model)),
      DataCell(Text(unit)),
      DataCell(
        Row(
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
            const SizedBox(width: 6),
            Text(status, style: TextStyle(color: statusColor)),
          ],
        ),
      ),
      DataCell(Text(location)),
      DataCell(Text(lastCheck)),
    ],
  );
}
