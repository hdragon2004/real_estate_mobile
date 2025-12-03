import 'package:flutter/material.dart';
import '../../widgets/common/property_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import 'search_screen.dart';
import 'filter_screen.dart';
import '../property/property_detail_screen.dart';

/// Màn hình Home / Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  final List<PropertyModel> _properties = _getSampleProperties(); // Dữ liệu mẫu

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    // Điều hướng đến màn hình tìm kiếm
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
  }

  void _handleFilter() async {
    // Mở màn hình filter
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FilterScreen(),
      ),
    );
    
    if (result != null) {
      // TODO: Áp dụng filter và reload danh sách
      _loadProperties();
    }
  }

  void _handlePropertyTypeFilter(String type) {
    // Lọc theo loại hình ngay trên Home
    // TODO: Gọi API với filter loại hình
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    // TODO: Gọi API load properties
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // Dữ liệu mẫu để xem trước giao diện
  static List<PropertyModel> _getSampleProperties() {
    return [
      PropertyModel(
        id: '1',
        title: 'Căn hộ cao cấp tại Quận 1',
        address: '123 Đường Nguyễn Huệ, Quận 1, TP.HCM',
        price: 15000000000,
        imageUrl: null,
        bedrooms: 3,
        bathrooms: 2,
        area: 120,
        isFavorite: false,
      ),
      PropertyModel(
        id: '2',
        title: 'Nhà phố mặt tiền Quận 3',
        address: '456 Đường Lê Văn Sỹ, Quận 3, TP.HCM',
        price: 25000000000,
        imageUrl: null,
        bedrooms: 4,
        bathrooms: 3,
        area: 200,
        isFavorite: true,
      ),
      PropertyModel(
        id: '3',
        title: 'Biệt thự tại Quận 7',
        address: '789 Đường Nguyễn Thị Thập, Quận 7, TP.HCM',
        price: 50000000000,
        imageUrl: null,
        bedrooms: 5,
        bathrooms: 4,
        area: 350,
        isFavorite: false,
      ),
      PropertyModel(
        id: '4',
        title: 'Căn hộ studio Quận 2',
        address: '321 Đường Nguyễn Duy Trinh, Quận 2, TP.HCM',
        price: 5000000000,
        imageUrl: null,
        bedrooms: 1,
        bathrooms: 1,
        area: 50,
        isFavorite: false,
      ),
      PropertyModel(
        id: '5',
        title: 'Chung cư hiện đại Quận Bình Thạnh',
        address: '654 Đường Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM',
        price: 8000000000,
        imageUrl: null,
        bedrooms: 2,
        bathrooms: 2,
        area: 80,
        isFavorite: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm địa điểm, loại hình...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune),
                          onPressed: _handleFilter,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onTap: _handleSearch,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Loại hình nhanh
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loại hình',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Tất cả',
                        'Căn hộ',
                        'Nhà phố',
                        'Biệt thự',
                        'Đất nền',
                        'Chung cư',
                      ].map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type),
                            selected: false, // TODO: Track selected type
                            onSelected: (selected) {
                              _handlePropertyTypeFilter(type);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // Properties list
            Expanded(
              child: _isLoading
                  ? const LoadingIndicator()
                  : _properties.isEmpty
                      ? const EmptyState(
                          icon: Icons.home_outlined,
                          title: 'Chưa có bất động sản',
                          message: 'Hãy thử tìm kiếm để khám phá',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _properties.length,
                          itemBuilder: (context, index) {
                            return PropertyCard(
                              property: _properties[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PropertyDetailScreen(
                                      propertyId: _properties[index].id,
                                    ),
                                  ),
                                );
                              },
                              onFavoriteTap: () {
                                setState(() {
                                  _properties[index] = PropertyModel(
                                    id: _properties[index].id,
                                    title: _properties[index].title,
                                    address: _properties[index].address,
                                    price: _properties[index].price,
                                    imageUrl: _properties[index].imageUrl,
                                    bedrooms: _properties[index].bedrooms,
                                    bathrooms: _properties[index].bathrooms,
                                    area: _properties[index].area,
                                    isFavorite: !_properties[index].isFavorite,
                                  );
                                });
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

