import 'package:front/features/merchant/models/merchant_model.dart';

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final String role;
  final Merchant? merchant; // Add merchant profile

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    required this.role,
    this.merchant,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      phoneNumber: json['phoneNumber'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      role: json['role'],
      merchant: json['merchant'] != null ? Merchant.fromJson(json['merchant']) : null,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    String? role,
    Merchant? merchant,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      role: role ?? this.role,
      merchant: merchant ?? this.merchant,
    );
  }
}
