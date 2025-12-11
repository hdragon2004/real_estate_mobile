import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get(ApiConstants.categories);

      if (response is List) {
        return response.map((json) => CategoryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CategoryModel>> getActiveCategories() async {
    try {
      final response = await _apiClient.get(ApiConstants.categoriesAll);

      if (response is List) {
        return response.map((json) => CategoryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<CategoryModel> getCategoryById(int id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.categories}/$id');
      return CategoryModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
