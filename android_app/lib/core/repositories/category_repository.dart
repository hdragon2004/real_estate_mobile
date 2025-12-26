import '../constants/api_constants.dart';
import '../models/category_model.dart';
import 'base_repository.dart';
import 'api_response.dart';

class CategoryRepository extends BaseRepository {
  /// Lấy danh sách tất cả categories
  Future<ApiResponse<List<CategoryModel>>> getCategories() async {
    return await handleRequestListWithResponse<CategoryModel>(
      request: () => apiClient.get(ApiConstants.categories),
      fromJson: (json) => CategoryModel.fromJson(json),
    );
  }

  /// Lấy danh sách categories đang active
  Future<ApiResponse<List<CategoryModel>>> getActiveCategories() async {
    return await handleRequestListWithResponse<CategoryModel>(
      request: () => apiClient.get(ApiConstants.categoriesAll),
      fromJson: (json) => CategoryModel.fromJson(json),
    );
  }

  /// Lấy category theo ID
  Future<ApiResponse<CategoryModel>> getCategoryById(int id) async {
    return await handleRequestWithResponse<CategoryModel>(
      request: () => apiClient.get('${ApiConstants.categories}/$id'),
      fromJson: (json) => CategoryModel.fromJson(json),
    );
  }
}
