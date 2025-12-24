/// Model cho SavedSearch (Khu vực tìm kiếm yêu thích)
class SavedSearchModel {
  final int id;
  final int userId;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusKm;
  final String transactionType; // 'Sale' hoặc 'Rent'
  final double? minPrice;
  final double? maxPrice;
  final bool enableNotification;
  final bool isActive;
  final DateTime createdAt;

  // Tên địa điểm (để hiển thị, không lưu trong DB)
  String? locationName;

  SavedSearchModel({
    required this.id,
    required this.userId,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusKm,
    required this.transactionType,
    this.minPrice,
    this.maxPrice,
    this.enableNotification = true,
    this.isActive = true,
    required this.createdAt,
    this.locationName,
  });

  factory SavedSearchModel.fromJson(Map<String, dynamic> json) {
    return SavedSearchModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      centerLatitude: (json['centerLatitude'] as num).toDouble(),
      centerLongitude: (json['centerLongitude'] as num).toDouble(),
      radiusKm: (json['radiusKm'] as num).toDouble(),
      transactionType: json['transactionType'] as String? ?? 'Sale',
      minPrice: json['minPrice'] != null ? (json['minPrice'] as num).toDouble() : null,
      maxPrice: json['maxPrice'] != null ? (json['maxPrice'] as num).toDouble() : null,
      enableNotification: json['enableNotification'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      locationName: json['locationName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'radiusKm': radiusKm,
      'transactionType': transactionType,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'enableNotification': enableNotification,
    };
  }

  /// Tạo copy với các giá trị mới
  SavedSearchModel copyWith({
    int? id,
    int? userId,
    double? centerLatitude,
    double? centerLongitude,
    double? radiusKm,
    String? transactionType,
    double? minPrice,
    double? maxPrice,
    bool? enableNotification,
    bool? isActive,
    DateTime? createdAt,
    String? locationName,
  }) {
    return SavedSearchModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      radiusKm: radiusKm ?? this.radiusKm,
      transactionType: transactionType ?? this.transactionType,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      enableNotification: enableNotification ?? this.enableNotification,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      locationName: locationName ?? this.locationName,
    );
  }
}

