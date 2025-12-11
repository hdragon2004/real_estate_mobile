enum TransactionType { sale, rent }
enum PriceUnit { total, perM2, perMonth }

class PostImage {
  final int? id;
  final String url;
  final int? postId;

  PostImage({this.id, required this.url, this.postId});

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'],
      url: json['url'] ?? '',
      postId: json['postId'],
    );
  }
}

class PostModel {
  final int id;
  final String title;
  final String description;
  final double price;
  final PriceUnit priceUnit;
  final TransactionType transactionType;
  final String status;
  final DateTime created;
  final double areaSize;
  final String streetName;
  final int userId;
  final int categoryId;
  final String? categoryName;
  final int wardId;
  final String? cityName; // Tên thành phố trực tiếp từ API
  final String? districtName; // Tên quận/huyện trực tiếp từ API
  final String? wardName; // Tên phường/xã trực tiếp từ API
  final String? userName;
  final bool isApproved;
  final DateTime? expiryDate;
  final int? soPhongNgu;
  final int? soPhongTam;
  final int? soTang;
  final String? huongNha;
  final String? huongBanCong;
  final double? matTien;
  final double? duongVao;
  final String? phapLy;
  final List<PostImage> images;
  final String? timeAgo;
  final PostUser? user;
  final PostCategory? category;
  final PostWard? ward;
  // Google Maps integration fields
  final String? fullAddress; // Địa chỉ đầy đủ từ Google Maps
  final double? longitude; // Tọa độ kinh độ
  final double? latitude; // Tọa độ vĩ độ
  final String? placeId; // Google Place ID
  final String? panoImageUrl; // URL ảnh panorama

  PostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.priceUnit,
    required this.transactionType,
    required this.status,
    required this.created,
    required this.areaSize,
    required this.streetName,
    required this.userId,
    required this.categoryId,
    this.categoryName,
    required this.wardId,
    this.cityName,
    this.districtName,
    this.wardName,
    this.userName,
    required this.isApproved,
    this.expiryDate,
    this.soPhongNgu,
    this.soPhongTam,
    this.soTang,
    this.huongNha,
    this.huongBanCong,
    this.matTien,
    this.duongVao,
    this.phapLy,
    required this.images,
    this.timeAgo,
    this.user,
    this.category,
    this.ward,
    this.fullAddress,
    this.longitude,
    this.latitude,
    this.placeId,
    this.panoImageUrl,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      priceUnit: _parsePriceUnit(json['priceUnit']),
      transactionType: _parseTransactionType(json['transactionType']),
      status: json['status'] ?? '',
      created: json['created'] != null
          ? DateTime.parse(json['created'])
          : DateTime.now(),
      areaSize: (json['area_Size'] ?? json['areaSize'] ?? 0).toDouble(),
      streetName: json['street_Name'] ?? json['streetName'] ?? '',
      userId: json['userId'] ?? 0,
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'],
      wardId: json['wardId'] ?? 0,
      cityName: json['cityName'] ?? json['CityName'], // Hỗ trợ cả camelCase và PascalCase
      districtName: json['districtName'] ?? json['DistrictName'],
      wardName: json['wardName'] ?? json['WardName'],
      userName: json['userName'],
      isApproved: json['isApproved'] ?? false,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      soPhongNgu: json['soPhongNgu'],
      soPhongTam: json['soPhongTam'],
      soTang: json['soTang'],
      huongNha: json['huongNha'],
      huongBanCong: json['huongBanCong'],
      matTien: json['matTien']?.toDouble(),
      duongVao: json['duongVao']?.toDouble(),
      phapLy: json['phapLy'],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => PostImage.fromJson(e))
              .toList() ??
          [],
      timeAgo: json['timeAgo'],
      user: json['user'] != null ? PostUser.fromJson(json['user']) : null,
      category: json['category'] != null
          ? PostCategory.fromJson(json['category'])
          : null,
      ward: json['ward'] != null ? PostWard.fromJson(json['ward']) : null,
      fullAddress: json['fullAddress'] ?? json['FullAddress'],
      longitude: json['longitude']?.toDouble() ?? json['Longitude']?.toDouble(),
      latitude: json['latitude']?.toDouble() ?? json['Latitude']?.toDouble(),
      placeId: json['placeId'] ?? json['PlaceId'],
      panoImageUrl: json['panoImageUrl'] ?? json['PanoImageUrl'],
    );
  }

  static TransactionType _parseTransactionType(dynamic value) {
    if (value == null) return TransactionType.sale;
    if (value is int) {
      return value == 1 ? TransactionType.rent : TransactionType.sale;
    }
    if (value is String) {
      return value.toLowerCase() == 'rent'
          ? TransactionType.rent
          : TransactionType.sale;
    }
    return TransactionType.sale;
  }

  static PriceUnit _parsePriceUnit(dynamic value) {
    if (value == null) return PriceUnit.total;
    if (value is int) {
      switch (value) {
        case 1:
          return PriceUnit.perM2;
        case 2:
          return PriceUnit.perMonth;
        default:
          return PriceUnit.total;
      }
    }
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'perm2':
          return PriceUnit.perM2;
        case 'permonth':
          return PriceUnit.perMonth;
        default:
          return PriceUnit.total;
      }
    }
    return PriceUnit.total;
  }

  String get firstImageUrl {
    if (images.isNotEmpty) {
      return images.first.url;
    }
    return '';
  }

  String get displayAddress {
    // Ưu tiên dùng fullAddress từ Google Maps, sau đó dùng ward nested data
    if (fullAddress != null && fullAddress!.isNotEmpty) {
      return fullAddress!;
    }
    if (ward != null) {
      final district = ward!.district;
      final city = district?.city;
      return '$streetName, ${ward!.name}, ${district?.name ?? ''}, ${city?.name ?? ''}';
    }
    // Fallback: dùng cityName, districtName, wardName trực tiếp
    if (cityName != null || districtName != null || wardName != null) {
      return '$streetName, ${wardName ?? ''}, ${districtName ?? ''}, ${cityName ?? ''}';
    }
    return streetName;
  }
}

class PostUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;

  PostUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  factory PostUser.fromJson(Map<String, dynamic> json) {
    return PostUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
    );
  }
}

class PostCategory {
  final int id;
  final String name;
  final bool isActive;

  PostCategory({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory PostCategory.fromJson(Map<String, dynamic> json) {
    return PostCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}

class PostWard {
  final int id;
  final String name;
  final int districtId;
  final PostDistrict? district;

  PostWard({
    required this.id,
    required this.name,
    required this.districtId,
    this.district,
  });

  factory PostWard.fromJson(Map<String, dynamic> json) {
    return PostWard(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      districtId: json['districtId'] ?? 0,
      district: json['district'] != null
          ? PostDistrict.fromJson(json['district'])
          : null,
    );
  }
}

class PostDistrict {
  final int id;
  final String name;
  final int cityId;
  final PostCity? city;

  PostDistrict({
    required this.id,
    required this.name,
    required this.cityId,
    this.city,
  });

  factory PostDistrict.fromJson(Map<String, dynamic> json) {
    return PostDistrict(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      cityId: json['cityId'] ?? 0,
      city: json['city'] != null ? PostCity.fromJson(json['city']) : null,
    );
  }
}

class PostCity {
  final int id;
  final String name;

  PostCity({required this.id, required this.name});

  factory PostCity.fromJson(Map<String, dynamic> json) {
    return PostCity(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}
