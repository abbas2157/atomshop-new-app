class SellerNotificationSettings {
  final Map<String, bool> preferences;
  final List<SellerNotificationType> types;

  const SellerNotificationSettings({
    required this.preferences,
    required this.types,
  });

  factory SellerNotificationSettings.fromResponse(Map<String, dynamic> response) {
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : <String, dynamic>{};
    final prefsRaw = data['preferences'] is Map
        ? Map<String, dynamic>.from(data['preferences'])
        : <String, dynamic>{};
    return SellerNotificationSettings(
      preferences: prefsRaw.map((k, v) => MapEntry(k, v == true)),
      types: (data['types'] as List? ?? [])
          .whereType<Map>()
          .map((e) => SellerNotificationType.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  SellerNotificationSettings copyWithToggle(String type, bool enabled) {
    return SellerNotificationSettings(
      preferences: {...preferences, type: enabled},
      types: types
          .map((t) => t.type == type ? t.copyWith(enabled: enabled) : t)
          .toList(growable: false),
    );
  }

  SellerNotificationSettings copyWithPreferences(Map<String, bool> updated) {
    return SellerNotificationSettings(
      preferences: updated,
      types: types.map((t) {
        final e = updated[t.type];
        return e != null ? t.copyWith(enabled: e) : t;
      }).toList(growable: false),
    );
  }

  /// Types grouped by their [SellerNotificationType.group], preserving API order.
  Map<String, List<SellerNotificationType>> get groupedTypes {
    final result = <String, List<SellerNotificationType>>{};
    for (final t in types) {
      (result[t.group] ??= []).add(t);
    }
    return result;
  }
}

class SellerNotificationType {
  final String type;
  final String label;
  final String description;
  final String group;
  final bool enabled;

  const SellerNotificationType({
    required this.type,
    required this.label,
    required this.description,
    required this.group,
    required this.enabled,
  });

  factory SellerNotificationType.fromJson(Map<String, dynamic> json) {
    return SellerNotificationType(
      type: _text(json['type']),
      label: _text(json['label']),
      description: _text(json['description']),
      group: _text(json['group'], fallback: 'General'),
      enabled: json['enabled'] == true,
    );
  }

  SellerNotificationType copyWith({bool? enabled}) {
    return SellerNotificationType(
      type: type,
      label: label,
      description: description,
      group: group,
      enabled: enabled ?? this.enabled,
    );
  }
}

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return fallback;
  return text;
}
