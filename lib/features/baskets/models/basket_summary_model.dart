class BasketSummary {
  final String id;
  final String? merchantId;
  final String title;
  final int originalPrice;
  final int discountedPrice;
  final double? distanceKm;
  final DateTime? pickupTimeStart;
  final DateTime? pickupTimeEnd;
  final String? photoURL;
  final String? status;
  final int? availableQuantity;
  final BasketMerchantSummary? merchant;

  BasketSummary({
    required this.id,
    this.merchantId,
    required this.title,
    required this.originalPrice,
    required this.discountedPrice,
    this.distanceKm,
    this.pickupTimeStart,
    this.pickupTimeEnd,
    this.photoURL,
    this.status,
    this.availableQuantity,
    this.merchant,
  });

  factory BasketSummary.fromJson(Map<String, dynamic> json) {
    final merchantJson = json['merchant'];
    return BasketSummary(
      id: (json['id'] ?? '').toString(),
      merchantId: json['merchantId']?.toString(),
      title: (json['title'] ?? '').toString(),
      originalPrice: _parseInt(json['originalPrice']),
      discountedPrice: _parseInt(json['discountedPrice']),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      pickupTimeStart: json['pickupTimeStart'] != null ? DateTime.parse(json['pickupTimeStart']) : null,
      pickupTimeEnd: json['pickupTimeEnd'] != null ? DateTime.parse(json['pickupTimeEnd']) : null,
      photoURL: json['photoURL'],
      status: json['status']?.toString(),
      availableQuantity: _parseInt(json['availableQuantity']),
      merchant: merchantJson is Map<String, dynamic>
          ? BasketMerchantSummary.fromJson(merchantJson)
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class BasketMerchantSummary {
  final String? businessName;
  final double? latitude;
  final double? longitude;

  BasketMerchantSummary({
    this.businessName,
    this.latitude,
    this.longitude,
  });

  factory BasketMerchantSummary.fromJson(Map<String, dynamic> json) {
    return BasketMerchantSummary(
      businessName: json['businessName'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
