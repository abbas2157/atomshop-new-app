class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final String? image;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? readAt;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.image,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      image: json['image'] as String?,
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : {},
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'image': image,
        'data': data,
        'is_read': isRead,
        'read_at': readAt,
        'created_at': createdAt,
      };

  String? get screen => data['screen'] as String?;
  String? get leadId => data['lead_id'] as String?;
  String? get orderId => data['order_id'] as String?;
  String? get paymentType => data['payment_type'] as String?;

  DateTime get createdAtDate {
    try {
      return DateTime.parse(createdAt);
    } catch (_) {
      return DateTime.now();
    }
  }

  AppNotification copyWith({bool? isRead, String? readAt}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      image: image,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

class NotificationsState {
  final List<AppNotification> items;
  final int unreadCount;
  final int currentPage;
  final int lastPage;
  final bool isLoading;
  final bool isLoadingMore;
  final bool initialized;
  final String? error;

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.currentPage = 1,
    this.lastPage = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.initialized = false,
    this.error,
  });

  bool get hasMore => currentPage < lastPage;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    int? currentPage,
    int? lastPage,
    bool? isLoading,
    bool? isLoadingMore,
    bool? initialized,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      initialized: initialized ?? this.initialized,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
