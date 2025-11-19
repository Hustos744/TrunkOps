import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trunk_ops_app/models/coverage_models.dart';
import 'package:trunk_ops_app/services/coverage_api_service.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

class CoveragePage extends StatelessWidget {
  const CoveragePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final bool isWide = maxWidth >= 1100;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Text(
                'Мапа покриття',
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Візуалізація зони дії транкінгової мережі та взаємодії між вузлами',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color:
                      textTheme.bodySmall?.color ??
                      colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),

              // Верхня панель фільтрів (формальна, поки без логіки)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _FilterPill(
                    label: 'ОТУ',
                    value: 'ОТУ «Північ»',
                    onTap: () {},
                  ),
                  _FilterPill(
                    label: 'Масштаб',
                    value: 'Оперативно-тактичний',
                    onTap: () {},
                  ),
                  _FilterPill(
                    label: 'Шар',
                    value: 'Покриття + вузли',
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      // TODO: скидання фільтрів
                    },
                    child: Text(
                      'Скинути фільтри',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color:
                            theme.extension<AppExtraColors>()?.warning ??
                            colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Основний контент
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(flex: 3, child: _CoverageMapCard()),
                    SizedBox(width: 20),
                    Expanded(flex: 2, child: _SideStatusPanel()),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _CoverageMapCard(),
                    SizedBox(height: 16),
                    _SideStatusPanel(),
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// ───────────────────── МОДЕЛЬ ВНУТРІШНЬОЇ СТАНЦІЇ ─────────────────────

class _Station {
  final String name;
  final Color color;
  double? lat;
  double? lon;

  _Station({required this.name, required this.color, this.lat, this.lon});
}

/// ───────────────────── КАРТКА З МАПОЮ ПОКРИТТЯ ─────────────────────

class _CoverageMapCard extends StatefulWidget {
  const _CoverageMapCard();

  @override
  State<_CoverageMapCard> createState() => _CoverageMapCardState();
}

class _CoverageMapCardState extends State<_CoverageMapCard> {
  // Бек завжди локальний, запуск на емуляторі → 10.0.2.2
  final CoverageApiService _api = CoverageApiService();
  final Distance _distance = const Distance();

  // Параметри станції (активної)
  final TextEditingController _centerLatController = TextEditingController(
    text: '50.4501',
  );
  final TextEditingController _centerLonController = TextEditingController(
    text: '30.5234',
  );
  final TextEditingController _radiusKmController = TextEditingController(
    text: '5',
  );
  final TextEditingController _stepMController = TextEditingController(
    text: '200',
  );
  final TextEditingController _frequencyController = TextEditingController(
    text: '410',
  );
  final TextEditingController _bsHeightController = TextEditingController(
    text: '30',
  );
  final TextEditingController _txPowerController = TextEditingController(
    text: '43',
  );
  final TextEditingController _rxHeightController = TextEditingController(
    text: '1.5',
  );

  bool _isLoading = false;
  CoverageResponse? _coverage;

  // Дві станції для взаємодії
  final List<_Station> _stations = [
    _Station(name: 'Станція 1', color: Colors.blueAccent),
    _Station(name: 'Станція 2', color: Colors.orangeAccent),
  ];
  int _selectedStationIndex = 0;

  _Station get _selectedStation => _stations[_selectedStationIndex];

  @override
  void dispose() {
    _centerLatController.dispose();
    _centerLonController.dispose();
    _radiusKmController.dispose();
    _stepMController.dispose();
    _frequencyController.dispose();
    _bsHeightController.dispose();
    _txPowerController.dispose();
    _rxHeightController.dispose();
    super.dispose();
  }

  Future<void> _calculateCoverage(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      final centerLat = double.parse(_centerLatController.text.trim());
      final centerLon = double.parse(_centerLonController.text.trim());
      final radiusKm = double.parse(_radiusKmController.text.trim());
      final stepM = double.parse(_stepMController.text.trim());
      final freqMhz = double.parse(_frequencyController.text.trim());
      final bsHeightM = double.parse(_bsHeightController.text.trim());
      final txPowerDbm = double.parse(_txPowerController.text.trim());
      final rxHeightM = double.parse(_rxHeightController.text.trim());

      // Підтягнути координати в активну станцію
      _selectedStation.lat = centerLat;
      _selectedStation.lon = centerLon;

      final site = Site(
        id: _selectedStation.name,
        lat: centerLat,
        lon: centerLon,
        txPowerDbm: txPowerDbm,
        antennaGainDbi: 9,
        antennaHeightM: bsHeightM,
        frequencyMhz: freqMhz,
      );

      final grid = GridConfig(
        centerLat: centerLat,
        centerLon: centerLon,
        radiusKm: radiusKm,
        stepM: stepM,
      );

      final req = CoverageRequest(
        sites: [site],
        rxHeightM: rxHeightM,
        grid: grid,
      );

      final resp = await _api.calculateCoverage(req);

      if (!mounted) return;
      setState(() {
        _coverage = resp;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка розрахунку: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _colorForRx(double rxDbm, ThemeData theme) {
    if (rxDbm >= -80) {
      return Colors.green.withOpacity(0.8);
    } else if (rxDbm >= -95) {
      return Colors.yellow.withOpacity(0.8);
    } else if (rxDbm >= -110) {
      return Colors.orange.withOpacity(0.8);
    } else {
      return Colors.red.withOpacity(0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final mutedText =
        theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);

    final centerLat =
        double.tryParse(_centerLatController.text.trim()) ?? 50.4501;
    final centerLon =
        double.tryParse(_centerLonController.text.trim()) ?? 30.5234;

    final radiusKm = double.tryParse(_radiusKmController.text.trim()) ?? 5.0;

    // Маркери станцій
    final markers = <Marker>[];
    for (final station in _stations) {
      if (station.lat != null && station.lon != null) {
        markers.add(
          Marker(
            point: LatLng(station.lat!, station.lon!),
            width: 30,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: station.color,
                boxShadow: [
                  BoxShadow(
                    color: station.color.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.radio_button_checked,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Лінії між станціями (чи "працюють" одна з одною)
    final polylines = <Polyline>[];
    if (_stations.length >= 2) {
      for (var i = 0; i < _stations.length; i++) {
        for (var j = i + 1; j < _stations.length; j++) {
          final a = _stations[i];
          final b = _stations[j];
          if (a.lat == null || b.lat == null) continue;

          final distKm = _distance.as(
            LengthUnit.Kilometer,
            LatLng(a.lat!, a.lon!),
            LatLng(b.lat!, b.lon!),
          );

          final within = distKm <= radiusKm;
          polylines.add(
            Polyline(
              points: [LatLng(a.lat!, a.lon!), LatLng(b.lat!, b.lon!)],
              strokeWidth: 3,
              color: within ? Colors.greenAccent : Colors.redAccent,
            ),
          );
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Верхній опис
          Text(
            'Оперативна обстановка',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 14,
              color: mutedText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Інтерактивна мапа покриття та взаємодії між станціями',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Вибір активної станції
          Row(
            children: [
              Text(
                'Активна станція:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: mutedText,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedStationIndex,
                items: List.generate(_stations.length, (index) {
                  final st = _stations[index];
                  return DropdownMenuItem(
                    value: index,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: st.color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(st.name),
                      ],
                    ),
                  );
                }),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedStationIndex = value;

                    // Якщо у станції вже є координати — підтягнути їх в поля
                    final st = _selectedStation;
                    if (st.lat != null && st.lon != null) {
                      _centerLatController.text = st.lat!.toStringAsFixed(6);
                      _centerLonController.text = st.lon!.toStringAsFixed(6);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Панель параметрів
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SmallNumberField(label: 'Lat', controller: _centerLatController),
              _SmallNumberField(label: 'Lon', controller: _centerLonController),
              _SmallNumberField(
                label: 'Радіус, км',
                controller: _radiusKmController,
              ),
              _SmallNumberField(label: 'Крок, м', controller: _stepMController),
              _SmallNumberField(
                label: 'Частота, МГц',
                controller: _frequencyController,
              ),
              _SmallNumberField(
                label: 'H БС, м',
                controller: _bsHeightController,
              ),
              _SmallNumberField(
                label: 'Tx, dBm',
                controller: _txPowerController,
              ),
              _SmallNumberField(
                label: 'H Rx, м',
                controller: _rxHeightController,
              ),
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _calculateCoverage(context),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Розрахувати'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Легенда
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.background.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    extra?.borderDefault ??
                    colorScheme.outline.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: const Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _LegendDot(
                  color: Colors.green,
                  label: 'Стабільна зона (rx ≥ -80 dBm)',
                ),
                _LegendDot(color: Colors.yellow, label: 'Погіршене покриття'),
                _LegendDot(color: Colors.orange, label: 'Граничне покриття'),
                _LegendDot(color: Colors.red, label: 'Нижче порога'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Мапа в фіксованій висоті (щоб не було Expanded в ScrollView)
          SizedBox(
            height: 380,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(centerLat, centerLon),
                  initialZoom: 11,
                  onTap: (tapPos, latLng) {
                    setState(() {
                      // Переносимо активну станцію в точку тапу
                      _centerLatController.text = latLng.latitude
                          .toStringAsFixed(6);
                      _centerLonController.text = latLng.longitude
                          .toStringAsFixed(6);
                      _selectedStation.lat = latLng.latitude;
                      _selectedStation.lon = latLng.longitude;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  if (_coverage != null)
                    CircleLayer(
                      circles: _coverage!.cells.map((cell) {
                        final color = _colorForRx(cell.rxLevelDbm, theme);
                        return CircleMarker(
                          point: LatLng(cell.lat, cell.lon),
                          radius: 8,
                          color: color,
                        );
                      }).toList(),
                    ),
                  if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                  if (markers.isNotEmpty) MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────── БОКОВА ПАНЕЛЬ СТАНУ ─────────────────────

class _SideStatusPanel extends StatelessWidget {
  const _SideStatusPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final extra = theme.extension<AppExtraColors>();

    final stableColor = extra?.success ?? colorScheme.primary;
    final degradedColor = extra?.warning ?? colorScheme.secondary;
    final criticalColor = colorScheme.error;

    final mutedText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Стан покриття',
            style: textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _CoverageStatusRow(
            label: 'Стабільна зона',
            percent: 0.72,
            color: stableColor,
          ),
          const SizedBox(height: 8),
          _CoverageStatusRow(
            label: 'Погіршене покриття',
            percent: 0.18,
            color: degradedColor,
          ),
          const SizedBox(height: 8),
          _CoverageStatusRow(
            label: 'Критичні ділянки',
            percent: 0.10,
            color: criticalColor,
          ),
          const SizedBox(height: 20),
          Text(
            'Ключові вузли',
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _NodeStatusTile(
            name: 'Вузол А — Штаб ОТУ',
            status: 'OK',
            description: 'Основний вузол, стабільний канал, резерв увімкнено.',
            color: stableColor,
          ),
          const SizedBox(height: 8),
          _NodeStatusTile(
            name: 'Вузол B — Опорний пункт',
            status: 'Warning',
            description:
                'Періодичні втрати пакетів в години пікового навантаження.',
            color: degradedColor,
          ),
          const SizedBox(height: 8),
          _NodeStatusTile(
            name: 'Вузол C — Резервний ретранслятор',
            status: 'Critical',
            description: 'Знижена потужність передавача, потрібна перевірка.',
            color: criticalColor,
          ),
        ],
      ),
    );
  }
}

/// ───────────────────── ДОПОМІЖНІ ВІДЖЕТИ ─────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _FilterPill({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
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
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: colorScheme.onSurface,
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final legendTextColor =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: legendTextColor,
          ),
        ),
      ],
    );
  }
}

class _CoverageStatusRow extends StatelessWidget {
  final String label;
  final double percent; // 0..1
  final Color color;

  const _CoverageStatusRow({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final muted =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: muted,
                ),
              ),
            ),
            Text(
              '${(percent * 100).round()}%',
              style: textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _NodeStatusTile extends StatelessWidget {
  final String name;
  final String status;
  final String description;
  final Color color;

  const _NodeStatusTile({
    required this.name,
    required this.status,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final muted =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Кольоровий маркер
          Container(
            width: 8,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),

          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color, width: 1),
              color: color.withOpacity(0.12),
            ),
            child: Text(
              status,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _SmallNumberField({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 120,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ).copyWith(labelText: label),
      ),
    );
  }
}
