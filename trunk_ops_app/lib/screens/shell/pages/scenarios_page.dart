// lib/screens/shell/pages/scenarios_page.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

class ScenariosPage extends StatefulWidget {
  const ScenariosPage({super.key});

  @override
  State<ScenariosPage> createState() => _ScenariosPageState();
}

class _ScenariosPageState extends State<ScenariosPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 700 ? 12.0 : 24.0;
        final verticalPadding = constraints.maxWidth < 700 ? 12.0 : 20.0;

        final screenHeight = MediaQuery.of(context).size.height;
        // робимо карту суттєво вищою
        final mapHeight = math.max(360.0, screenHeight * 0.58);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок сторінки
              Text(
                'Типові сценарії застосування транкінгового звʼязку батальйона',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Два базові сценарії роботи механізованого батальйона: в обороні та в наступі, '
                'із відображенням розподілу каналів транкінгового звʼязку та зон покриття.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color ??
                      colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),

              // ───────────────── СЦЕНАРІЙ 1. ОБОРОНА ─────────────────
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color:
                      extra?.surfaceSubtle ??
                      colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        extra?.borderDefault ??
                        colorScheme.outline.withOpacity(0.6),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: _DefenceScenarioSection(mapHeight: mapHeight),
              ),

              // ───────────────── СЦЕНАРІЙ 2. НАСТУП ─────────────────
              Container(
                decoration: BoxDecoration(
                  color:
                      extra?.surfaceSubtle ??
                      colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        extra?.borderDefault ??
                        colorScheme.outline.withOpacity(0.6),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: _OffenceScenarioSection(mapHeight: mapHeight),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// =================================================================
///                         СЦЕНАРІЙ 1 – ОБОРОНА
/// =================================================================

class _DefenceScenarioSection extends StatelessWidget {
  final double mapHeight;

  const _DefenceScenarioSection({required this.mapHeight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сценарій 1. Механізований батальйон в обороні',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Район м. Покровськ, Донецька область. Оборона механізованого батальйона '
          'проти умовного противника з боку рф у смузі відповідальності бригади.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color:
                theme.textTheme.bodySmall?.color ??
                colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),

        const _InputDataCard(),
        const SizedBox(height: 16),

        const _ChannelAllocationCard(),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  Theme.of(
                    context,
                  ).extension<AppExtraColors>()?.borderDefault ??
                  colorScheme.outline.withOpacity(0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Схема розташування підрозділів та базових станцій (оборона)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Механізований батальйон в обороні в районі Покровська. '
                'На карті відображені: ПУ батальйона, роти першого ешелону, резерв, '
                'взводні опорні пункти, базові станції транкінгового звʼязку та '
                'зони їх покриття для оцінки стійкості управління.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color ??
                      colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(height: mapHeight, child: const _DefenceScenarioMap()),
              const SizedBox(height: 8),
              const _MapLegend(),
            ],
          ),
        ),
      ],
    );
  }
}

/// ───────────────────── ВХІДНІ ДАНІ СЦЕНАРІЮ 1 ─────────────────────

