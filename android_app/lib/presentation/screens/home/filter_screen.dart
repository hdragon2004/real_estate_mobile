import 'package:flutter/material.dart';
import '../../widgets/common/app_button.dart';

/// Model cho Filter
class FilterModel {
  double? minPrice;
  double? maxPrice;
  double? minArea;
  double? maxArea;
  int? bedrooms;
  int? bathrooms;
  String? propertyType;
  String? location;

  FilterModel({
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.bedrooms,
    this.bathrooms,
    this.propertyType,
    this.location,
  });
}

/// Màn hình Bộ lọc nâng cao
class FilterScreen extends StatefulWidget {
  final FilterModel? initialFilters;

  const FilterScreen({
    super.key,
    this.initialFilters,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late FilterModel _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? FilterModel();
  }

  void _applyFilters() {
    Navigator.of(context).pop(_filters);
  }

  void _resetFilters() {
    setState(() {
      _filters = FilterModel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bộ lọc'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Đặt lại'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Property Type
          _buildSection(
            title: 'Loại hình',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Căn hộ',
                'Nhà phố',
                'Biệt thự',
                'Đất nền',
                'Chung cư',
              ].map((type) {
                final isSelected = _filters.propertyType == type;
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filters.propertyType = selected ? type : null;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Price Range
          _buildSection(
            title: 'Khoảng giá',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Từ (triệu)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _filters.minPrice = double.tryParse(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Đến (triệu)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _filters.maxPrice = double.tryParse(value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Area Range
          _buildSection(
            title: 'Diện tích (m²)',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Từ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _filters.minArea = double.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Đến',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _filters.maxArea = double.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Bedrooms
          _buildSection(
            title: 'Số phòng ngủ',
            child: Wrap(
              spacing: 8,
              children: List.generate(5, (index) {
                final count = index + 1;
                final isSelected = _filters.bedrooms == count;
                return FilterChip(
                  label: Text('$count+'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filters.bedrooms = selected ? count : null;
                    });
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          // Bathrooms
          _buildSection(
            title: 'Số phòng tắm',
            child: Wrap(
              spacing: 8,
              children: List.generate(4, (index) {
                final count = index + 1;
                final isSelected = _filters.bathrooms == count;
                return FilterChip(
                  label: Text('$count+'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filters.bathrooms = selected ? count : null;
                    });
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          // Location
          _buildSection(
            title: 'Khu vực',
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Nhập địa điểm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              onChanged: (value) {
                _filters.location = value.isEmpty ? null : value;
              },
            ),
          ),
          const SizedBox(height: 32),
          // Apply button
          AppButton(
            text: 'Áp dụng bộ lọc',
            onPressed: _applyFilters,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

