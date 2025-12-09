import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../models/location_model.dart';

class LocationRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<CityModel>> getCities() async {
    try {
      final response = await _apiClient.get(ApiConstants.cities);

      if (response is List) {
        return response.map((json) => CityModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<CityModel> getCityById(int id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.cities}/$id');
      return CityModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DistrictModel>> getDistricts() async {
    try {
      final response = await _apiClient.get(ApiConstants.districts);

      if (response is List) {
        return response.map((json) => DistrictModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DistrictModel>> getDistrictsByCity(int cityId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.cities}/$cityId/districts');

      if (response is List) {
        return response.map((json) => DistrictModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<WardModel>> getWards() async {
    try {
      final response = await _apiClient.get(ApiConstants.wards);

      if (response is List) {
        return response.map((json) => WardModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<WardModel>> getWardsByDistrict(int districtId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.districts}/$districtId/wards');

      if (response is List) {
        return response.map((json) => WardModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

