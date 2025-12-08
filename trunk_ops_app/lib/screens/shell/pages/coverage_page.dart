import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trunk_ops_app/models/asset.dart';
import 'package:trunk_ops_app/models/coverage_models.dart';
import 'package:trunk_ops_app/services/asset_local_repository.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

class CoveragePage extends StatefulWidget {
  const CoveragePage({super.key});

  @override
  State<CoveragePage> createState() => _CoveragePageState();
}

class _CoveragePageState extends State<CoveragePage> {
  CoverageResponse? _coverage;

  void _handleCoverageChanged(CoverageResponse? resp) {
    setState(() {
      _coverage = resp;
    });
  }

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
          padding: EdgeInsets.symmetric(
            horizontal: maxWidth < 600 ? 12 : 24,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Text(
                'Мапа покриття',
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: maxWidth < 600 ? 22 : 26,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Візуалізація зони дії транкінгової мережі та взаємодії між вузлами',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: maxWidth < 600 ? 13 : 14,
                  color:
                      textTheme.bodySmall?.color ??
                      colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),

              // Верхня панель фільтрів (формальна)
              const SizedBox(height: 12),

              // Основний контент
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _CoverageMapCard(
                        onCoverageChanged: _handleCoverageChanged,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _SideStatusPanel(coverage: _coverage),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CoverageMapCard(onCoverageChanged: _handleCoverageChanged),
                    const SizedBox(height: 16),
                    _SideStatusPanel(coverage: _coverage),
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

/// ───────────────────── ВНУТРІШНЯ МОДЕЛЬ СТАНЦІЇ ─────────────────────

class _Station {
  final Asset asset;
  final String label;
  final Color color;
  double? lat;
  double? lon;

  _Station({
    required this.asset,
    required this.label,
    required this.color,
    this.lat,
    this.lon,
  });

  /// Потужність передавача в dBm, обчислена з Вт.
  /// P[dBm] = 10 * log10(P[mW]), P[mW] = P[Вт] * 1000.
  double get txPowerDbm {
    if (asset.txPowerW == null) {
      // дефолт ~20 Вт ≈ 43 дБм
      return 43;
    }
    return 10 * log(asset.txPowerW! * 1000) / ln10;
  }

  double get frequencyMHz => asset.frequencyMHz ?? 410;
  double get antennaHeightM => asset.antennaHeightM ?? 30;
  double get antennaGainDb => asset.antennaGainDb ?? 9;
}

/// ───────────────────── ПАРАМЕТРИ МОДЕЛІ ПОШИРЕННЯ ─────────────────────

enum PropagationModel { hata, freeSpace }

enum EnvironmentType { urban, suburban, ruralOpen }

/// Режим візуалізації: класифіковані зони або heatmap.
enum CoverageViewMode { zones, heatmap }

/// ───────────────────── КАРТКА З МАПОЮ ПОКРИТТЯ ─────────────────────

class _CoverageMapCard extends StatefulWidget {
  final ValueChanged<CoverageResponse?> onCoverageChanged;

  const _CoverageMapCard({required this.onCoverageChanged});

  @override
  State<_CoverageMapCard> createState() => _CoverageMapCardState();
}

class _CoverageMapCardState extends State<_CoverageMapCard> {
  final AssetLocalRepository _assetRepo = AssetLocalRepository();
  final Distance _distance = const Distance();

  // Параметри розрахунку
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
  bool _assetsLoading = true;
  CoverageResponse? _coverage;

  List<_Station> _stations = [];
  int _selectedStationIndex = 0;

  // Модель поширення та тип середовища
  PropagationModel _model = PropagationModel.hata;
  EnvironmentType _envType = EnvironmentType.urban;

  // Додаткові налаштування
  bool _useAllStations = false; // комбіноване покриття
  bool _showTheoreticalContours = true; // аналітичні контури

  // Нове: режим візуалізації (зони / heatmap)
  CoverageViewMode _viewMode = CoverageViewMode.zones;

  _Station get _selectedStation => _stations[_selectedStationIndex];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadStations();
    await _loadPersistedState();
  }

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

  // ───────────── ЗАВАНТАЖЕННЯ СТАНЦІЙ З БД ─────────────

  Future<void> _loadStations() async {
    final assets = await _assetRepo.getAll();

    if (!mounted) return;

    setState(() {
      // Беремо всі assets, дефолти підставляються у _Station.
      _stations = List.generate(assets.length, (index) {
        final a = assets[index];
        final label =
            '${a.unit} • ${(a.model.isNotEmpty ? a.model : a.type)} (${a.invNumber})';
        final baseColor = Colors.primaries[index % Colors.primaries.length];

        return _Station(asset: a, label: label, color: baseColor.shade400);
      });

      _assetsLoading = false;

      if (_stations.isNotEmpty) {
        _selectedStationIndex = 0;
        _applyStationParams(_selectedStation);
      }
    });
  }

  // ───────────── ПІДСТАНОВКА ПАРАМЕТРІВ СТАНЦІЇ ─────────────

  void _applyStationParams(_Station st) {
    _frequencyController.text = st.frequencyMHz.toStringAsFixed(1);
    _bsHeightController.text = st.antennaHeightM.toStringAsFixed(1);
    _txPowerController.text = st.txPowerDbm.toStringAsFixed(1);
  }

  // ───────────── ЗБЕРЕЖЕННЯ / ВІДНОВЛЕННЯ СТАНУ ─────────────

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _centerLatController.text =
          prefs.getString('cov_center_lat') ?? _centerLatController.text;
      _centerLonController.text =
          prefs.getString('cov_center_lon') ?? _centerLonController.text;
      _radiusKmController.text =
          prefs.getString('cov_radius_km') ?? _radiusKmController.text;
      _stepMController.text =
          prefs.getString('cov_step_m') ?? _stepMController.text;
      _frequencyController.text =
          prefs.getString('cov_frequency_mhz') ?? _frequencyController.text;
      _bsHeightController.text =
          prefs.getString('cov_bs_height_m') ?? _bsHeightController.text;
      _txPowerController.text =
          prefs.getString('cov_tx_power_dbm') ?? _txPowerController.text;
      _rxHeightController.text =
          prefs.getString('cov_rx_height_m') ?? _rxHeightController.text;

      final savedIndex = prefs.getInt('cov_selected_station');
      if (savedIndex != null &&
          savedIndex >= 0 &&
          savedIndex < _stations.length) {
        _selectedStationIndex = savedIndex;
      }

      final modelStr = prefs.getString('cov_model');
      if (modelStr != null) {
        if (modelStr == 'hata') _model = PropagationModel.hata;
        if (modelStr == 'freeSpace') _model = PropagationModel.freeSpace;
      }

      final envStr = prefs.getString('cov_env');
      if (envStr != null) {
        if (envStr == 'urban') _envType = EnvironmentType.urban;
        if (envStr == 'suburban') _envType = EnvironmentType.suburban;
        if (envStr == 'ruralOpen') _envType = EnvironmentType.ruralOpen;
      }

      _useAllStations =
          prefs.getBool('cov_use_all_stations') ?? _useAllStations;
      _showTheoreticalContours =
          prefs.getBool('cov_show_contours') ?? _showTheoreticalContours;

      final viewStr = prefs.getString('cov_view_mode');
      if (viewStr != null) {
        if (viewStr == 'zones') _viewMode = CoverageViewMode.zones;
        if (viewStr == 'heatmap') _viewMode = CoverageViewMode.heatmap;
      }

      for (final st in _stations) {
        final lat = prefs.getDouble('cov_station_${st.asset.id}_lat');
        final lon = prefs.getDouble('cov_station_${st.asset.id}_lon');
        if (lat != null && lon != null) {
          st.lat = lat;
          st.lon = lon;
        }
      }
    });
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('cov_center_lat', _centerLatController.text.trim());
    await prefs.setString('cov_center_lon', _centerLonController.text.trim());
    await prefs.setString('cov_radius_km', _radiusKmController.text.trim());
    await prefs.setString('cov_step_m', _stepMController.text.trim());
    await prefs.setString(
      'cov_frequency_mhz',
      _frequencyController.text.trim(),
    );
    await prefs.setString('cov_bs_height_m', _bsHeightController.text.trim());
    await prefs.setString('cov_tx_power_dbm', _txPowerController.text.trim());
    await prefs.setString('cov_rx_height_m', _rxHeightController.text.trim());
    await prefs.setInt('cov_selected_station', _selectedStationIndex);

