import 'package:flutter/material.dart';

@immutable
class AppExtraColors extends ThemeExtension<AppExtraColors> {
  final Color success;
  final Color warning;
  final Color info;

  final Color borderDefault;
  final Color borderLight;

  /// Додаткові акценти
  final Color accent; // для виділення, активних елементів
  final Color accentSoft; // мʼякий фон виділення / hover

  /// Додаткові поверхні
  final Color surfaceSubtle; // трохи відрізняється від основного фону
  final Color surfaceElevated; // для "піднятих" панелей / карток

  const AppExtraColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.borderDefault,
    required this.borderLight,
    required this.accent,
    required this.accentSoft,
    required this.surfaceSubtle,
    required this.surfaceElevated,
  });

  @override
  AppExtraColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? borderDefault,
    Color? borderLight,
    Color? accent,
    Color? accentSoft,
    Color? surfaceSubtle,
    Color? surfaceElevated,
  }) {
    return AppExtraColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      borderDefault: borderDefault ?? this.borderDefault,
      borderLight: borderLight ?? this.borderLight,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    );
  }

  @override
  AppExtraColors lerp(ThemeExtension<AppExtraColors>? other, double t) {
    if (other is! AppExtraColors) return this;
    return AppExtraColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
    );
  }
}

/// ----------------------
/// DARK THEME COLORS
/// ----------------------
const Color _darkPrimary700 = Color(0xFF2E3A21); // Primary 700
const Color _darkPrimary500 = Color(0xFF3F4E2C); // Primary 500
const Color _darkPrimary300 = Color(0xFF5D7041); // Primary 300;

const Color _darkBackground900 = Color(0xFF0D100D); // зовнішня "рама"
const Color _darkSurface700 = Color(0xFF1B201B); // основний фон панелей

const Color _darkTextPrimary = Color(0xFFE5E8E0);
const Color _darkTextSecondary = Color(0xFF9BA09B);

const Color _darkError = Color(0xFFA23C3C);
const Color _darkSuccess = Color(0xFF5E8C3F);
const Color _darkWarning = Color(0xFFC7A93D);
const Color _darkInfo = Color(0xFF4A647C);

const Color _darkBorderDefault = Color(0xFF2C332C);
const Color _darkBorderLight = Color(0xFFB5BDB5);

// Додаткові dark-поверхні/акценти
const Color _darkAccent = _darkPrimary300;
const Color _darkAccentSoft = Color(0xFF273020);
const Color _darkSurfaceSubtle = Color(0xFF191E19);
const Color _darkSurfaceElevated = Color(0xFF222820);

/// ----------------------
/// LIGHT THEME COLORS (заглушка)
/// ----------------------
// Світла палітра вивірена для комерційного вигляду
const Color _lightPrimary700 = Color(
  0xFF1565C0,
); // насичений синій для кнопок/головного акценту
const Color _lightPrimary500 = Color(0xFF1E88E5); // основний акцентний колір
const Color _lightPrimary300 = Color(
  0xFF42A5F5,
); // більш світлий відтінок для виділення

// Фони: майже білі та дуже світлі для чистого вигляду
const Color _lightBackground50 = Color(0xFFF5F7FA); // зовнішній фон
const Color _lightSurface100 = Color(
  0xFFFFFFFF,
); // основна поверхня, білосніжна

// Текстові кольори: темно-сірі для контрастності
const Color _lightTextPrimary = Color(0xFF212121); // основний текст
const Color _lightTextSecondary = Color(0xFF666666); // вторинний текст

// Стани: використані матеріальні кольори для впізнаваності
const Color _lightError = Color(0xFFE53935);
const Color _lightSuccess = Color(0xFF4CAF50);
const Color _lightWarning = Color(0xFFFFB300);
const Color _lightInfo = Color(0xFF039BE5);

// Рамки та лінії: світло-сірі, ледь помітні
const Color _lightBorderDefault = Color(0xFFE0E0E0);
const Color _lightBorderLight = Color(0xFFF0F0F0);

// Додаткові light-поверхні/акценти
const Color _lightAccent = _lightPrimary500; // той же синій для консистентності
const Color _lightAccentSoft = Color(
  0xFFE7F1FC,
); // м’який фон для hover/selected
const Color _lightSurfaceSubtle = Color(
  0xFFF9FAFB,
); // фон відрізняється від surface
const Color _lightSurfaceElevated = Color(
  0xFFFFFFFF,
); // підняті картки на білому фоні

/// ----------------------
/// Публічні фабрики тем
/// ----------------------

ThemeData buildDarkTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: _darkPrimary500,
    brightness: Brightness.dark,
  );

  final colorScheme = base.copyWith(
    primary: _darkPrimary500,
    primaryContainer: _darkPrimary700,
    secondary: _darkPrimary300,
    background: _darkBackground900, // зовнішній фон (за межами shell)
    surface: _darkSurface700, // основна "робоча" поверхня
    onBackground: _darkTextPrimary,
    onSurface: _darkTextPrimary,
    error: _darkError,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.background,
    fontFamily: 'Inter',
    textTheme: buildAppTextTheme(_darkTextPrimary, _darkTextSecondary),
    extensions: const [
      AppExtraColors(
        success: _darkSuccess,
        warning: _darkWarning,
        info: _darkInfo,
        borderDefault: _darkBorderDefault,
        borderLight: _darkBorderLight,
        accent: _darkAccent,
        accentSoft: _darkAccentSoft,
        surfaceSubtle: _darkSurfaceSubtle,
        surfaceElevated: _darkSurfaceElevated,
      ),
    ],
  );
}

/// Світла тема – базова, якщо раптом знадобиться.
/// Основний фокус все одно на dark.
ThemeData buildLightTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: _lightPrimary500,
    brightness: Brightness.light,
  );

  final colorScheme = base.copyWith(
    primary: _lightPrimary500,
    primaryContainer: _lightPrimary700,
    secondary: _lightPrimary300,
    background: _lightBackground50,
    surface: _lightSurface100,
    onBackground: _lightTextPrimary,
    onSurface: _lightTextPrimary,
    error: _lightError,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.background,
    fontFamily: 'Inter',
    textTheme: buildAppTextTheme(_lightTextPrimary, _lightTextSecondary),
    extensions: const [
      AppExtraColors(
        success: _lightSuccess,
        warning: _lightWarning,
        info: _lightInfo,
        borderDefault: _lightBorderDefault,
        borderLight: _lightBorderLight,
        accent: _lightAccent,
        accentSoft: _lightAccentSoft,
        surfaceSubtle: _lightSurfaceSubtle,
        surfaceElevated: _lightSurfaceElevated,
      ),
    ],
  );
}

class AppDisplayText {
  static const TextStyle mainH1 = TextStyle(
    fontFamily: 'Volja',
    fontSize: 50,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 1.2,
  );

  static const TextStyle mainH2 = TextStyle(
    fontFamily: 'Volja',
    fontSize: 30,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 2.5,
  );
}

TextTheme buildAppTextTheme(Color primary, Color secondary) {
  return TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 22,
      height: 30 / 22,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: primary,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
      color: secondary,
    ),
  );
}

extension AppTextThemeX on TextTheme {
  TextStyle get h1 => headlineLarge!;
  TextStyle get h2 => titleLarge!;
  TextStyle get body => bodyLarge!;
  TextStyle get label => labelLarge!;
  TextStyle get caption => bodySmall!;
}

/// Зручно тягнути extra-colors з context:
extension AppExtraColorsX on BuildContext {
  AppExtraColors get extra => Theme.of(this).extension<AppExtraColors>()!;
}
