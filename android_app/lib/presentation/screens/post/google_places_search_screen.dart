import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/services/google_places_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../config/app_config.dart';

/// Màn hình tìm kiếm địa điểm bằng Google Places
class GooglePlacesSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const GooglePlacesSearchScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<GooglePlacesSearchScreen> createState() => _GooglePlacesSearchScreenState();
}

class _GooglePlacesSearchScreenState extends State<GooglePlacesSearchScreen> {
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  bool _isLoading = false;
  List<PlacePrediction> _predictions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _handleSearch(widget.initialQuery!);
    }
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _predictions = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Lấy API key từ app_config
      const apiKey = AppConfig.googlePlacesApiKey;
      
      if (apiKey.isEmpty || apiKey == 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
        throw Exception('Google Places API Key chưa được cấu hình. Vui lòng thêm API key vào app_config.dart');
      }
      
      final predictions = await GooglePlacesService.searchPlaces(
        query,
        apiKey: apiKey,
      );

      if (!mounted) return;
      
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _predictions = [];
      });
    }
  }

  Future<void> _selectPlace(PlacePrediction prediction) async {
    setState(() => _isLoading = true);

    try {
      const apiKey = AppConfig.googlePlacesApiKey;
      
      if (apiKey.isEmpty || apiKey == 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
        throw Exception('Google Places API Key chưa được cấu hình');
      }
      
      final details = await GooglePlacesService.getPlaceDetails(
        prediction.placeId,
        apiKey: apiKey,
      );

      if (!mounted) return;

      // Trả về kết quả cho màn hình trước
      Navigator.pop(context, details);
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Lỗi lấy chi tiết địa điểm: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Tìm kiếm địa điểm', style: AppTextStyles.h6),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Nhập địa điểm cần tìm...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                prefixIcon: const Icon(Iconsax.search_normal_1, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.textSecondary,
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _predictions = [];
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _handleSearch,
              onSubmitted: _handleSearch,
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
                            const Gap(16),
                            Text(
                              _errorMessage!,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                            const Gap(16),
                            Text(
                              'Vui lòng kiểm tra Google Places API Key trong app_config.dart',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _predictions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.location, size: 64, color: AppColors.textHint),
                                const Gap(16),
                                Text(
                                  'Nhập địa điểm để tìm kiếm',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _predictions.length,
                            itemBuilder: (context, index) {
                              final prediction = _predictions[index];
                              return _buildPlaceItem(prediction);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceItem(PlacePrediction prediction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Iconsax.location, color: AppColors.primary, size: 20),
        ),
        title: Text(
          prediction.mainText ?? prediction.description,
          style: AppTextStyles.labelLarge,
        ),
        subtitle: prediction.secondaryText != null
            ? Text(
                prediction.secondaryText!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              )
            : null,
        trailing: const Icon(Iconsax.arrow_right_3, size: 18, color: AppColors.textSecondary),
        onTap: () => _selectPlace(prediction),
      ),
    );
  }
}

