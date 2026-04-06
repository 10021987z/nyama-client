import 'dart:convert';
import 'menu_item.dart';

class DayHours {
  final String open;
  final String close;
  final bool closed;

  const DayHours({
    required this.open,
    required this.close,
    required this.closed,
  });

  factory DayHours.fromJson(Map<String, dynamic> json) => DayHours(
        open: json['open']?.toString() ?? '00:00',
        close: json['close']?.toString() ?? '00:00',
        closed: json['closed'] as bool? ?? false,
      );
}

class Cook {
  final String id;
  final String displayName;
  final List<String> specialty;
  final String? description;
  final double avgRating;
  final int totalOrders;
  final String? landmark;
  final double? locationLat;
  final double? locationLng;
  final Map<String, DayHours> openingHours;
  final QuarterInfo? quarter;
  final List<MenuItem> menuItems;

  const Cook({
    required this.id,
    required this.displayName,
    required this.specialty,
    this.description,
    required this.avgRating,
    required this.totalOrders,
    this.landmark,
    this.locationLat,
    this.locationLng,
    required this.openingHours,
    this.quarter,
    required this.menuItems,
  });

  /// Retourne les horaires du jour actuel (null si non défini)
  DayHours? get todayHours {
    const dayKeys = [
      'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'
    ];
    final todayKey = dayKeys[DateTime.now().weekday - 1];
    return openingHours[todayKey];
  }

  bool get isOpenNow {
    final hours = todayHours;
    if (hours == null || hours.closed) return false;
    final now = DateTime.now();
    List<int> parts(String h) => h.split(':').map(int.parse).toList();
    try {
      final openParts = parts(hours.open);
      final closeParts = parts(hours.close);
      final nowMinutes = now.hour * 60 + now.minute;
      final openMinutes = openParts[0] * 60 + openParts[1];
      final closeMinutes = closeParts[0] * 60 + closeParts[1];
      return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
    } catch (_) {
      return true;
    }
  }

  factory Cook.fromJson(Map<String, dynamic> json) {
    return Cook(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      specialty: _parseSpecialty(json['specialty']),
      description: json['description']?.toString(),
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      landmark: json['landmark']?.toString(),
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
      openingHours: _parseOpeningHours(json['openingHours']),
      quarter: json['quarter'] != null
          ? QuarterInfo.fromJson(json['quarter'] as Map<String, dynamic>)
          : null,
      menuItems: (json['menuItems'] as List<dynamic>?)
              ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static List<String> _parseSpecialty(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.isNotEmpty) {
      if (raw.startsWith('[')) {
        try {
          final parsed = jsonDecode(raw) as List<dynamic>;
          return parsed.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [raw];
    }
    return [];
  }

  static Map<String, DayHours> _parseOpeningHours(dynamic raw) {
    if (raw == null) return {};
    Map<String, dynamic> map;
    if (raw is String) {
      try {
        map = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    } else if (raw is Map<String, dynamic>) {
      map = raw;
    } else {
      return {};
    }
    return map.map((key, value) {
      if (value is Map<String, dynamic>) {
        return MapEntry(key, DayHours.fromJson(value));
      }
      return MapEntry(key, const DayHours(open: '00:00', close: '00:00', closed: true));
    });
  }
}
