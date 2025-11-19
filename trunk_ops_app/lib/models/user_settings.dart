/// Model representing persisted settings for a user.
class UserSettings {
  final int id;
  final int userId;
  final bool notificationsEnabled;
  final bool autoUpdateEnabled;
  final String themeMode;

  UserSettings({
    required this.id,
    required this.userId,
    required this.notificationsEnabled,
    required this.autoUpdateEnabled,
    required this.themeMode,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
        userId: json['user_id'] is int
            ? json['user_id']
            : int.tryParse(json['user_id'].toString()) ?? 0,
        notificationsEnabled: json['notifications_enabled'] ?? false,
        autoUpdateEnabled: json['auto_update_enabled'] ?? false,
        themeMode: json['theme_mode'] ?? 'dark',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'notifications_enabled': notificationsEnabled,
        'auto_update_enabled': autoUpdateEnabled,
        'theme_mode': themeMode,
      };
}