class _InputDataCard extends StatelessWidget {
  const _InputDataCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final muted =
        theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Вхідні дані сценарію (оборона)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          const _BlockTitle(text: 'Район оборони батальйона'),
          const SizedBox(height: 4),
          Text(
            '• Оборона механізованого батальйона на рубежі західніше м. Покровськ, Донецька область.\n'
            '• Напрямок можливого наступу противника — зі сходу (умовно з боку рф).\n'
            '• Батальйон утримує опорний район у смузі відповідальності механізованої бригади.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),

          const _BlockTitle(text: 'Штатний склад батальйона (узагальнено)'),
          const SizedBox(height: 4),
          Text(
            '• Пункт управління батальйона (ПУ батальйона).\n'
            '• 1-ша механізована рота (перший ешелон, 3 механізовані взводи).\n'
            '• 2-га механізована рота (перший ешелон, 3 механізовані взводи).\n'
            '• 3-тя механізована рота (резерв / другий ешелон).\n'
            '• Підрозділи вогневої підтримки та забезпечення (мінометний взвод, ПТ-засоби, тил, медпункт).',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),

          const _BlockTitle(text: 'Структура транкінгового звʼязку батальйона'),
          const SizedBox(height: 4),
          Text(
            '• Бригадна базова станція (БС бригади) — розташована в тилу, забезпечує стійкий звʼязок '
            'між ПУ бригади та ПУ батальйона.\n'
            '• Базова станція батальйона (БС батальйона) — у районі ПУ батальйона, формує радіомережу батальйона.\n'
            '• Радіостанції у кожного командира роти, взводу, командира бойової машини, а також у ПУ та '
            'підрозділах вогневої підтримки.\n'
            '• Зони впевненого прийому для рухомих абонентів — не менше 5–7 км для БС батальйона, до 15 км для БС бригади.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),

          const _BlockTitle(text: 'Діапазон частот та канальний ресурс'),
          const SizedBox(height: 4),
          Text(
            '• Робочий діапазон (умовно): UHF 380–430 МГц – типовий діапазон для тактичних транкінгових систем.\n'
            '• БС бригади: Nбр = 8 логічних каналів (групових викликів).\n'
            '• БС батальйона: Nбн = 6 логічних каналів.\n'
            '• Канали розподіляються між групами абонентів за принципом talkgroup, '
            'з пріоритетом для ПУ батальйона та рот першого ешелону.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class _BlockTitle extends StatelessWidget {
  final String text;

  const _BlockTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }
}

/// ───────────────────── РОЗПОДІЛ КАНАЛІВ СЦЕНАРІЙ 1 ─────────────────────

class _ChannelAllocationCard extends StatelessWidget {
  const _ChannelAllocationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final muted =
        theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. Розподіл каналів транкінгового звʼязку батальйона (оборона)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Канальний ресурс БС батальйона та БС бригади розподіляється за групами абонентів '
            '(talkgroup), що забезпечує пріоритет командних ланок і мінімізує взаємні завади.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _ChannelPill(
                title: 'TG1 – Канал управління батальйона',
                description:
                    'ПУ батальйона, старші начальники, звʼязок із ПУ бригади. Обслуговується БС батальйона та БС бригади з найвищим пріоритетом.',
              ),
              _ChannelPill(
                title: 'TG2 – Канал 1-ї мехроти',
                description:
                    'Командир роти, КП взводів, опорні пункти. Пріоритетний канал для роти першого ешелону.',
              ),
              _ChannelPill(
                title: 'TG3 – Канал 2-ї мехроти',
                description: 'Аналогічно TG2, для другої роти першого ешелону.',
              ),
              _ChannelPill(
                title: 'TG4 – Канал 3-ї мехроти (резерв)',
                description:
                    'Резерв батальйона, маневрена група, підрозділи посилення.',
              ),
              _ChannelPill(
                title: 'TG5 – Канал вогневої підтримки',
                description:
                    'Мінометний взвод, ПТ-засоби, коригувальники вогню, старший офіцер батареї.',
              ),
              _ChannelPill(
                title: 'TG6 – Логістично-медичний канал',
                description:
                    'Медпункт, тил, підвезення боєприпасів, евакуація поранених.',
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            'На мапі колір маркерів і зон покриття повʼязаний із talkgroup: роти першого ешелону – один колір, '
            'резерв – інший, БС батальйона / бригади – окремі кольори. Це дозволяє наочно показати, '
            'які підрозділи працюють у спільному каналі, а які – в окремих.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class _ChannelPill extends StatelessWidget {
  final String title;
  final String description;

  const _ChannelPill({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final muted =
        theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: extra?.surfaceElevated ?? colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────── МАПА СЦЕНАРІЮ ОБОРОНИ ─────────────────────

class _RadioStation {
  final String id;
  final String name;
  final LatLng position;
  final double radiusKm;
  final Color baseColor;
  final String role; // ПУ батальйона, КП роти, КП взводу, БС тощо
  final String talkGroup; // TG1, TG2...

  const _RadioStation({
    required this.id,
    required this.name,
    required this.position,
    required this.radiusKm,
    required this.baseColor,
    required this.role,
    required this.talkGroup,
  });
}

class _DefenceScenarioMap extends StatefulWidget {
  const _DefenceScenarioMap();

  @override
  State<_DefenceScenarioMap> createState() => _DefenceScenarioMapState();
}

class _DefenceScenarioMapState extends State<_DefenceScenarioMap> {
  // Центр району Покровська
  LatLng get _center => const LatLng(48.2800, 37.1700);

  // обрана станція для детального покриття (по кліку)
  String? _selectedStationId;

  List<_RadioStation> get _stations {
    final c = _center;

    LatLng offset(double dLat, double dLon) =>
        LatLng(c.latitude + dLat, c.longitude + dLon);

    // Базові станції
    final brigadeBs = _RadioStation(
      id: 'brigade_bs',
      name: 'БС бригади',
      position: offset(-0.08, -0.10),
      radiusKm: 15,
      baseColor: Colors.blueAccent,
      role: 'Базова станція бригади',
      talkGroup: 'TG1 / резерв TG5–TG6',
    );

    final bnBs = _RadioStation(
      id: 'bn_bs',
      name: 'БС батальйона',
      position: offset(-0.01, -0.02),
      radiusKm: 8,
      baseColor: Colors.green,
      role: 'Базова станція батальйона',
      talkGroup: 'TG1–TG4',
    );

    // ПУ батальйона
    final bnCp = _RadioStation(
      id: 'bn_cp',
      name: 'ПУ батальйона',
      position: c,
      radiusKm: 4,
      baseColor: Colors.orangeAccent,
      role: 'Пункт управління батальйона',
      talkGroup: 'TG1',
    );

    // 1-а мехрота: КП роти + взводи
    final coy1Cp = _RadioStation(
      id: 'coy1_cp',
      name: 'КП 1-ї мехроти',
      position: offset(0.015, -0.03),
      radiusKm: 3.5,
      baseColor: Colors.teal,
      role: 'КП роти першого ешелону',
      talkGroup: 'TG2',
    );
    final coy1Pl1 = _RadioStation(
      id: 'coy1_pl1',
      name: '1-й взвод 1-ї роти',
      position: offset(0.020, -0.020),
      radiusKm: 2.0,
      baseColor: Colors.tealAccent.shade400,
      role: 'Опорний пункт взводу',
      talkGroup: 'TG2',
    );
    final coy1Pl2 = _RadioStation(
      id: 'coy1_pl2',
      name: '2-й взвод 1-ї роти',
      position: offset(0.010, -0.040),
      radiusKm: 2.0,
      baseColor: Colors.tealAccent.shade400,
      role: 'Опорний пункт взводу',
      talkGroup: 'TG2',
    );
    final coy1Pl3 = _RadioStation(
      id: 'coy1_pl3',
      name: '3-й взвод 1-ї роти',
      position: offset(0.024, -0.050),
      radiusKm: 2.0,
      baseColor: Colors.tealAccent.shade400,
      role: 'Опорний пункт взводу',
      talkGroup: 'TG2',
    );

    // 2-а мехрота
    final coy2Cp = _RadioStation(
      id: 'coy2_cp',
      name: 'КП 2-ї мехроти',
      position: offset(-0.005, -0.04),
      radiusKm: 3.5,
      baseColor: Colors.lightBlue,
      role: 'КП роти першого ешелону',
      talkGroup: 'TG3',
    );
    final coy2Pl1 = _RadioStation(
      id: 'coy2_pl1',
      name: '1-й взвод 2-ї роти',
      position: offset(-0.002, -0.020),
      radiusKm: 2.0,
      baseColor: Colors.lightBlueAccent,
      role: 'Опорний пункт взводу',
      talkGroup: 'TG3',
    );
    final coy2Pl2 = _RadioStation(
      id: 'coy2_pl2',
      name: '2-й взвод 2-ї роти',
      position: offset(-0.012, -0.060),
      radiusKm: 2.0,
      baseColor: Colors.lightBlueAccent,
      role: 'Опорний пункт взводу',
      talkGroup: 'TG3',
    );
    final coy2Pl3 = _RadioStation(
      id: 'coy2_pl3',
      name: '3-й взвод 2-ї роти',
      position: offset(-0.020, -0.040),
      radiusKm: 2.0,
      baseColor: Colors.lightBlueAccent,
      role: 'Опорний пункт взводу',
      talkGroup: 'TG3',
    );

    // 3-я мехрота (резерв)
    final coy3Cp = _RadioStation(
      id: 'coy3_cp',
      name: 'КП 3-ї мехроти (резерв)',
      position: offset(-0.030, -0.025),
      radiusKm: 3.0,
      baseColor: Colors.amber,
      role: 'КП роти резерву',
      talkGroup: 'TG4',
    );

    // Вогнева підтримка
    final fireSupport = _RadioStation(
      id: 'fire_support',
      name: 'Мінометний взвод / вогнева підтримка',
      position: offset(-0.020, -0.080),
      radiusKm: 4.0,
      baseColor: Colors.deepPurple,
      role: 'Підрозділ вогневої підтримки',
      talkGroup: 'TG5',
    );

    // Логістика/медпункт
    final logistics = _RadioStation(
      id: 'logistics',
      name: 'Тил / медпункт батальйона',
      position: offset(-0.050, -0.060),
      radiusKm: 3.0,
      baseColor: Colors.brown,
      role: 'Логістика, медпункт',
      talkGroup: 'TG6',
    );

    return [
      brigadeBs,
      bnBs,
      bnCp,
      coy1Cp,
      coy1Pl1,
      coy1Pl2,
      coy1Pl3,
      coy2Cp,
      coy2Pl1,
      coy2Pl2,
      coy2Pl3,
      coy3Cp,
      fireSupport,
      logistics,
    ];
  }

  List<LatLng> _buildCircle(LatLng center, double radiusKm) {
    final radiusM = radiusKm * 1000.0;
    final latRad = center.latitude * math.pi / 180.0;
    final cosLat = math.cos(latRad);
    const segments = 72;
    final points = <LatLng>[];

    for (int i = 0; i < segments; i++) {
      final ang = 2 * math.pi * i / segments;
      final dx = radiusM * math.cos(ang);
      final dy = radiusM * math.sin(ang);
      final dLat = dy / 111320.0;
      final dLon = dx / (111320.0 * math.max(cosLat, 0.1));
      points.add(LatLng(center.latitude + dLat, center.longitude + dLon));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stations = _stations;
    final selectedStation = _selectedStationId != null
        ? stations.firstWhere(
            (s) => s.id == _selectedStationId,
            orElse: () => stations.first,
          )
        : null;

    // Напрямок противника зі сходу
    LatLng offsetCenter(double dLat, double dLon) =>
        LatLng(_center.latitude + dLat, _center.longitude + dLon);

    final enemyStart = offsetCenter(0.0, 0.14);
    final enemyMid = offsetCenter(0.0, 0.07);

    // Базові полігони покриття (всі станції, слабка прозорість)
    final polygons = <Polygon>[];

    for (final st in stations) {
      polygons.add(
        Polygon(
          points: _buildCircle(st.position, st.radiusKm),
          color: st.baseColor.withOpacity(0.035),
          borderColor: st.baseColor.withOpacity(0.6),
          borderStrokeWidth: 1.0,
        ),
      );
    }

    // Якщо вибрана станція — додаємо поверх більш виразну зону
    if (selectedStation != null && _selectedStationId != null) {
      polygons.add(
        Polygon(
          points: _buildCircle(
            selectedStation.position,
            selectedStation.radiusKm,
          ),
          color: selectedStation.baseColor.withOpacity(0.12),
          borderColor: selectedStation.baseColor.withOpacity(0.95),
          borderStrokeWidth: 2.4,
        ),
      );
    }

    // Лінія наступу противника
    final enemyPolyline = Polyline(
      points: [enemyStart, enemyMid, _center],
      strokeWidth: 3,
      color: Colors.redAccent,
    );

    // Маркери станцій + противник
    final markers = <Marker>[
      // Маркер умовного противника
      Marker(
        point: enemyStart,
        width: 36,
        height: 36,
        child: Tooltip(
          message: 'Умовний противник (напрямок наступу зі сходу)',
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
      // Усі радіостанції батальйона
      ...stations.map(
        (st) => _buildStationMarker(
          context: context,
          station: st,
          isSelected: _selectedStationId == st.id,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Пояснення + коротка інфа по обраній станції
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Натисніть на станцію, щоб побачити її окрему зону покриття та параметри.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color ??
                      colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (selectedStation != null && _selectedStationId != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.96),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selectedStation.baseColor.withOpacity(0.9),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: selectedStation.baseColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${selectedStation.name} • ${selectedStation.role} • '
                    '${selectedStation.talkGroup} • '
                    'R ≈ ${selectedStation.radiusKm.toStringAsFixed(1)} км',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStationId = null;
                    });
                  },
                  child: const Text('Очистити'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 11.5,
                maxZoom: 16,
                minZoom: 7,
                onTap: (_, __) {
                  // клік по карті – зняти виділення
                  if (_selectedStationId != null) {
                    setState(() => _selectedStationId = null);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.trunkops.app',
                ),
                PolygonLayer(polygons: polygons),
                PolylineLayer(polylines: [enemyPolyline]),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Marker _buildStationMarker({
    required BuildContext context,
    required _RadioStation station,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = station.baseColor;
    final borderColor = isSelected
        ? Colors.white
        : Colors.black.withOpacity(0.45);
    final size = isSelected ? 40.0 : 32.0;

    return Marker(
      point: station.position,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_selectedStationId == station.id) {
              _selectedStationId = null;
            } else {
              _selectedStationId = station.id;
            }
          });
        },
        child: Tooltip(
          message:
              '${station.name}\n'
              '${station.role}\n'
              'Talkgroup: ${station.talkGroup}\n'
              'Радіус покриття ≈ ${station.radiusKm.toStringAsFixed(1)} км',
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: bg.withOpacity(0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _iconForRole(station.role),
              size: isSelected ? 20 : 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForRole(String role) {
    if (role.contains('батальйона')) return Icons.flag;
    if (role.contains('Базова станція')) return Icons.cell_tower;
    if (role.contains('роти')) return Icons.shield_outlined;
    if (role.contains('взвод')) return Icons.shield;
    if (role.contains('вогневої')) return Icons.local_fire_department;
    if (role.contains('Логістика') || role.contains('медпункт')) {
      return Icons.local_hospital;
    }
    return Icons.radio;
  }
}

/// ───────────────────── ЛЕГЕНДА ДЛЯ МАПИ (СПІЛЬНА) ─────────────────────

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final muted =
        theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: extra?.surfaceElevated ?? colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _legendItem(
                context,
                color: Colors.green,
                label:
                    'БС батальйона – основна зона управління батальйона (TG1–TG4)',
              ),
              _legendItem(
                context,
                color: Colors.blueAccent,
                label: 'БС бригади – тилова/резервна зона (TG1, TG5–TG6)',
              ),
              _legendItem(
                context,
                color: Colors.teal,
                label: 'КП та взводи 1-ї мехроти (TG2)',
              ),
              _legendItem(
                context,
                color: Colors.lightBlue,
                label: 'КП та взводи 2-ї мехроти (TG3)',
              ),
              _legendItem(
                context,
                color: Colors.amber,
                label: 'КП 3-ї мехроти (резерв, TG4)',
              ),
              _legendItem(
                context,
                color: Colors.deepPurple,
                label: 'Вогнева підтримка (TG5)',
              ),
              _legendItem(
                context,
                color: Colors.brown,
                label: 'Логістика та медпункт (TG6)',
              ),
              _legendItem(
                context,
                color: Colors.redAccent,
                label: 'Напрямок наступу умовного противника',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'При натисканні на станцію її зона покриття підсвічується, що дозволяє оцінити, '
            'які підрозділи гарантовано потрапляють у діапазон дії саме цієї базової або рухомої станції, '
            'а також як накладаються зони покриття в масштабі всього батальйона.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    BuildContext context, {
    required Color color,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final textColor =
        theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.8);

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
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

/// =================================================================
///                         СЦЕНАРІЙ 2 – НАСТУП
/// =================================================================

class _OffenceScenarioSection extends StatelessWidget {
  final double mapHeight;

  const _OffenceScenarioSection({required this.mapHeight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сценарій 2. Механізований батальйон в наступі',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Наступ механізованого батальйона в районі м. Покровськ з заходу на схід у напрямку рубежів противника. '
          'Показано організацію транкінгового звʼязку в умовах маневру та розгортання бойових порядків.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color:
                theme.textTheme.bodySmall?.color ??
                colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),

        const _OffenceInputDataCard(),
        const SizedBox(height: 16),

        const _OffenceChannelAllocationCard(),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  Theme.of(
                    context,
                  ).extension<AppExtraColors>()?.borderDefault ??
                  colorScheme.outline.withOpacity(0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Схема наступу батальйона та зон покриття (наступ)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Батальйон розгортається в передбойовий, а далі в бойовий порядок, виконуючи наступ на противника '
                'в напрямку східніше Покровська. На мапі показані стартові рубежі, рубіж переходу в атаку, '
                'напрямок удару, розміщення БС бригади, БС батальйона, КП рот, взводні ланки та їх зони покриття.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color ??
                      colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(height: mapHeight, child: const _OffenceScenarioMap()),
              const SizedBox(height: 8),
              const _OffenceMapLegend(),
            ],
          ),
        ),
      ],
    );
  }
}

/// ───────────────────── ВХІДНІ ДАНІ СЦЕНАРІЮ 2 ─────────────────────

class _OffenceInputDataCard extends StatelessWidget {
  const _OffenceInputDataCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final muted =
        theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Вхідні дані сценарію (наступ)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          const _BlockTitle(text: 'Бойове завдання батальйона'),
          const SizedBox(height: 4),
          Text(
            '• Механізований батальйон діє у складі переднього ешелону бригади.\n'
            '• Завдання батальйона: прорвати оборону противника на передньому краї, '
            'оволодіти опорним пунктом противника східніше Покровська та розвинути успіх у глибину.\n'
            '• Напрямок головного удару – зі заходу на схід у смузі відповідальності батальйона.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),

          const _BlockTitle(text: 'Бойовий порядок батальйона в наступі'),
          const SizedBox(height: 4),
          Text(
            '• 1-ша і 2-га механізовані роти – перший ешелон, розгорнуті в лінію батальйонного фронту.\n'
            '• 3-тя механізована рота – другий ешелон/резерв, готова до введення в бій на напрямку успіху.\n'
            '• Підрозділи вогневої підтримки – на вогневих позиціях у другому ешелоні.\n'
            '• ПУ батальйона – у районі вихідного положення, з можливістю висування передового КП ближче до рубежу атаки.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),

          const _BlockTitle(
            text: 'Особливості організації транкінгового звʼязку в наступі',
          ),
          const SizedBox(height: 4),
          Text(
            '• Потрібно забезпечити стійкий звʼязок при русі підрозділів: від вихідного положення до рубежу переходу в атаку та в глибині оборони противника.\n'
            '• БС бригади забезпечує звʼязок із ПУ бригади, БС батальйона – основний обсяг трафіку між ПУ батальйона, ротами та взводами.\n'
            '• Передовий КП батальйона (ПКП) може мати окремий радіоканал/пріоритетну talkgroup для керування боєм у зоні прориву.\n'
            '• Від роти до взводу зберігається структура talkgroup, але з урахуванням маневру та можливого виходу окремих взводів уперед.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────── РОЗПОДІЛ КАНАЛІВ СЦЕНАРІЙ 2 ─────────────────────

class _OffenceChannelAllocationCard extends StatelessWidget {
  const _OffenceChannelAllocationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final muted =
        theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. Розподіл каналів транкінгового звʼязку батальйона (наступ)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'У наступі додатково враховується потреба передового КП, розвідувальних/ударних груп та управління резервом. '
            'Тому розподіл каналів має забезпечувати як фронтальний наступ, так і швидке введення в бій другого ешелону.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _ChannelPill(
                title: 'TG1 – Канал управління батальйона (ПУ + ПКП)',
                description:
                    'ПУ батальйона, передовий КП, старші начальники, звʼязок із ПУ бригади. Найвищий пріоритет при розподілі ресурсів БС.',
              ),
              _ChannelPill(
                title: 'TG2 – Канал 1-ї мехроти (напрямок головного удару)',
                description:
                    'Командир роти, взводи першого ешелону, бойові машини роти на головному напрямку наступу.',
              ),
              _ChannelPill(
                title: 'TG3 – Канал 2-ї мехроти',
                description:
                    'Другий напрямок наступу батальйона, взаємодія із сусідами по фронту.',
              ),
              _ChannelPill(
                title: 'TG4 – Канал 3-ї мехроти (другий ешелон / резерв)',
                description:
                    'Резерв батальйона, маневр силами у прорив, розвиток успіху в глибину.',
              ),
              _ChannelPill(
                title: 'TG5 – Канал вогневої підтримки (міномети, артилерія)',
                description:
                    'Керування вогнем підтримки наступу: міномети, ПТ-засоби, коригувальники вогню, взаємодія із старшим артилерійським начальником.',
              ),
              _ChannelPill(
                title: 'TG6 – Канал забезпечення наступу',
                description:
                    'Тилові підрозділи, медична евакуація, підвезення боєприпасів і пального, евакуація пошкодженої техніки.',
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            'У сценарії наступу на мапі виділено окремі зони покриття для підрозділів головного удару, резерву, '
            'вогневої підтримки та тилу, що дозволяє візуально оцінити, де потрібне підсилення зон покриття або зміна '
            'розташування БС батальйона.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

/// ───────────────────── МАПА СЦЕНАРІЮ НАСТУПУ ─────────────────────

class _OffenceScenarioMap extends StatefulWidget {
  const _OffenceScenarioMap();

  @override
  State<_OffenceScenarioMap> createState() => _OffenceScenarioMapState();
}

class _OffenceScenarioMapState extends State<_OffenceScenarioMap> {
  // Центр району наступу (трохи західніше Покровська)
  LatLng get _center => const LatLng(48.2800, 37.1300);

  String? _selectedStationId;

  List<_RadioStation> get _stations {
    final c = _center;

    LatLng offset(double dLat, double dLon) =>
        LatLng(c.latitude + dLat, c.longitude + dLon);

    // БС бригади – у глибині власних порядків, ще західніше
    final brigadeBs = _RadioStation(
      id: 'brigade_bs_off',
      name: 'БС бригади (наступ)',
      position: offset(0.0, -0.14),
      radiusKm: 15,
      baseColor: Colors.blueAccent,
      role: 'Базова станція бригади',
      talkGroup: 'TG1 / TG5–TG6',
    );

    // БС батальйона – ближче до рубежу переходу в атаку
    final bnBs = _RadioStation(
      id: 'bn_bs_off',
      name: 'БС батальйона (наступ)',
      position: offset(0.0, -0.04),
      radiusKm: 8,
      baseColor: Colors.green,
      role: 'Базова станція батальйона',
      talkGroup: 'TG1–TG4',
    );

    // ПУ батальйона (вихідне положення)
    final bnCp = _RadioStation(
      id: 'bn_cp_off',
      name: 'ПУ батальйона (вихідне положення)',
      position: offset(-0.01, -0.06),
      radiusKm: 4.0,
      baseColor: Colors.orangeAccent,
      role: 'Пункт управління батальйона',
      talkGroup: 'TG1',
    );

    // Передовий КП батальйона (ПКП)
    final bnFwdCp = _RadioStation(
      id: 'bn_fwd_cp_off',
      name: 'Передовий КП батальйона',
      position: offset(0.0, 0.0),
      radiusKm: 4.0,
      baseColor: Colors.deepOrange,
      role: 'Передовий КП батальйона',
      talkGroup: 'TG1 (польовий підканал)',
    );

    // 1-а мехрота – головний удар
    final coy1Cp = _RadioStation(
      id: 'coy1_cp_off',
      name: 'КП 1-ї мехроти (головний удар)',
      position: offset(0.01, 0.02),
      radiusKm: 3.5,
      baseColor: Colors.teal,
      role: 'КП роти головного удару',
      talkGroup: 'TG2',
    );
    final coy1Pl1 = _RadioStation(
      id: 'coy1_pl1_off',
      name: '1-й взвод 1-ї роти (ліва ділянка)',
      position: offset(0.012, -0.01),
      radiusKm: 2.0,
      baseColor: Colors.tealAccent.shade400,
      role: 'Ударний взвод ліворуч',
      talkGroup: 'TG2',
    );
    final coy1Pl2 = _RadioStation(
      id: 'coy1_pl2_off',
      name: '2-й взвод 1-ї роти (центр)',
      position: offset(0.016, 0.02),
      radiusKm: 2.0,
      baseColor: Colors.tealAccent.shade400,
      role: 'Ударний взвод центр',
      talkGroup: 'TG2',
    );
    final coy1Pl3 = _RadioStation(
      id: 'coy1_pl3_off',
      name: '3-й взвод 1-ї роти (права ділянка)',
      position: offset(0.012, 0.045),
      radiusKm: 2.0,
      baseColor: Colors.tealAccent.shade400,
      role: 'Ударний взвод праворуч',
      talkGroup: 'TG2',
    );

    // 2-а мехрота – другий напрямок наступу
    final coy2Cp = _RadioStation(
      id: 'coy2_cp_off',
      name: 'КП 2-ї мехроти',
      position: offset(-0.01, 0.02),
      radiusKm: 3.5,
      baseColor: Colors.lightBlue,
      role: 'КП роти другого напрямку',
      talkGroup: 'TG3',
    );
    final coy2Pl1 = _RadioStation(
      id: 'coy2_pl1_off',
      name: '1-й взвод 2-ї роти',
      position: offset(-0.010, -0.01),
      radiusKm: 2.0,
      baseColor: Colors.lightBlueAccent,
      role: 'Взвод лівого крила',
      talkGroup: 'TG3',
    );
    final coy2Pl2 = _RadioStation(
      id: 'coy2_pl2_off',
      name: '2-й взвод 2-ї роти',
      position: offset(-0.016, 0.02),
      radiusKm: 2.0,
      baseColor: Colors.lightBlueAccent,
      role: 'Взвод центру другого напрямку',
      talkGroup: 'TG3',
    );
    final coy2Pl3 = _RadioStation(
      id: 'coy2_pl3_off',
      name: '3-й взвод 2-ї роти',
      position: offset(-0.012, 0.045),
      radiusKm: 2.0,
      baseColor: Colors.lightBlueAccent,
      role: 'Взвод правого крила другого напрямку',
      talkGroup: 'TG3',
    );

    // 3-я мехрота – другий ешелон/резерв
    final coy3Cp = _RadioStation(
      id: 'coy3_cp_off',
      name: 'КП 3-ї мехроти (другий ешелон)',
      position: offset(-0.030, -0.02),
      radiusKm: 3.0,
      baseColor: Colors.amber,
      role: 'КП роти другого ешелону',
      talkGroup: 'TG4',
    );

    // Вогнева підтримка – позаду бойового порядку
    final fireSupport = _RadioStation(
      id: 'fire_support_off',
      name: 'Мінометний взвод / вогнева підтримка',
      position: offset(-0.035, -0.055),
      radiusKm: 4.5,
      baseColor: Colors.deepPurple,
      role: 'Підрозділ вогневої підтримки наступу',
      talkGroup: 'TG5',
    );

    // Тил/медпункт – ще далі в тилу
    final logistics = _RadioStation(
      id: 'logistics_off',
      name: 'Тил / медпункт батальйона',
      position: offset(-0.055, -0.080),
      radiusKm: 3.5,
      baseColor: Colors.brown,
      role: 'Забезпечення наступу, медпункт',
      talkGroup: 'TG6',
    );

    return [
      brigadeBs,
      bnBs,
      bnCp,
      bnFwdCp,
      coy1Cp,
      coy1Pl1,
      coy1Pl2,
      coy1Pl3,
      coy2Cp,
      coy2Pl1,
      coy2Pl2,
      coy2Pl3,
      coy3Cp,
      fireSupport,
      logistics,
    ];
  }

  List<LatLng> _buildCircle(LatLng center, double radiusKm) {
    final radiusM = radiusKm * 1000.0;
    final latRad = center.latitude * math.pi / 180.0;
    final cosLat = math.cos(latRad);
    const segments = 72;
    final points = <LatLng>[];

    for (int i = 0; i < segments; i++) {
      final ang = 2 * math.pi * i / segments;
      final dx = radiusM * math.cos(ang);
      final dy = radiusM * math.sin(ang);
      final dLat = dy / 111320.0;
      final dLon = dx / (111320.0 * math.max(cosLat, 0.1));
      points.add(LatLng(center.latitude + dLat, center.longitude + dLon));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stations = _stations;
    final selectedStation = _selectedStationId != null
        ? stations.firstWhere(
            (s) => s.id == _selectedStationId,
            orElse: () => stations.first,
          )
        : null;

    LatLng offsetCenter(double dLat, double dLon) =>
        LatLng(_center.latitude + dLat, _center.longitude + dLon);

    // Рубежі наступу: вихідне положення -> рубіж атаки -> рубіж розвитку успіху
    final startLine = [offsetCenter(-0.02, -0.06), offsetCenter(0.02, -0.06)];
    final attackLine = [offsetCenter(-0.02, 0.02), offsetCenter(0.02, 0.02)];
    final exploitationLine = [
      offsetCenter(-0.02, 0.08),
      offsetCenter(0.02, 0.08),
    ];

    // Умовний противник – на східному рубежі
    final enemyLine = [offsetCenter(-0.02, 0.11), offsetCenter(0.02, 0.11)];
    final enemyCenter = offsetCenter(0.0, 0.11);

    // Полігони покриття (усі станції)
    final polygons = <Polygon>[];
    for (final st in stations) {
      polygons.add(
        Polygon(
          points: _buildCircle(st.position, st.radiusKm),
          color: st.baseColor.withOpacity(0.035),
          borderColor: st.baseColor.withOpacity(0.6),
          borderStrokeWidth: 1.0,
        ),
      );
    }

    // Обрана станція – підсвічена зона
    if (selectedStation != null && _selectedStationId != null) {
      polygons.add(
        Polygon(
          points: _buildCircle(
            selectedStation.position,
            selectedStation.radiusKm,
          ),
          color: selectedStation.baseColor.withOpacity(0.12),
          borderColor: selectedStation.baseColor.withOpacity(0.95),
          borderStrokeWidth: 2.4,
        ),
      );
    }

    // Полілінії рубежів та напрямку удару
    final polylines = <Polyline>[
      Polyline(points: startLine, strokeWidth: 2, color: Colors.grey.shade500),
      Polyline(
        points: attackLine,
        strokeWidth: 2,
        color: Colors.orangeAccent.shade200,
      ),
      Polyline(
        points: exploitationLine,
        strokeWidth: 2,
        color: Colors.greenAccent.shade400,
      ),
      Polyline(points: enemyLine, strokeWidth: 3, color: Colors.redAccent),
      // Напрямок головного удару стрілкою
      Polyline(
        points: [
          offsetCenter(0.0, -0.06),
          offsetCenter(0.0, 0.02),
          offsetCenter(0.0, 0.08),
        ],
        strokeWidth: 3,
        color: Colors.orangeAccent,
      ),
    ];

    // Маркери станцій + умовний противник
    final markers = <Marker>[
      Marker(
        point: enemyCenter,
        width: 36,
        height: 36,
        child: Tooltip(
          message: 'Передній край противника / опорний пункт',
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.shield, size: 18, color: Colors.white),
          ),
        ),
      ),
      ...stations.map(
        (st) => _buildStationMarker(
          context: context,
          station: st,
          isSelected: _selectedStationId == st.id,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Натисніть на станцію, щоб побачити її зону покриття в наступі та роль у бойовому порядку.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color ??
                      colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (selectedStation != null && _selectedStationId != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.96),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selectedStation.baseColor.withOpacity(0.9),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: selectedStation.baseColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${selectedStation.name} • ${selectedStation.role} • '
                    '${selectedStation.talkGroup} • '
                    'R ≈ ${selectedStation.radiusKm.toStringAsFixed(1)} км',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStationId = null;
                    });
                  },
                  child: const Text('Очистити'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 11.6,
                maxZoom: 16,
                minZoom: 7,
                onTap: (_, __) {
                  if (_selectedStationId != null) {
                    setState(() => _selectedStationId = null);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.trunkops.app',
                ),
                PolygonLayer(polygons: polygons),
                PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Marker _buildStationMarker({
    required BuildContext context,
    required _RadioStation station,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = station.baseColor;
    final borderColor = isSelected
        ? Colors.white
        : Colors.black.withOpacity(0.45);
    final size = isSelected ? 40.0 : 32.0;

    return Marker(
      point: station.position,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_selectedStationId == station.id) {
              _selectedStationId = null;
            } else {
              _selectedStationId = station.id;
            }
          });
        },
        child: Tooltip(
          message:
              '${station.name}\n'
              '${station.role}\n'
              'Talkgroup: ${station.talkGroup}\n'
              'Радіус покриття ≈ ${station.radiusKm.toStringAsFixed(1)} км',
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: bg.withOpacity(0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _iconForRole(station.role),
              size: isSelected ? 20 : 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForRole(String role) {
    if (role.contains('Передовий КП')) return Icons.flag_circle;
    if (role.contains('ПУ батальйона')) return Icons.flag;
    if (role.contains('Базова станція')) return Icons.cell_tower;
    if (role.contains('головного удару')) return Icons.shield_outlined;
    if (role.contains('Взвод') ||
        role.contains('взвод') ||
        role.contains('Ударний')) {
      return Icons.shield;
    }
    if (role.contains('вогневої')) return Icons.local_fire_department;
    if (role.contains('Забезпечення') || role.contains('медпункт')) {
      return Icons.local_hospital;
    }
    return Icons.radio;
  }
}

/// ───────────────────── ЛЕГЕНДА ДЛЯ МАПИ НАСТУПУ ─────────────────────

class _OffenceMapLegend extends StatelessWidget {
  const _OffenceMapLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final muted =
        theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: extra?.surfaceElevated ?? colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _legendItem(
                context,
                color: Colors.green,
                label:
                    'БС батальйона – основний вузол звʼязку наступу (TG1–TG4)',
              ),
              _legendItem(
                context,
                color: Colors.blueAccent,
                label:
                    'БС бригади – глибинне управління (звʼязок з ПУ бригади)',
              ),
              _legendItem(
                context,
                color: Colors.deepOrange,
                label: 'Передовий КП батальйона (ПКП)',
              ),
              _legendItem(
                context,
                color: Colors.teal,
                label: '1-ша мехрота – головний удар (TG2)',
              ),
              _legendItem(
                context,
                color: Colors.lightBlue,
                label: '2-га мехрота – другий напрямок наступу (TG3)',
              ),
              _legendItem(
                context,
                color: Colors.amber,
                label: '3-тя мехрота – другий ешелон/резерв (TG4)',
              ),
              _legendItem(
                context,
                color: Colors.deepPurple,
                label: 'Вогнева підтримка наступу (TG5)',
              ),
              _legendItem(
                context,
                color: Colors.brown,
                label: 'Тил та медичне забезпечення (TG6)',
              ),
              _legendItem(
                context,
                color: Colors.orangeAccent,
                label: 'Напрямок головного удару батальйона',
              ),
              _legendItem(
                context,
                color: Colors.redAccent,
                label: 'Передній край противника / опорний пункт',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Сукупність зон покриття дає змогу оцінити, чи забезпечено гарантований звʼязок '
            'на всіх рубежах наступу – від вихідного положення до рубежу розвитку успіху, '
            'а також чи не виникають «провали» в управлінні при висуванні ПКП та введенні в бій резерву.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    BuildContext context, {
    required Color color,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final textColor =
        theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.8);

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
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
