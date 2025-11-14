import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

import '../shell/dashboard_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = context.extra;

    // Адаптивні розміри для логотипу та текстів
    final logoSize = (size.width * 0.06).clamp(40.0, 80.0);
    final brandFontSize = (size.width * 0.035).clamp(26.0, 50.0);
    final mottoFontSize = (size.width * 0.022).clamp(18.0, 32.0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LEFT PANEL — 40%
            Expanded(
              flex: 4,
              child: Container(
                color: colorScheme.surface,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),

                      // LOGO + TITLE
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/trunkops_logo.svg',
                              width: logoSize,
                              height: logoSize,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              "TrunkOps",
                              style: TextStyle(
                                fontFamily: "Volja",
                                fontSize: brandFontSize,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // MOTTO
                      Text(
                        "PATRIA ET HONOR",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Volja",
                          fontSize: mottoFontSize,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // VITI LOGO
                      Opacity(
                        opacity: theme.brightness == Brightness.dark
                            ? 0.6
                            : 0.4,
                        child: Image.asset(
                          'assets/images/viti_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),

            // RIGHT PANEL — 60%
            Expanded(
              flex: 6,
              child: Container(
                color: colorScheme.background,
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: _buildLoginCard(context, colorScheme, extra),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LOGIN CARD
  Widget _buildLoginCard(
    BuildContext context,
    ColorScheme colorScheme,
    AppExtraColors extra,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: 600,
      constraints: const BoxConstraints(maxWidth: 600, minWidth: 280),
      decoration: BoxDecoration(
        color: extra.surfaceElevated, // піднята поверхня
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: extra.borderDefault),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              "Вхід до системи",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            "Логін",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: extra.surfaceSubtle,
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: extra.borderDefault, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: extra.accent, width: 1.4),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "Пароль",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            obscureText: _obscurePassword,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              filled: true,
              fillColor: extra.surfaceSubtle,
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: extra.borderDefault, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: extra.accent, width: 1.4),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                side: BorderSide(color: extra.borderDefault, width: 1.5),
                activeColor: extra.accent,
                checkColor: colorScheme.surface,
              ),
              const SizedBox(width: 8),
              Text(
                "Пам’ятати мене",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: () {
                // Поки що завжди йдемо на Dashboard
                Navigator.pushReplacementNamed(
                  context,
                  DashboardShellScreen.routeName,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: extra.accent,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Увійти",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                "Забули пароль ?",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: extra.warning,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
