import 'package:flutter/material.dart';
import '../../widgets/common/property_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';

/// Màn hình Kết quả tìm kiếm
class SearchResultsScreen extends StatefulWidget {
  final String query;
  final Map<String, dynamic>? filters;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.filters,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _isLoading = false;
  final List<PropertyModel> _results = []; // TODO: Load từ API
  String _sortBy = 'Mới nhất';

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    // TODO: Gọi API với query và filters
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sắp xếp theo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['Mới nhất', 'Giá thấp đến cao', 'Giá cao đến thấp', 'Diện tích']
                .map((option) => ListTile(
                      title: Text(option),
                      trailing: _sortBy == option
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() => _sortBy = option);
                        Navigator.pop(context);
                        _loadResults();
                      },
                    )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kết quả: ${widget.query}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sắp xếp',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _results.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  title: 'Không tìm thấy kết quả',
                  message: 'Thử thay đổi từ khóa hoặc bộ lọc',
                  buttonText: 'Thử lại',
                  onButtonTap: _loadResults,
                )
              : Column(
                  children: [
                    // Results count
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade100,
                      child: Row(
                        children: [
                          Text(
                            'Tìm thấy ${_results.length} kết quả',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Mở filter
                            },
                            icon: const Icon(Icons.tune),
                            label: const Text('Lọc'),
                          ),
                        ],
                      ),
                    ),
                    // Results list
                    Expanded(
                      child: ListView.builder(
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
                      ),
                    ),
                  ],
                ),
    );
  }
}

