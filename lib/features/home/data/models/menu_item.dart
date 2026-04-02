class QuarterInfo {
  final String name;
  final String city;

  const QuarterInfo({required this.name, required this.city});

  factory QuarterInfo.fromJson(Map<String, dynamic> json) => QuarterInfo(
        name: json['name']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
      );
}

class CookSummary {
  final String id;
  final String displayName;
  final double avgRating;
  final String? landmark;
  final QuarterInfo? quarter;

  const CookSummary({
    required this.id,
    required this.displayName,
    required this.avgRating,
    this.landmark,
    this.quarter,
  });

  factory CookSummary.fromJson(Map<String, dynamic> json) => CookSummary(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? '',
        avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
        landmark: json['landmark']?.toString(),
        quarter: json['quarter'] != null
            ? QuarterInfo.fromJson(json['quarter'] as Map<String, dynamic>)
            : null,
      );
}

class MenuItem {
  final String id;
  final String name;
  final String? description;
  final int priceXaf;
  final String? category;
  final String? imageUrl;
  final bool isAvailable;
  final bool isDailySpecial;
  final int? prepTimeMin;
  final int? stockRemaining;
  final CookSummary? cook;

  const MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.priceXaf,
    this.category,
    this.imageUrl,
    required this.isAvailable,
    required this.isDailySpecial,
    this.prepTimeMin,
    this.stockRemaining,
    this.cook,
  });

  bool get canOrder =>
      isAvailable && (stockRemaining == null || stockRemaining! > 0);

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        priceXaf: (json['priceXaf'] as num?)?.toInt() ?? 0,
        category: json['category']?.toString(),
        imageUrl: json['imageUrl']?.toString(),
        isAvailable: json['isAvailable'] as bool? ?? true,
        isDailySpecial: json['isDailySpecial'] as bool? ?? false,
        prepTimeMin: (json['prepTimeMin'] as num?)?.toInt(),
        stockRemaining: (json['stockRemaining'] as num?)?.toInt(),
        cook: json['cook'] != null
            ? CookSummary.fromJson(json['cook'] as Map<String, dynamic>)
            : null,
      );
}

class PaginatedResult<T> {
  final List<T> data;
  final int total;
  final int page;
  final int totalPages;

  const PaginatedResult({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}
