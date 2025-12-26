import '../repositories/saved_search_repository.dart';
import '../models/saved_search_model.dart';
import 'base_service.dart';

class SavedSearchService extends BaseService {
  late SavedSearchRepository _savedSearchRepository;

  SavedSearchService() {
    _savedSearchRepository = SavedSearchRepository();
  }

  /// Lấy danh sách saved searches của user
  Future<List<SavedSearchModel>> getUserSavedSearches() async {
    final response = await _savedSearchRepository.getUserSavedSearches();
    return unwrapListResponse(response);
  }

  /// Tạo saved search mới
  Future<SavedSearchModel> createSavedSearch(SavedSearchModel savedSearch) async {
    final response = await _savedSearchRepository.createSavedSearch(savedSearch);
    return unwrapResponse(response);
  }

  /// Xóa saved search
  Future<void> deleteSavedSearch(int id) async {
    return await _savedSearchRepository.deleteSavedSearch(id);
  }

  /// Lấy danh sách posts phù hợp với saved search
  Future<List<Map<String, dynamic>>> getMatchingPosts(int savedSearchId) async {
    final response = await _savedSearchRepository.getMatchingPosts(savedSearchId);
    return unwrapListResponse(response);
  }
}

