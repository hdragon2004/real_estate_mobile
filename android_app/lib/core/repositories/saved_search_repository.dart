import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../models/saved_search_model.dart';

class SavedSearchRepository {
  final ApiClient _apiClient = ApiClient();

  /// Lấy tất cả SavedSearch của user hiện tại
  Future<List<SavedSearchModel>> getUserSavedSearches() async {
    try {
      final response = await _apiClient.get('${ApiConstants.savedSearches}/me');
      
      if (response is List) {
        return response
            .map((json) => SavedSearchModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo SavedSearch mới
  Future<SavedSearchModel> createSavedSearch(SavedSearchModel savedSearch) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.savedSearches,
        data: savedSearch.toJson(),
      );
      return SavedSearchModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa SavedSearch
  Future<void> deleteSavedSearch(int id) async {
    try {
      await _apiClient.delete('${ApiConstants.savedSearches}/$id');
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy danh sách posts phù hợp với SavedSearch
  Future<List<Map<String, dynamic>>> getMatchingPosts(int savedSearchId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.savedSearches}/$savedSearchId/posts');
      
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

