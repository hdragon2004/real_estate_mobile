import '../repositories/location_repository.dart';
import '../models/location_model.dart';
import 'base_service.dart';

class LocationService extends BaseService {
  late LocationRepository _locationRepository;

  LocationService() {
    _locationRepository = LocationRepository();
  }

  /// Lấy danh sách cities
  Future<List<CityModel>> getCities() async {
    final response = await _locationRepository.getCities();
    return unwrapListResponse(response);
  }

  /// Lấy city theo ID
  Future<CityModel> getCityById(int id) async {
    final response = await _locationRepository.getCityById(id);
    return unwrapResponse(response);
  }

  /// Lấy danh sách districts
  Future<List<DistrictModel>> getDistricts() async {
    final response = await _locationRepository.getDistricts();
    return unwrapListResponse(response);
  }

  /// Lấy danh sách districts theo city
  Future<List<DistrictModel>> getDistrictsByCity(int cityId) async {
    final response = await _locationRepository.getDistrictsByCity(cityId);
    return unwrapListResponse(response);
  }

  /// Lấy danh sách wards
  Future<List<WardModel>> getWards() async {
    final response = await _locationRepository.getWards();
    return unwrapListResponse(response);
  }

  /// Lấy danh sách wards theo district
  Future<List<WardModel>> getWardsByDistrict(int districtId) async {
    final response = await _locationRepository.getWardsByDistrict(districtId);
    return unwrapListResponse(response);
  }
}

