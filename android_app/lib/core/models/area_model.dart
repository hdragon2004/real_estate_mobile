class CityModel {
  final int id;
  final String name;

  CityModel({required this.id, required this.name});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class DistrictModel {
  final int id;
  final String name;
  final int cityId;

  DistrictModel({
    required this.id,
    required this.name,
    required this.cityId,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      cityId: json['cityId'] ?? 0,
    );
  }
}

class WardModel {
  final int id;
  final String name;
  final int districtId;

  WardModel({
    required this.id,
    required this.name,
    required this.districtId,
  });

  factory WardModel.fromJson(Map<String, dynamic> json) {
    return WardModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      districtId: json['districtId'] ?? 0,
    );
  }
}
