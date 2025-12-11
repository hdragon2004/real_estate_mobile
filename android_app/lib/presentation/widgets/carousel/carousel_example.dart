import 'package:flutter/material.dart';
import '../../../core/models/post_model.dart';
import 'property_carousel.dart';

/// Ví dụ cách sử dụng PropertyCarousel
/// 
/// File này chỉ để tham khảo, không được import vào app chính
/// Xem cách sử dụng thực tế trong home_screen.dart
class CarouselExampleScreen extends StatelessWidget {
  const CarouselExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Giả sử bạn có danh sách properties
    final List<PostModel> sampleProperties = []; // Thay bằng dữ liệu thực tế

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Carousel Example'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Sử dụng PropertyCarousel
          PropertyCarousel(
            properties: sampleProperties,
            height: 160, // Chiều cao của carousel
            onTap: (property) {
              // Xử lý khi click vào card
              debugPrint('Clicked property: ${property.title}');
              // Navigator.push(...) để điều hướng đến detail screen
            },
            onFavoriteTap: (property) {
              // Xử lý khi click vào nút favorite
              debugPrint('Favorite toggled: ${property.id}');
              // Gọi API để toggle favorite
            },
            isFavorite: (postId) {
              // Kiểm tra xem property có được favorite không
              // Trả về true/false dựa trên postId
              return false; // Thay bằng logic thực tế
            },
          ),
        ],
      ),
    );
  }
}
