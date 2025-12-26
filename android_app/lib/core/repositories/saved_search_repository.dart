import '../constants/api_constants.dart';
import '../models/saved_search_model.dart';
import 'base_repository.dart';
import 'api_response.dart';

class SavedSearchRepository extends BaseRepository {
  /// Lấy danh sách saved searches của user
  Future<ApiResponse<List<SavedSearchModel>>> getUserSavedSearches() async {
    return await handleRequestListWithResponse<SavedSearchModel>(
      request: () => apiClient.get('${ApiConstants.savedSearches}/me'),
      fromJson: (json) => SavedSearchModel.fromJson(json),
    );
  }

  /// Tạo saved search mới
  Future<ApiResponse<SavedSearchModel>> createSavedSearch(SavedSearchModel savedSearch) async {
    return await handleRequestWithResponse<SavedSearchModel>(
      request: () => apiClient.post(
        ApiConstants.savedSearches,
        data: savedSearch.toJson(),
      ),
      fromJson: (json) => SavedSearchModel.fromJson(json),
    );
  }

  /// Xóa saved search
  Future<void> deleteSavedSearch(int id) async {
    return await handleVoidRequest(
      request: () => apiClient.delete('${ApiConstants.savedSearches}/$id'),
    );
  }

  /// Lấy danh sách posts phù hợp với saved search
  Future<ApiResponse<List<Map<String, dynamic>>>> getMatchingPosts(int savedSearchId) async {
    return await handleRequestListWithResponse<Map<String, dynamic>>(
      request: () => apiClient.get('${ApiConstants.savedSearches}/$savedSearchId/posts'),
      fromJson: (json) => Map<String, dynamic>.from(json),
    );
  }
}
