/// NetLearn — User Model
/// Represents a student user with gamification attributes.
/// Uses WhatsApp phone number as primary identifier.
class UserModel {
  final String id;
  final String displayName;
  final String phoneNumber; // WhatsApp number
  final String? photoUrl;
  final int xp;
  final int level;
  final int streak;
  final DateTime lastActive;
  final DateTime createdAt;
  final UserSettings settings;
  final List<String> unlockedBadgeIds;
  final String role; // 'student' or 'admin'
  final String? password;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    this.photoUrl,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    required this.lastActive,
    required this.createdAt,
    this.settings = const UserSettings(),
    this.unlockedBadgeIds = const [],
    this.role = 'student',
    this.password,
  });

  /// Initials for avatar display
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.substring(0, displayName.length.clamp(0, 2)).toUpperCase();
  }

  /// XP needed for next level (simple formula: level * 100)
  int get xpForNextLevel => _validatedLevel * 100;

  /// Progress to next level (0.0 to 1.0)
  double get levelProgress {
    final nextLevelXp = xpForNextLevel;
    if (nextLevelXp <= 0) return 0.0;
    return (_validatedXp % nextLevelXp) / nextLevelXp;
  }

  int get _validatedXp => xp < 0 ? 0 : xp;
  int get _validatedLevel => level < 1 ? 1 : level;

  /// Formatted phone number display
  String get formattedPhone {
    if (phoneNumber.startsWith('08')) {
      return '+62${phoneNumber.substring(1)}';
    }
    return phoneNumber;
  }

  UserModel copyWith({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    int? xp,
    int? level,
    int? streak,
    DateTime? lastActive,
    UserSettings? settings,
    List<String>? unlockedBadgeIds,
    String? role,
    String? password,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt,
      settings: settings ?? this.settings,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
      role: role ?? this.role,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'photoUrl': photoUrl,
        'xp': xp,
        'level': level,
        'streak': streak,
        'lastActive': lastActive.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'settings': settings.toJson(),
        'unlockedBadgeIds': unlockedBadgeIds,
        'role': role,
        'password': password,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final parsedXp = _asNonNegativeInt(json['xp'], fallback: 0);
    final parsedLevel = _asLevel(json['level'], xp: parsedXp);
    final parsedStreak = _asNonNegativeInt(json['streak'], fallback: 0);

    return UserModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      photoUrl: json['photoUrl'] as String?,
      xp: parsedXp,
      level: parsedLevel,
      streak: parsedStreak,
      lastActive: DateTime.parse(json['lastActive'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      settings: json['settings'] != null
          ? UserSettings.fromJson(Map<String, dynamic>.from(json['settings'] as Map))
          : const UserSettings(),
      unlockedBadgeIds:
          (json['unlockedBadgeIds'] as List?)?.cast<String>() ?? [],
      role: json['role'] as String? ?? 'student',
      password: json['password'] as String?,
    );
  }

  static int _asNonNegativeInt(dynamic value, {required int fallback}) {
    final parsed = switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v),
      _ => null,
    };
    if (parsed == null) return fallback;
    return parsed < 0 ? 0 : parsed;
  }

  static int _asLevel(dynamic rawLevel, {required int xp}) {
    final parsedLevel = _asNonNegativeInt(rawLevel, fallback: 1);
    final safeLevel = parsedLevel < 1 ? 1 : parsedLevel;

    // Keep level at least aligned with XP progression (100 XP per level).
    final derivedLevel = (xp ~/ 100) + 1;
    return derivedLevel > safeLevel ? derivedLevel : safeLevel;
  }
}

/// User settings (persisted preferences)
class UserSettings {
  final bool darkMode;
  final bool audioEnabled;
  final bool musicEnabled;
  final String language;

  const UserSettings({
    this.darkMode = false,
    this.audioEnabled = true,
    this.musicEnabled = false,
    this.language = 'id',
  });

  UserSettings copyWith({
    bool? darkMode,
    bool? audioEnabled,
    bool? musicEnabled,
    String? language,
  }) {
    return UserSettings(
      darkMode: darkMode ?? this.darkMode,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
        'audioEnabled': audioEnabled,
        'musicEnabled': musicEnabled,
        'language': language,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        darkMode: json['darkMode'] as bool? ?? false,
        audioEnabled: json['audioEnabled'] as bool? ?? true,
        musicEnabled: json['musicEnabled'] as bool? ?? false,
        language: json['language'] as String? ?? 'id',
      );
}
