import 'package:flutter/material.dart';
// import '../../../core/services/device_info_service.dart'; // DeviceInfoService đã bị xóa

/// Màn hình demo hiển thị thông tin thiết bị (dùng info_plus)
/// Có thể tích hợp vào Settings hoặc About screen
class DeviceInfoDemoScreen extends StatefulWidget {
  const DeviceInfoDemoScreen({super.key});

  @override
  State<DeviceInfoDemoScreen> createState() => _DeviceInfoDemoScreenState();
}

class _DeviceInfoDemoScreenState extends State<DeviceInfoDemoScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _deviceInfo = {};
  String _appInfo = '';
  Map<String, String?> _wifiInfo = {};

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() => _isLoading = true);

    // DeviceInfoService đã bị xóa - comment lại
    // final fullInfo = await DeviceInfoService.getFullDeviceInfo();
    // final appInfoString = await DeviceInfoService.getAppInfoString();
    // final wifiInfo = await DeviceInfoService.getWiFiInfo();
    final fullInfo = <String, dynamic>{};
    final appInfoString = 'App Version 1.0.0';
    final wifiInfo = <String, String?>{};

    setState(() {
      _deviceInfo = fullInfo;
      _appInfo = appInfoString;
      _wifiInfo = wifiInfo;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin thiết bị'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeviceInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDeviceInfo,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Info
                    _buildSection(
                      title: 'Thông tin ứng dụng',
                      icon: Icons.apps,
                      children: [
                        _buildInfoTile('Tên ứng dụng', _appInfo),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Device Info
                    _buildSection(
                      title: 'Thông tin thiết bị',
                      icon: Icons.phone_android,
                      children: [
                        if (_deviceInfo['platform'] != null)
                          _buildInfoTile('Nền tảng', _deviceInfo['platform']),
                        if (_deviceInfo['brand'] != null)
                          _buildInfoTile('Hãng', _deviceInfo['brand']),
                        if (_deviceInfo['manufacturer'] != null)
                          _buildInfoTile('Nhà sản xuất', _deviceInfo['manufacturer']),
                        if (_deviceInfo['model'] != null)
                          _buildInfoTile('Model', _deviceInfo['model']),
                        if (_deviceInfo['device'] != null)
                          _buildInfoTile('Thiết bị', _deviceInfo['device']),
                        if (_deviceInfo['version'] != null)
                          _buildInfoTile(
                            'Phiên bản OS',
                            _deviceInfo['version'] is Map
                                ? _deviceInfo['version']['release'] ?? 'Unknown'
                                : _deviceInfo['version'].toString(),
                          ),
                        if (_deviceInfo['isPhysicalDevice'] != null)
                          _buildInfoTile(
                            'Loại thiết bị',
                            _deviceInfo['isPhysicalDevice'] == true
                                ? 'Thiết bị thật'
                                : 'Emulator/Simulator',
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Network Info
                    if (_wifiInfo.isNotEmpty)
                      _buildSection(
                        title: 'Thông tin mạng',
                        icon: Icons.wifi,
                        children: [
                          if (_wifiInfo['wifiName'] != null)
                            _buildInfoTile('Tên WiFi', _wifiInfo['wifiName'] ?? 'N/A'),
                          if (_wifiInfo['wifiIPAddress'] != null)
                            _buildInfoTile('Địa chỉ IP', _wifiInfo['wifiIPAddress'] ?? 'N/A'),
                          if (_wifiInfo['wifiGatewayIP'] != null)
                            _buildInfoTile('Gateway IP', _wifiInfo['wifiGatewayIP'] ?? 'N/A'),
                        ],
                      ),
                    const SizedBox(height: 24),
                    // Raw Data (for debugging)
                    _buildSection(
                      title: 'Dữ liệu thô (Debug)',
                      icon: Icons.code,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _deviceInfo.toString(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, dynamic value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(
        value?.toString() ?? 'N/A',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}

