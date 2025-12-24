import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../models/post_model.dart';

class PostRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<PostModel>> getPosts({
    bool? isApproved,
    String? transactionType,
    String? categoryType,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (isApproved != null) queryParams['isApproved'] = isApproved;
      if (transactionType != null) queryParams['transactionType'] = transactionType;
      if (categoryType != null) queryParams['categoryType'] = categoryType;

      final response = await _apiClient.get(
        ApiConstants.posts,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response is List) {
        return response.map((json) => PostModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<PostModel> getPostById(int id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.posts}/$id');
      return PostModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PostModel>> getPostsByUser(int userId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.postsByUser}/$userId');

      if (response is List) {
        return response.map((json) => PostModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PostModel>> searchPosts({
    int? categoryId,
    String? status,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    String? cityName, // Thay đổi từ cityId sang cityName (text search)
    String? districtName, // Thay đổi từ districtId sang districtName (text search)
    String? wardName, // Thay đổi từ wardId sang wardName (text search)
    String? query,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (status != null) queryParams['status'] = status;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (minArea != null) queryParams['minArea'] = minArea;
      if (maxArea != null) queryParams['maxArea'] = maxArea;
      if (cityName != null && cityName.isNotEmpty) queryParams['cityName'] = cityName;
      if (districtName != null && districtName.isNotEmpty) queryParams['districtName'] = districtName;
      if (wardName != null && wardName.isNotEmpty) queryParams['wardName'] = wardName;
      if (query != null && query.isNotEmpty) queryParams['q'] = query;

      final response = await _apiClient.get(
        ApiConstants.postSearch,
        queryParameters: queryParams,
      );

      if (response is List) {
        return response.map((json) => PostModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<PostModel> createPost(FormData formData, {int role = 0}) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.posts}?role=$role',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return PostModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePost(int id, FormData formData) async {
    try {
      await _apiClient.dio.put(
        '${ApiConstants.posts}/$id',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePost(int id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.posts}/$id');
    } catch (e) {
      rethrow;
    }
  }

  /// Tìm kiếm posts trong bán kính từ một điểm trên bản đồ
  /// Sử dụng Haversine formula để tính khoảng cách
  /// 
  /// [centerLat]: Vĩ độ của điểm trung tâm
  /// [centerLng]: Kinh độ của điểm trung tâm
  /// [radiusInKm]: Bán kính tìm kiếm (km)
  Future<List<PostModel>> searchByRadius({
    required double centerLat,
    required double centerLng,
    required double radiusInKm,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.postSearchByRadius,
        data: {
          'centerLat': centerLat,
          'centerLng': centerLng,
          'radiusInKm': radiusInKm,
        },
      );

      if (response is List) {
        return response.map((json) => PostModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
