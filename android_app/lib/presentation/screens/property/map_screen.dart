import 'package:flutter/material.dart';

/// Model cho Property trên Map
class MapProperty {
  final String id;
  final String title;
  final double price;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  MapProperty({
    required this.id,
    required this.title,
    required this.price,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });
}

/// Màn hình Bản đồ - xem vị trí & các BĐS lân cận
class MapScreen extends StatefulWidget {
  final String? propertyId;
  final double? initialLatitude;
  final double? initialLongitude;

  const MapScreen({
    super.key,
    this.propertyId,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<MapProperty> _nearbyProperties = []; // TODO: Load từ API

  @override
  void initState() {
    super.initState();
    _loadNearbyProperties();
  }

  Future<void> _loadNearbyProperties() async {
    // TODO: Gọi API lấy các BĐS lân cận
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              // TODO: Toggle list view
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map placeholder (cần tích hợp Google Maps)
          Container(
            color: Colors.grey.shade300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 80,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tích hợp Google Maps',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cần thêm package: google_maps_flutter',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom sheet với danh sách BĐS lân cận
          if (_nearbyProperties.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.1,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Title
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Bất động sản lân cận',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _nearbyProperties.length,
                          itemBuilder: (context, index) {
                            final property = _nearbyProperties[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: property.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          property.imageUrl!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey.shade300,
                                              child: const Icon(Icons.image),
                                            );
                                          },
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.image),
                                      ),
                                title: Text(
                                  property.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${(property.price / 1000000).toStringAsFixed(0)} triệu',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                onTap: () {
                                  // TODO: Điều hướng đến chi tiết
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

