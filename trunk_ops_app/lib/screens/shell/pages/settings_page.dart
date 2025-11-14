import 'package:flutter/material.dart';
import 'package:trunk_ops_app/main.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

/// Сторінка налаштувань.
/// Дозволяє користувачу вмикати/вимикати сповіщення, автоматичне
/// оновлення та перемикати тему між світлою і темною.
/// Враховує ширину екрана: на великих екранах панель налаштувань центрована, на малих — займає всю ширину.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _autoUpdateEnabled = false;
  // Поточний вибір теми. Оновлюється в didChangeDependencies.
  ThemeMode _selectedThemeMode = ThemeMode.dark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Встановлюємо _selectedThemeMode відповідно до поточної теми
    final brightness = Theme.of(context).brightness;
    _selectedThemeMode = brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 700;
        final double maxContentWidth = isWide ? 600 : constraints.maxWidth;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: extra.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Налаштування',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // Сповіщення
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        'Отримувати сповіщення',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    // Автооновлення
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        'Автоматичне оновлення даних',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      value: _autoUpdateEnabled,
                      onChanged: (value) {
                        setState(() {
                          _autoUpdateEnabled = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    // Вибір теми
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Тема інтерфейсу',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<ThemeMode>(
                              dropdownColor: colorScheme.surface,
                              value: _selectedThemeMode,
                              items: const [
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text('Темна'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text('Світла'),
                                ),
                              ],
                              onChanged: (mode) async {
                                if (mode != null) {
                                  // Пошук стану додатка та зміна теми з очікуванням запису
                                  final appState = context
                                      .findAncestorStateOfType<
                                        TrunkOpsAppState
                                      >();
                                  if (appState != null) {
                                    await appState.setThemeMode(mode);
                                  }
                                  setState(() {
                                    _selectedThemeMode = mode;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
