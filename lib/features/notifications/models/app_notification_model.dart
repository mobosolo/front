class AppNotification {
  final String id;
  final String? title;
  final String? body;
  final String? type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    this.title,
    this.body,
    this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      title: json['title'],
      body: json['body'],
      type: json['type'],
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      isRead: json['isRead'] == true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