    await prefs.setString(
      'cov_model',
      _model == PropagationModel.hata ? 'hata' : 'freeSpace',
    );
    await prefs.setString('cov_env', switch (_envType) {
      EnvironmentType.urban => 'urban',
      EnvironmentType.suburban => 'suburban',
      EnvironmentType.ruralOpen => 'ruralOpen',
    });

    await prefs.setBool('cov_use_all_stations', _useAllStations);
    await prefs.setBool('cov_show_contours', _showTheoreticalContours);
    await prefs.setString(
      'cov_view_mode',
      _viewMode == CoverageViewMode.zones ? 'zones' : 'heatmap',
    );

    for (final st in _stations) {
      if (st.lat != null && st.lon != null) {
        await prefs.setDouble('cov_station_${st.asset.id}_lat', st.lat!);
        await prefs.setDouble('cov_station_${st.asset.id}_lon', st.lon!);
      }
    }
  }

  // ───────────── МАТЕМАТИЧНА МОДЕЛЬ (Hata / COST-231 / Free-space) ─────────────

  // Корекція для міста (urban)
  double _mobileCorrectionUrban(double freqMhz, double hm) {
    final logF = log(freqMhz) / ln10;
    return (1.1 * logF - 0.7) * hm - (1.56 * logF - 0.8);
  }

  /// Узагальнена модель Hata з урахуванням типу місцевості.
  double _hataPathLoss({
    required double freqMhz,
    required double distanceKm,
    required double hb,
    required double hm,
    required EnvironmentType envType,
  }) {
    final d = max(distanceKm, 0.01);
    final logF = log(freqMhz) / ln10;
    final logHb = log(hb) / ln10;
    final logD = log(d) / ln10;

    final aHmUrban = _mobileCorrectionUrban(freqMhz, hm);

    // Базовий urban Hata (150–1500 МГц)
    double lossUrban =
        69.55 +
        26.16 * logF -
        13.82 * logHb -
        aHmUrban +
        (44.9 - 6.55 * logHb) * logD;

    switch (envType) {
      case EnvironmentType.urban:
        // +3 дБ як поправка на щільну забудову (аналог COST-231)
        return lossUrban + 3.0;

      case EnvironmentType.suburban:
        // Рекомендована поправка для передмістя
        final term = log(freqMhz / 28.0) / ln10;
        final correction = -2 * term * term - 5.4;
        return lossUrban + correction;

      case EnvironmentType.ruralOpen:
        // Відкрита / сільська місцевість
        final correction = -4.78 * logF * logF + 18.33 * logF - 40.94;
        return lossUrban + correction;
    }
  }

  /// Вільний простір (free-space) у дБ: 32.45 + 20log10(f_MHz) + 20log10(d_km).
  double _freeSpacePathLoss({
    required double freqMhz,
    required double distanceKm,
  }) {
    final d = max(distanceKm, 0.001);
    final logF = log(freqMhz) / ln10;
    final logD = log(d) / ln10;
    return 32.45 + 20 * logF + 20 * logD;
  }

  /// Єдиний вхід: повертає втрати залежно від обраної моделі.
  double _pathLoss({
    required double freqMhz,
    required double distanceKm,
    required double hb,
    required double hm,
  }) {
    switch (_model) {
      case PropagationModel.hata:
        return _hataPathLoss(
          freqMhz: freqMhz,
          distanceKm: distanceKm,
          hb: hb,
          hm: hm,
          envType: _envType,
        );
      case PropagationModel.freeSpace:
        return _freeSpacePathLoss(freqMhz: freqMhz, distanceKm: distanceKm);
    }
  }

  /// Чисельний розвʼязок для відстані до ізолінії P_rx = threshold.
  double _solveDistanceForRxThreshold({
    required double freqMhz,
    required double hb,
    required double hm,
    required double txPowerDbm,
    required double gTx,
    required double gRx,
    required double rxThresholdDbm,
    double maxDistanceKm = 50.0,
  }) {
    double lo = 0.01;
    double hi = maxDistanceKm;

    for (int i = 0; i < 40; i++) {
      final mid = (lo + hi) / 2;
      final loss = _pathLoss(freqMhz: freqMhz, distanceKm: mid, hb: hb, hm: hm);
      final rx = txPowerDbm + gTx + gRx - loss;
      if (rx >= rxThresholdDbm) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return hi;
  }

  List<LatLng> _buildCirclePolygonCoords(LatLng center, double radiusKm) {
    final radiusM = radiusKm * 1000.0;
    final latRad = center.latitude * pi / 180.0;
    final cosLat = cos(latRad);
    const segments = 72;
    final points = <LatLng>[];

    for (int i = 0; i < segments; i++) {
      final ang = 2 * pi * i / segments;
      final dx = radiusM * cos(ang);
      final dy = radiusM * sin(ang);
      final dLat = dy / 111320.0;
      final dLon = dx / (111320.0 * max(cosLat, 0.1));
      points.add(LatLng(center.latitude + dLat, center.longitude + dLon));
    }

    return points;
  }

  // ───────────── ЛОКАЛЬНИЙ РОЗРАХУНОК ПОКРИТТЯ ─────────────

  Future<void> _calculateCoverage(BuildContext context) async {
    if (_stations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Немає жодної станції з бази даних. Додайте хоча б одну в розділі засобів.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final centerLat = double.parse(_centerLatController.text.trim());
      final centerLon = double.parse(_centerLonController.text.trim());
      final radiusKm = double.parse(_radiusKmController.text.trim());
      final stepM = double.parse(_stepMController.text.trim());
      final rxHeightM = double.parse(_rxHeightController.text.trim());

      final active = _selectedStation;
      final freqMhzActive = active.frequencyMHz;
      final hbActive = active.antennaHeightM;

      final txPowerDbmParsed = _txPowerController.text.trim();
      final txPowerDbmActive = double.parse(
        txPowerDbmParsed.isEmpty
            ? active.txPowerDbm.toString()
            : txPowerDbmParsed,
      );
      final gTxActive = active.antennaGainDb;
      const gRx = 0.0;

      // Привʼязуємо координати до активної станції
      active.lat = centerLat;
      active.lon = centerLon;

      final center = LatLng(centerLat, centerLon);
      final radiusM = radiusKm * 1000.0;
      final step = max(
        stepM,
        50.0,
      ); // не надто густо, щоб не вбити продуктивність

      final cells = <CoverageCell>[];

      final latRad = centerLat * pi / 180.0;
      final cosLat = cos(latRad);

      // Список станцій, які беремо в розрахунок
      final stationsForCalc = _useAllStations
          ? _stations.where((s) => s.lat != null && s.lon != null).toList()
          : <_Station>[active];

      if (stationsForCalc.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Для комбінованого покриття немає жодної станції з координатами.',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      for (double dy = -radiusM; dy <= radiusM; dy += step) {
        for (double dx = -radiusM; dx <= radiusM; dx += step) {
          final r = sqrt(dx * dx + dy * dy);
          if (r > radiusM) continue;

          // Перехід із локальних координат (x,y в метрах) до географічних
          final dLatDeg = dy / 111320.0;
          final dLonDeg = dx / (111320.0 * max(cosLat, 0.1));
          final lat = centerLat + dLatDeg;
          final lon = centerLon + dLonDeg;
          final cellLatLng = LatLng(lat, lon);

          double bestRx = -9999.0;

          for (final st in stationsForCalc) {
            if (st.lat == null || st.lon == null) continue;

            final dKm = max(
              _distance.as(
                LengthUnit.Kilometer,
                LatLng(st.lat!, st.lon!),
                cellLatLng,
              ),
              0.01,
            );

            final freqMhz = _useAllStations ? st.frequencyMHz : freqMhzActive;
            final hb = _useAllStations ? st.antennaHeightM : hbActive;
            final txDbm = _useAllStations ? st.txPowerDbm : txPowerDbmActive;
            final gTx = _useAllStations ? st.antennaGainDb : gTxActive;

            final loss = _pathLoss(
              freqMhz: freqMhz,
              distanceKm: dKm,
              hb: hb,
              hm: rxHeightM,
            );

            final rxDbm = txDbm + gTx + gRx - loss;
            if (rxDbm > bestRx) {
              bestRx = rxDbm;
            }
          }

          cells.add(CoverageCell(lat: lat, lon: lon, rxLevelDbm: bestRx));
        }
      }

      final resp = CoverageResponse(gridStepM: step, cells: cells);

      if (!mounted) return;
      setState(() {
        _coverage = resp;
      });

      widget.onCoverageChanged(resp);
      await _persistState();
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

  /// Класичне зональне забарвлення (як було раніше).
  Color _classifiedColorForRx(double rxDbm) {
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

  /// Нове: кольори для heatmap (градієнт від червоного до зеленого).
  Color _heatmapColorForRx(double rxDbm) {
    // Нормуємо рівень сигналу до [0;1] у діапазоні [-110; -70] dBm.
    const minDbm = -110.0;
    const maxDbm = -70.0;
    double t = (rxDbm - minDbm) / (maxDbm - minDbm);
    t = t.clamp(0.0, 1.0);

    // 0 -> червоний (0°), 1 -> зелений (120°).
    final hue = 0.0 + 120.0 * t;
    final hsv = HSVColor.fromAHSV(0.75, hue, 1.0, 1.0);
    return hsv.toColor();
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

    final screenWidth = MediaQuery.of(context).size.width;
    final bool compact = screenWidth < 700;

    if (_assetsLoading) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Маркери станцій (якщо вони є)
    final markers = <Marker>[];
    for (final station in _stations) {
      if (station.lat != null && station.lon != null) {
        markers.add(
          Marker(
            point: LatLng(station.lat!, station.lon!),
            width: 30,
            height: 30,
            child: Tooltip(
              message: station.label,
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
          ),
        );
      }
    }

    // Лінії між станціями
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

    // Аналітичні контури покриття від активної станції
    final polygons = <Polygon>[];
    final active = _stations.isNotEmpty ? _selectedStation : null;
    if (_showTheoreticalContours &&
        active != null &&
        active.lat != null &&
        active.lon != null) {
      final center = LatLng(active.lat!, active.lon!);
      final rxHeightM = double.tryParse(_rxHeightController.text.trim()) ?? 1.5;

      final txPowerDbmParsed = _txPowerController.text.trim();
      final txPowerDbm =
          double.tryParse(
            txPowerDbmParsed.isEmpty
                ? active.txPowerDbm.toString()
                : txPowerDbmParsed,
          ) ??
          active.txPowerDbm;

      const gRx = 0.0;
      final gTx = active.antennaGainDb;
      final maxD = max(radiusKm * 1.2, radiusKm);

      double rStable = _solveDistanceForRxThreshold(
        freqMhz: active.frequencyMHz,
        hb: active.antennaHeightM,
        hm: rxHeightM,
        txPowerDbm: txPowerDbm,
        gTx: gTx,
        gRx: gRx,
        rxThresholdDbm: -80,
        maxDistanceKm: maxD,
      );
      double rDegraded = _solveDistanceForRxThreshold(
        freqMhz: active.frequencyMHz,
        hb: active.antennaHeightM,
        hm: rxHeightM,
        txPowerDbm: txPowerDbm,
        gTx: gTx,
        gRx: gRx,
        rxThresholdDbm: -95,
        maxDistanceKm: maxD,
      );
      double rWeak = _solveDistanceForRxThreshold(
        freqMhz: active.frequencyMHz,
        hb: active.antennaHeightM,
        hm: rxHeightM,
        txPowerDbm: txPowerDbm,
        gTx: gTx,
        gRx: gRx,
        rxThresholdDbm: -110,
        maxDistanceKm: maxD,
      );

      rStable = min(rStable, radiusKm);
      rDegraded = min(rDegraded, radiusKm);
      rWeak = min(rWeak, radiusKm);

      polygons.add(
        Polygon(
          points: _buildCirclePolygonCoords(center, rStable),
          color: Colors.green.withOpacity(0.08),
          borderColor: Colors.green.withOpacity(0.6),
          borderStrokeWidth: 2,
        ),
      );
      polygons.add(
        Polygon(
          points: _buildCirclePolygonCoords(center, rDegraded),
          color: Colors.yellow.withOpacity(0.05),
          borderColor: Colors.yellow.withOpacity(0.6),
          borderStrokeWidth: 1.5,
        ),
      );
      polygons.add(
        Polygon(
          points: _buildCirclePolygonCoords(center, rWeak),
          color: Colors.orange.withOpacity(0.04),
          borderColor: Colors.orange.withOpacity(0.6),
          borderStrokeWidth: 1.3,
        ),
      );
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
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Верхній опис
          Text(
            'Оперативна обстановка',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: compact ? 13 : 14,
              color: mutedText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Інтерактивна мапа покриття та взаємодії між станціями',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Блок вибору активної станції — завжди видимий, якщо є станції
          if (_stations.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Активна станція',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: _selectedStationIndex,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
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
                          Expanded(
                            child: Text(
                              st.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      _selectedStationIndex = value;
                      final st = _selectedStation;
                      _applyStationParams(st);
                      if (st.lat != null && st.lon != null) {
                        _centerLatController.text = st.lat!.toStringAsFixed(6);
                        _centerLonController.text = st.lon!.toStringAsFixed(6);
                      }
                    });
                    await _persistState();
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _useAllStations,
                      onChanged: (val) async {
                        setState(() => _useAllStations = val);
                        await _persistState();
                      },
                    ),
                    Flexible(
                      child: Text(
                        'Усі станції (комбіноване покриття)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Немає засобів у локальній базі. Додайте хоча б один засіб у розділі «Засоби», '
                'щоб мати змогу привʼязати його до мапи.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: mutedText,
                ),
              ),
            ),

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

              // Вибір моделі поширення
              DropdownButton<PropagationModel>(
                value: _model,
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _model = value);
                  await _persistState();
                },
                items: const [
                  DropdownMenuItem(
                    value: PropagationModel.hata,
                    child: Text('Hata'),
                  ),
                  DropdownMenuItem(
                    value: PropagationModel.freeSpace,
                    child: Text('Free-space'),
                  ),
                ],
              ),

              // Вибір типу середовища
              DropdownButton<EnvironmentType>(
                value: _envType,
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _envType = value);
                  await _persistState();
                },
                items: const [
                  DropdownMenuItem(
                    value: EnvironmentType.urban,
                    child: Text('Місто'),
                  ),
                  DropdownMenuItem(
                    value: EnvironmentType.suburban,
                    child: Text('Приміське'),
                  ),
                  DropdownMenuItem(
                    value: EnvironmentType.ruralOpen,
                    child: Text('Відкрите'),
                  ),
                ],
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _showTheoreticalContours,
                    onChanged: (val) async {
                      if (val == null) return;
                      setState(() => _showTheoreticalContours = val);
                      await _persistState();
                    },
                  ),
                  Text(
                    'Аналітичні контури',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: mutedText,
                    ),
                  ),
                ],
              ),

              ElevatedButton.icon(
                onPressed: (_isLoading)
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

          // Перемикач режиму візуалізації
          Row(
            children: [
              Text(
                'Режим візуалізації:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: mutedText,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Зони покриття'),
                selected: _viewMode == CoverageViewMode.zones,
                onSelected: (sel) async {
                  if (!sel) return;
                  setState(() => _viewMode = CoverageViewMode.zones);
                  await _persistState();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Heatmap сигналу'),
                selected: _viewMode == CoverageViewMode.heatmap,
                onSelected: (sel) async {
                  if (!sel) return;
                  setState(() => _viewMode = CoverageViewMode.heatmap);
                  await _persistState();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Легенда
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    extra?.borderDefault ??
                    colorScheme.outline.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: _viewMode == CoverageViewMode.zones
                ? const Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _LegendDot(
                        color: Colors.green,
                        label: 'Стабільна зона (rx ≥ -80 dBm)',
                      ),
                      _LegendDot(
                        color: Colors.yellow,
                        label: 'Погіршене покриття',
                      ),
                      _LegendDot(
                        color: Colors.orange,
                        label: 'Граничне покриття',
                      ),
                      _LegendDot(color: Colors.red, label: 'Нижче порога'),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.red,
                              Colors.orange,
                              Colors.yellow,
                              Colors.green,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Heatmap рівня сигналу (від слабкого до сильного)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: mutedText,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),

          // Маленький "науковий" опис моделі
          Text(
            'Модель: узагальнена модель Хата з поправкою на середовище. '
            'L(d) = 69.55 + 26.16·log₁₀(f) − 13.82·log₁₀(hb) − a(hm) '
            '+ (44.9 − 6.55·log₁₀(hb))·log₁₀(d) + C_env.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: mutedText,
            ),
          ),
          const SizedBox(height: 12),

          // Мапа
          SizedBox(
            height: compact ? 300 : 380,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(centerLat, centerLon),
                  initialZoom: 11,
                  onTap: (tapPos, latLng) async {
                    setState(() {
                      _centerLatController.text = latLng.latitude
                          .toStringAsFixed(6);
                      _centerLonController.text = latLng.longitude
                          .toStringAsFixed(6);
                      if (_stations.isNotEmpty) {
                        _selectedStation.lat = latLng.latitude;
                        _selectedStation.lon = latLng.longitude;
                      }
                    });
                    await _persistState();

                    if (_stations.isNotEmpty) {
                      final st = _selectedStation;
                      if (st.lat != null && st.lon != null) {
                        final distKm = _distance.as(
                          LengthUnit.Kilometer,
                          LatLng(st.lat!, st.lon!),
                          latLng,
                        );

                        final rxHeightM =
                            double.tryParse(_rxHeightController.text.trim()) ??
                            1.5;
                        final txPowerDbmParsed = _txPowerController.text.trim();
                        final txPowerDbm =
                            double.tryParse(
                              txPowerDbmParsed.isEmpty
                                  ? st.txPowerDbm.toString()
                                  : txPowerDbmParsed,
                            ) ??
                            st.txPowerDbm;

                        final loss = _pathLoss(
                          freqMhz: st.frequencyMHz,
                          distanceKm: distKm,
                          hb: st.antennaHeightM,
                          hm: rxHeightM,
                        );

                        final gTx = st.antennaGainDb;
                        const gRx = 0.0;
                        final rxDbm = txPowerDbm + gTx + gRx - loss;
                        final marginDb = rxDbm - (-100.0);

                        if (!mounted) return;

                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) {
                            final t = Theme.of(ctx).textTheme;
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Аналіз точки', style: t.titleMedium),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Lat: ${latLng.latitude.toStringAsFixed(6)}, '
                                    'Lon: ${latLng.longitude.toStringAsFixed(6)}',
                                  ),
                                  Text(
                                    'Відстань до станції: ${distKm.toStringAsFixed(2)} км',
                                  ),
                                  Text(
                                    'Втрати шляху L(d): ${loss.toStringAsFixed(1)} дБ',
                                  ),
                                  Text('P_rx: ${rxDbm.toStringAsFixed(1)} dBm'),
                                  Text(
                                    'Запас по чутливості (від -100 dBm): '
                                    '${marginDb.toStringAsFixed(1)} дБ',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    marginDb >= 0
                                        ? 'Зона вважається придатною для стійкого звʼязку.'
                                        : 'Ймовірні провали звʼязку, сигнал нижче цільового порогу.',
                                    style: t.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.trunkops.app',
                    maxZoom: 18,
                    minZoom: 3,
                  ),
                  if (_coverage != null)
                    CircleLayer(
                      circles: _coverage!.cells.map((cell) {
                        final color = _viewMode == CoverageViewMode.zones
                            ? _classifiedColorForRx(cell.rxLevelDbm)
                            : _heatmapColorForRx(cell.rxLevelDbm);
                        final radius = _viewMode == CoverageViewMode.zones
                            ? (compact ? 6.0 : 8.0)
                            : (compact ? 10.0 : 14.0);
                        return CircleMarker(
                          point: LatLng(cell.lat, cell.lon),
                          radius: radius,
                          color: color,
                        );
                      }).toList(),
                    ),
                  if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
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
  final CoverageResponse? coverage;

  const _SideStatusPanel({this.coverage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final extra = theme.extension<AppExtraColors>();

    final mutedText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    double stablePercent = 0;
    double degradedPercent = 0;
    double weakPercent = 0;
    double nonePercent = 0;

    final cells = coverage?.cells ?? [];

    double? minRx;
    double? maxRx;
    double? medianRx;
    double? stableAreaKm2;
    double? totalAreaKm2;

    final stepM = coverage?.gridStepM;

    if (cells.isNotEmpty) {
      final levels = <double>[];
      int stable = 0;
      int degraded = 0;
      int weak = 0;
      int none = 0;

      for (final c in cells) {
        final rx = c.rxLevelDbm;
        levels.add(rx);
        if (rx >= -80) {
          stable++;
        } else if (rx >= -95) {
          degraded++;
        } else if (rx >= -110) {
          weak++;
        } else {
          none++;
        }

        minRx = (minRx == null) ? rx : (rx < minRx! ? rx : minRx);
        maxRx = (maxRx == null) ? rx : (rx > maxRx! ? rx : maxRx);
      }

      levels.sort();
      medianRx = levels[levels.length ~/ 2];

      final total = cells.length.toDouble();
      stablePercent = stable / total;
      degradedPercent = degraded / total;
      weakPercent = weak / total;
      nonePercent = none / total;

      if (stepM != null) {
        final cellAreaKm2 = (stepM * stepM) / 1e6;
        totalAreaKm2 = cellAreaKm2 * total;
        stableAreaKm2 = cellAreaKm2 * stable;
      }
    }

    final stableColor = extra?.success ?? colorScheme.primary;
    final degradedColor = extra?.warning ?? colorScheme.secondary;
    final weakColor = Colors.orange;
    final criticalColor = colorScheme.error;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 360;
          return Column(
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
              const SizedBox(height: 8),
              Text(
                coverage == null
                    ? 'Немає актуального розрахунку. Оберіть станцію та натисніть «Розрахувати».'
                    : 'Оцінка зони покриття для останнього розрахунку.',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: mutedText,
                ),
              ),
              const SizedBox(height: 12),
              _CoverageStatusRow(
                label: 'Стабільна зона',
                percent: stablePercent,
                color: stableColor,
              ),
              const SizedBox(height: 8),
              _CoverageStatusRow(
                label: 'Погіршене покриття',
                percent: degradedPercent,
                color: degradedColor,
              ),
              const SizedBox(height: 8),
              _CoverageStatusRow(
                label: 'Граничне покриття',
                percent: weakPercent,
                color: weakColor,
              ),
              const SizedBox(height: 8),
              _CoverageStatusRow(
                label: 'Критичні ділянки (нижче порога)',
                percent: nonePercent,
                color: criticalColor,
              ),
              const SizedBox(height: 16),
              if (minRx != null && maxRx != null && medianRx != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статистика сигналу',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Min: ${minRx!.toStringAsFixed(1)} dBm   '
                      'Median: ${medianRx!.toStringAsFixed(1)} dBm   '
                      'Max: ${maxRx!.toStringAsFixed(1)} dBm',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: narrow ? 10 : 11,
                        color: mutedText,
                      ),
                    ),
                    if (totalAreaKm2 != null && stableAreaKm2 != null)
                      Text(
                        'Площа стабільного покриття (≥ -80 dBm): '
                        '${stableAreaKm2!.toStringAsFixed(2)} км² '
                        'із ${totalAreaKm2!.toStringAsFixed(2)} км² сітки.',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: narrow ? 10 : 11,
                          color: mutedText,
                        ),
                      ),
                  ],
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
                name: 'Базові станції',
                status: stablePercent > 0.7 ? 'OK' : 'Warning',
                description: stablePercent > 0.7
                    ? 'Основні вузли забезпечують стійке покриття більшості зони.'
                    : 'Стабільне покриття нижче бажаного рівня, варто розглянути підсилення.',
                color: stableColor,
              ),
              const SizedBox(height: 8),
              _NodeStatusTile(
                name: 'Опорні пункти',
                status: degradedPercent > 0.15 || weakPercent > 0.15
                    ? 'Warning'
                    : 'OK',
                description:
                    'Частина зони має погіршене або граничне покриття, можливі провали звʼязку при русі.',
                color: degradedColor,
              ),
              const SizedBox(height: 8),
              _NodeStatusTile(
                name: 'Критичні ділянки',
                status: nonePercent > 0.05 ? 'Critical' : 'OK',
                description: nonePercent > 0.05
                    ? 'Є зони без гарантованого покриття — потрібне планування ретрансляторів.'
                    : 'Зони без покриття незначні або відсутні.',
                color: criticalColor,
              ),
            ],
          );
        },
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

    final clamped = percent.clamp(0.0, 1.0);

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
              '${(clamped * 100).round()}%',
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
            value: clamped,
            minHeight: 6,
            backgroundColor: colorScheme.surface.withOpacity(0.9),
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
        color: colorScheme.surface,
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

  const _SmallNumberField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Адаптивна ширина: трохи менша на мобілках
        final maxW = constraints.maxWidth;
        double fieldWidth;
        if (maxW < 360) {
          fieldWidth = 100;
        } else if (maxW < 600) {
          fieldWidth = 110;
        } else {
          fieldWidth = 120;
        }

        return SizedBox(
          width: fieldWidth,
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
      },
    );
  }
}
