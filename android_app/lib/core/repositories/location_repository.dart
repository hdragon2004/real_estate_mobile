import '../constants/api_constants.dart';
import '../models/location_model.dart';
import 'base_repository.dart';
import 'api_response.dart';

class LocationRepository extends BaseRepository {
  /// Lấy danh sách cities
  Future<ApiResponse<List<CityModel>>> getCities() async {
    return await handleRequestListWithResponse<CityModel>(
      request: () => apiClient.get(ApiConstants.cities),
      fromJson: (json) => CityModel.fromJson(json),
    );
  }

  /// Lấy city theo ID
  Future<ApiResponse<CityModel>> getCityById(int id) async {
    return await handleRequestWithResponse<CityModel>(
      request: () => apiClient.get('${ApiConstants.cities}/$id'),
      fromJson: (json) => CityModel.fromJson(json),
    );
  }

  /// Lấy danh sách districts
  Future<ApiResponse<List<DistrictModel>>> getDistricts() async {
    return await handleRequestListWithResponse<DistrictModel>(
      request: () => apiClient.get(ApiConstants.districts),
      fromJson: (json) => DistrictModel.fromJson(json),
    );
  }

  /// Lấy danh sách districts theo city
  Future<ApiResponse<List<DistrictModel>>> getDistrictsByCity(int cityId) async {
    return await handleRequestListWithResponse<DistrictModel>(
      request: () => apiClient.get('${ApiConstants.cities}/$cityId/districts'),
      fromJson: (json) => DistrictModel.fromJson(json),
    );
  }

  /// Lấy danh sách wards
  Future<ApiResponse<List<WardModel>>> getWards() async {
    return await handleRequestListWithResponse<WardModel>(
      request: () => apiClient.get(ApiConstants.wards),
      fromJson: (json) => WardModel.fromJson(json),
    );
  }

  /// Lấy danh sách wards theo district
  Future<ApiResponse<List<WardModel>>> getWardsByDistrict(int districtId) async {
    return await handleRequestListWithResponse<WardModel>(
      request: () => apiClient.get('${ApiConstants.districts}/$districtId/wards'),
      fromJson: (json) => WardModel.fromJson(json),
    );
  }
}
