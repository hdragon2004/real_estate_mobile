import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/post_model.dart';
import 'base_repository.dart';
import 'api_response.dart';

class PostRepository extends BaseRepository {
  
  /// Lấy danh sách posts với filters
  Future<ApiResponse<List<PostModel>>> getPosts({
    bool? isApproved,
    String? transactionType,
    String? categoryType,
  }) async {
    Map<String, dynamic> queryParams = {};
    if (isApproved != null) queryParams['isApproved'] = isApproved;
    if (transactionType != null) queryParams['transactionType'] = transactionType;
    if (categoryType != null) queryParams['categoryType'] = categoryType;

    return await handleRequestListWithResponse<PostModel>(
      request: () => apiClient.get(
        ApiConstants.posts,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      ),
      fromJson: (json) => PostModel.fromJson(json),
    );
  }

  /// Lấy post theo ID
  Future<ApiResponse<PostModel>> getPostById(int id) async {
    return await handleRequestWithResponse<PostModel>(
      request: () => apiClient.get('${ApiConstants.posts}/$id'),
      fromJson: (json) => PostModel.fromJson(json),
    );
  }

  /// Lấy danh sách posts của user
  Future<ApiResponse<List<PostModel>>> getPostsByUser(int userId) async {
    return await handleRequestListWithResponse<PostModel>(
      request: () => apiClient.get('${ApiConstants.postsByUser}/$userId'),
      fromJson: (json) => PostModel.fromJson(json),
    );
  }

  /// Tìm kiếm posts với nhiều filters
  Future<ApiResponse<List<PostModel>>> searchPosts({
    int? categoryId,
    String? status,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    String? cityName,
    String? districtName,
    String? wardName,
    String? query,
  }) async {
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

    return await handleRequestListWithResponse<PostModel>(
      request: () => apiClient.get(
        ApiConstants.postSearch,
        queryParameters: queryParams,
      ),
      fromJson: (json) => PostModel.fromJson(json),
    );
  }

  /// Tìm kiếm posts trong bán kính
  Future<ApiResponse<List<PostModel>>> searchByRadius({
    required double centerLat,
    required double centerLng,
    required double radiusInKm,
  }) async {
    return await handleRequestListWithResponse<PostModel>(
      request: () => apiClient.post(
        ApiConstants.postSearchByRadius,
        data: {
          'centerLat': centerLat,
          'centerLng': centerLng,
          'radiusInKm': radiusInKm,
        },
      ),
      fromJson: (json) => PostModel.fromJson(json),
    );
  }

  /// Tạo post mới
  Future<ApiResponse<PostModel>> createPost(FormData formData, {int role = 0}) async {
    return await handleRequestWithResponse<PostModel>(
      request: () => apiClient.dio.post(
        '${ApiConstants.posts}?role=$role',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      ).then((response) => response.data),
      fromJson: (json) => PostModel.fromJson(json),
    );
  }

  /// Cập nhật post
  Future<void> updatePost(int id, FormData formData) async {
    return await handleVoidRequest(
      request: () => apiClient.dio.put(
        '${ApiConstants.posts}/$id',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      ),
    );
  }

  /// Xóa post
  Future<void> deletePost(int id) async {
    return await handleVoidRequest(
      request: () => apiClient.delete('${ApiConstants.posts}/$id'),
    );
  }

}
