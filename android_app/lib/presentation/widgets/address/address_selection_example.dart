import 'package:flutter/material.dart';
import 'address_selection_widget.dart';
import '../../../core/models/address_data_model.dart';

/// Example: Cách sử dụng AddressSelectionWidget
/// 
/// Widget này cho phép user:
/// 1. Chọn tỉnh/thành phố, quận/huyện, phường/xã từ dropdown
/// 2. Nhập tên đường
/// 3. Chọn vị trí chính xác trên bản đồ OpenStreetMap (FREE)
/// 4. Lưu địa chỉ với tọa độ (lat/lng)
class AddressSelectionExample extends StatelessWidget {
  const AddressSelectionExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn địa chỉ'),
      ),
      body: AddressSelectionWidget(
        // Callback khi user chọn xong địa chỉ
        onAddressSelected: (AddressData addressData) {
          // In ra console để xem cấu trúc dữ liệu
          debugPrint('=== ĐỊA CHỈ ĐÃ CHỌN ===');
          debugPrint('Tỉnh: ${addressData.provinceName} (${addressData.provinceCode})');
          debugPrint('Quận: ${addressData.districtName} (${addressData.districtCode})');
          debugPrint('Phường: ${addressData.wardName} (${addressData.wardCode})');
          debugPrint('Đường: ${addressData.street}');
          debugPrint('Tọa độ: ${addressData.latitude}, ${addressData.longitude}');
          debugPrint('Địa chỉ đầy đủ: ${addressData.fullAddress}');
          debugPrint('JSON: ${addressData.toJson()}');
          
          // Gửi lên backend
          _sendToBackend(addressData);
          
          // Hiển thị thông báo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã chọn: ${addressData.fullAddress}'),
              backgroundColor: Colors.green,
            ),
          );
        },
        
        // Địa chỉ ban đầu (nếu có - optional)
        // initialAddress: AddressData(...),
      ),
    );
  }

  Future<void> _sendToBackend(AddressData addressData) async {
    try {
      // TODO: Thay bằng API client của bạn
      // final response = await apiClient.post(
      //   '/api/posts/address',
      //   data: addressData.toJson(),
      // );
      
      debugPrint('Gửi lên backend: ${addressData.toJson()}');
    } catch (e) {
      debugPrint('Lỗi gửi lên backend: $e');
    }
  }
}

