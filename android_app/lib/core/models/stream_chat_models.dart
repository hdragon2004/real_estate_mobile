/// Model classes cho Stream Chat API responses
/// Dùng cho mobile app integration

class MobileChannelsResponse {
  final List<MobileChannelDto> channels;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  MobileChannelsResponse({
    required this.channels,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory MobileChannelsResponse.fromJson(Map<String, dynamic> json) {
    return MobileChannelsResponse(
      channels: (json['channels'] as List<dynamic>?)
              ?.map((e) => MobileChannelDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channels': channels.map((e) => e.toJson()).toList(),
      'page': page,
      'limit': limit,
      'total': total,
      'hasMore': hasMore,
    };
  }
}

class MobileChannelDto {
  final String id;
  final String type;
  final String? name;
  final String? image;
  final MessageSummaryDto? lastMessage;
  final int unreadCount;
  final int memberCount;
  final String? partnerName;
  final String? partnerAvatar;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  MobileChannelDto({
    required this.id,
    required this.type,
    this.name,
    this.image,
    this.lastMessage,
    required this.unreadCount,
    required this.memberCount,
    this.partnerName,
    this.partnerAvatar,
    this.updatedAt,
    this.createdAt,
  });

  factory MobileChannelDto.fromJson(Map<String, dynamic> json) {
    return MobileChannelDto(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      name: json['name'] as String?,
      image: json['image'] as String?,
      lastMessage: json['lastMessage'] != null
          ? MessageSummaryDto.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      memberCount: json['memberCount'] as int? ?? 0,
      partnerName: json['partnerName'] as String?,
      partnerAvatar: json['partnerAvatar'] as String?,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'image': image,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'memberCount': memberCount,
      'partnerName': partnerName,
      'partnerAvatar': partnerAvatar,
      'updatedAt': updatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class MessageSummaryDto {
  final String? text;
  final String? userId;
  final DateTime? createdAt;

  MessageSummaryDto({
    this.text,
    this.userId,
    this.createdAt,
  });

  factory MessageSummaryDto.fromJson(Map<String, dynamic> json) {
    return MessageSummaryDto(
      text: json['text'] as String?,
      userId: json['userId'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class UnreadCountResponse {
  final int unreadCount;

  UnreadCountResponse({
    required this.unreadCount,
  });

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unreadCount': unreadCount,
    };
  }
}

class UploadResponse {
  final String fileUrl;
  final String fileName;
  final String? fileType;
  final int fileSize;

  UploadResponse({
    required this.fileUrl,
    required this.fileName,
    this.fileType,
    required this.fileSize,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileType: json['fileType'] as String?,
      fileSize: json['fileSize'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
    };
  }
}

class SyncResponse {
  final bool success;
  final DateTime syncTime;
  final Map<String, dynamic>? conflicts;
  final List<Map<String, dynamic>>? updatedItems;

  SyncResponse({
    required this.success,
    required this.syncTime,
    this.conflicts,
    this.updatedItems,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      success: json['success'] as bool? ?? false,
      syncTime: DateTime.parse(json['syncTime'] as String),
      conflicts: json['conflicts'] as Map<String, dynamic>?,
      updatedItems: (json['updatedItems'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'syncTime': syncTime.toIso8601String(),
      'conflicts': conflicts,
      'updatedItems': updatedItems,
    };
  }
}