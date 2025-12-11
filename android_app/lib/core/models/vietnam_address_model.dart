/// Model cho dữ liệu địa chỉ Việt Nam từ API provinces.open-api.vn
class VietnamProvince {
  final String code;
  final String name;

  VietnamProvince({
    required this.code,
    required this.name,
  });

  factory VietnamProvince.fromJson(Map<String, dynamic> json) {
    return VietnamProvince(
      code: json['code']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class VietnamDistrict {
  final String code;
  final String name;

  VietnamDistrict({
    required this.code,
    required this.name,
  });

  factory VietnamDistrict.fromJson(Map<String, dynamic> json) {
    return VietnamDistrict(
      code: json['code']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class VietnamWard {
  final String code;
  final String name;

  VietnamWard({
    required this.code,
    required this.name,
  });

  factory VietnamWard.fromJson(Map<String, dynamic> json) {
    return VietnamWard(
      code: json['code']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

