import 'package:flutter/material.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/property_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../../core/models/post_model.dart';

/// Màn hình Tìm kiếm
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  final List<PostModel> _results = [];
  final List<String> _recentSearches = ['Căn hộ Hà Nội', 'Nhà phố TP.HCM'];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    // TODO: Gọi API tìm kiếm
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
    });
  }

  void _handleRecentSearch(String query) {
    _searchController.text = query;
    _handleSearch(query);
  }

  void _handleLocationSearch() {
    // TODO: Mở Google Map để chọn địa điểm
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => MapSearchScreen(),
    //   ),
    // );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng tìm kiếm theo bản đồ sẽ được tích hợp Google Maps'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppTextField(
          controller: _searchController,
          hint: 'Tìm kiếm địa điểm, loại hình...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _results.clear();
                    });
                  },
                )
              : null,
          focusNode: _searchFocusNode,
          onChanged: (value) {
            setState(() {});
            if (value.isNotEmpty) {
              _handleSearch(value);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Tìm kiếm theo bản đồ',
            onPressed: _handleLocationSearch,
          ),
          TextButton(
            onPressed: () {
              _searchController.clear();
              _results.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Hủy'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    if (_searchController.text.isEmpty) {
      return _buildRecentSearches();
    }

    if (_results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Không tìm thấy kết quả',
        message: 'Thử tìm kiếm với từ khóa khác',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return PropertyCard(
          property: _results[index],
          onTap: () {
            // TODO: Điều hướng đến chi tiết
          },
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tìm kiếm theo bản đồ
        Card(
          child: ListTile(
            leading: const Icon(Icons.map, color: Colors.blue),
            title: const Text('Tìm kiếm theo bản đồ'),
            subtitle: const Text('Chọn địa điểm trên bản đồ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _handleLocationSearch,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Tìm kiếm gần đây',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._recentSearches.map((search) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(search),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _handleRecentSearch(search),
            )),
        const SizedBox(height: 24),
        const Text(
          'Loại hình',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Căn hộ',
            'Nhà phố',
            'Biệt thự',
            'Đất nền',
            'Chung cư',
          ].map((tag) => ActionChip(
                label: Text(tag),
                onPressed: () => _handleRecentSearch(tag),
              )).toList(),
        ),
      ],
    );
  }
}

