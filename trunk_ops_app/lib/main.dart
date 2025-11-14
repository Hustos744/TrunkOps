import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login/login_screen.dart';
import 'screens/shell/dashboard_shell_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Закріплюємо орієнтацію екрана в альбомному режимі
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const TrunkOpsApp());
}

/// Кореневий віджет додатка. Він Stateful, щоб можна було
/// змінювати тему в режимі роботи та зберігати вибір.
class TrunkOpsApp extends StatefulWidget {
  const TrunkOpsApp({super.key});

  @override
  State<TrunkOpsApp> createState() => TrunkOpsAppState();
}

/// Стан TrunkOpsApp, де зберігається поточний вибір теми.
class TrunkOpsAppState extends State<TrunkOpsApp> {
  // Поточний режим теми. За замовчуванням темна тема.
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  @override
  void initState() {
    super.initState();
    // Завантажуємо збережену тему при запуску
    _loadThemeMode();
  }

  /// Зчитує збережене значення теми з SharedPreferences
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    setState(() {
      _themeMode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    });
  }

  /// Зміна теми та збереження вибору. Викликайте цей метод із налаштувань.
  Future<void> setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  /// Дозволяє знайти цей state у дереві віджетів
  static TrunkOpsAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<TrunkOpsAppState>();
  }

  // Стиль для системних панелей (статусбар та навбар)
  static const _systemBarsStyle = SystemUiOverlayStyle(
    statusBarColor: Color(0xFF1B201B), // верхня панель (час/заряд)
    statusBarIconBrightness: Brightness.light, // світлі іконки
    systemNavigationBarColor: Color(0xFF1B201B), // нижня панель (кнопки)
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemBarsStyle,
      child: MaterialApp(
        title: 'TRUNKOPS',
        debugShowCheckedModeBanner: false,
        // Передаємо світлу та темну тему з app_colors.dart
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        // Використовуємо _themeMode, щоб перемикати теми динамічно
        themeMode: _themeMode,
        initialRoute: LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          DashboardShellScreen.routeName: (_) => const DashboardShellScreen(),
        },
      ),
    );
  }
}
