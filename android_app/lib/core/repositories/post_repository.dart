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
    int? cityId,
    int? districtId,
    int? wardId,
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
      if (cityId != null) queryParams['cityId'] = cityId;
      if (districtId != null) queryParams['districtId'] = districtId;
      if (wardId != null) queryParams['wardId'] = wardId;
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
}
