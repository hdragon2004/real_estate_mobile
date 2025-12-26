class ApiResponse<T> {
  final int status;
  final String message;
  final T? data;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    final rawData = json['data'];
    T? parsedData;

    if (rawData != null && fromJsonT != null) {
      if (rawData is List) {
        if (rawData.isNotEmpty) {
          parsedData = fromJsonT(rawData[0] as Map<String, dynamic>);
        }
      } else if (rawData is Map<String, dynamic>) {
        parsedData = fromJsonT(rawData);
      }
    } else {
      parsedData = rawData as T?;
    }

    return ApiResponse<T>(
      status: json['status'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data: parsedData,
    );
  }

  static ApiResponse<List<T>> fromJsonList<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawData = json['data'];
    List<T> parsedData = [];

    if (rawData is List) {
      parsedData = rawData
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList();
    } else if (rawData is Map<String, dynamic>) {
      parsedData = [fromJsonT(rawData)];
    }

    return ApiResponse<List<T>>(
      status: json['status'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data: parsedData,
    );
  }

  bool get isSuccess => status >= 200 && status < 300;
  bool get isError => !isSuccess;

  List<T> get dataAsList {
    if (data == null) return [];
    if (data is List) return data as List<T>;
    return [data as T];
  }

  @override
  String toString() {
    return 'ApiResponse{status: $status, message: $message, data: $data}';
  }
}
