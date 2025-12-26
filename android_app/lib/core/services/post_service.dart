import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/post_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/api_response.dart';
import '../models/post_model.dart';
import '../models/category_model.dart';
import 'package:dio/dio.dart';
import 'permission_service.dart';
import 'base_service.dart';

class PostService extends BaseService {
  late PostRepository _postRepository;
  late CategoryRepository _categoryRepository;
  static final ImagePicker _picker = ImagePicker();

  PostService() {
    _postRepository = PostRepository();
    _categoryRepository = CategoryRepository();
  }

  /// Lấy danh sách posts với filters
  Future<List<PostModel>> getPosts({
    bool? isApproved,
    String? transactionType,
    String? categoryType,
  }) async {
    final response = await _postRepository.getPosts(
      isApproved: isApproved,
      transactionType: transactionType,
      categoryType: categoryType,
    );
    return unwrapListResponse(response);
  }

  /// Lấy posts với ApiResponse wrapper (khi cần status/message)
  Future<ApiResponse<List<PostModel>>> getPostsWithMeta({
    bool? isApproved,
    String? transactionType,
    String? categoryType,
  }) async {
    return await _postRepository.getPosts(
      isApproved: isApproved,
      transactionType: transactionType,
      categoryType: categoryType,
    );
  }

  /// Lấy post theo ID
  Future<PostModel> getPostById(int id) async {
    final response = await _postRepository.getPostById(id);
    return unwrapResponse(response);
  }

  /// Lấy danh sách posts của user
  Future<List<PostModel>> getPostsByUser(int userId) async {
    final response = await _postRepository.getPostsByUser(userId);
    return unwrapListResponse(response);
  }

  /// Tìm kiếm posts với nhiều filters
  Future<List<PostModel>> searchPosts({
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
    final response = await _postRepository.searchPosts(
      categoryId: categoryId,
      status: status,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minArea: minArea,
      maxArea: maxArea,
      cityName: cityName,
      districtName: districtName,
      wardName: wardName,
      query: query,
    );
    return unwrapListResponse(response);
  }

  /// Tìm kiếm posts trong bán kính
  Future<List<PostModel>> searchByRadius({
    required double centerLat,
    required double centerLng,
    required double radiusInKm,
  }) async {
    final response = await _postRepository.searchByRadius(
      centerLat: centerLat,
      centerLng: centerLng,
      radiusInKm: radiusInKm,
    );
    return unwrapListResponse(response);
  }

  /// Tạo post mới
  Future<PostModel> createPost(FormData formData, {int role = 0}) async {
    final response = await _postRepository.createPost(formData, role: role);
    return unwrapResponse(response);
  }

  /// Cập nhật post
  Future<void> updatePost(int id, FormData formData) async {
    return await _postRepository.updatePost(id, formData);
  }

  /// Xóa post
  Future<void> deletePost(int id) async {
    return await _postRepository.deletePost(id);
  }

  /// Lấy danh sách tất cả categories
  Future<List<CategoryModel>> getCategories() async {
    final response = await _categoryRepository.getCategories();
    return unwrapListResponse(response);
  }

  /// Lấy danh sách categories đang active
  Future<List<CategoryModel>> getActiveCategories() async {
    final response = await _categoryRepository.getActiveCategories();
    return unwrapListResponse(response);
  }

  /// Lấy category theo ID
  Future<CategoryModel> getCategoryById(int id) async {
    final response = await _categoryRepository.getCategoryById(id);
    return unwrapResponse(response);
  }

  List<PostImage> getPostImages(PostModel post) {
    return post.images;
  }

  String? getMainImageUrl(PostModel post) {
    if (post.images.isNotEmpty) {
      return post.images.first.url;
    }
    return post.imageURL;
  }

  List<String> getAllImageUrls(PostModel post) {
    final urls = <String>[];
    if (post.imageURL != null && post.imageURL!.isNotEmpty) {
      urls.add(post.imageURL!);
    }
    for (var image in post.images) {
      if (image.url.isNotEmpty && !urls.contains(image.url)) {
        urls.add(image.url);
      }
    }
    return urls;
  }

  /// Chụp ảnh từ camera
  Future<File?> takePicture(BuildContext context) async {
    final hasPermission = await PermissionService.requestCameraPermission(context);
    if (!hasPermission) {
      return null;
    }

    return await safeLocalCall<File?>(() async {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    });
  }

  /// Chọn 1 ảnh từ thư viện
  Future<File?> pickImageFromGallery(BuildContext context) async {
    final hasPermission = await PermissionService.requestPhotoLibraryPermission(context);
    if (!hasPermission) {
      return null;
    }

    return await safeLocalCall<File?>(() async {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    });
  }

  /// Hiển thị dialog chọn nguồn ảnh (camera hoặc thư viện)
  Future<File?> showImageSourceDialog(BuildContext context) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.of(sheetContext).pop(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.of(sheetContext).pop(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Hủy'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return null;

    if (!context.mounted) {
      return null;
    }
    if (source == ImageSource.camera) {
      return await takePicture(context);
    } else {
      return await pickImageFromGallery(context);
    }
  }

  /// Chọn nhiều ảnh từ thư viện
  Future<List<File>> pickMultipleImagesFromGallery(
    BuildContext context, {
    int maxImages = 10,
  }) async {
    final hasPermission = await PermissionService.requestPhotoLibraryPermission(context);
    if (!hasPermission) {
      return [];
    }

    return await safeLocalCall<List<File>>(() async {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images.isEmpty) return [];

      final limitedImages = images.take(maxImages).toList();
      return limitedImages.map((xFile) => File(xFile.path)).toList();
    });
  }
}

