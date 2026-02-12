class Merchant {
  final String id;
  final String? userId;
  final String businessName;
  final String? type;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? photoURL;
  final String status; // PENDING, APPROVED, REJECTED
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Merchant({
    required this.id,
    this.userId,
    required this.businessName,
    this.type,
    this.address,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.photoURL,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'],
      userId: json['userId'],
      businessName: (json['businessName'] ?? '').toString(),
      type: json['type'],
      address: json['address'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      phoneNumber: json['phoneNumber'],
      photoURL: json['photoURL'],
      status: (json['status'] ?? 'PENDING').toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'businessName': businessName,
      'type': type,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
