class BasketSummary {
  final String id;
  final String title;
  final int discountedPrice;
  final double? distanceKm;
  final DateTime? pickupTimeEnd;
  final String? photoURL;
  final BasketMerchantSummary? merchant;

  BasketSummary({
    required this.id,
    required this.title,
    required this.discountedPrice,
    this.distanceKm,
    this.pickupTimeEnd,
    this.photoURL,
    this.merchant,
  });

  factory BasketSummary.fromJson(Map<String, dynamic> json) {
    final merchantJson = json['merchant'];
    return BasketSummary(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      discountedPrice: _parseInt(json['discountedPrice']),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      pickupTimeEnd: json['pickupTimeEnd'] != null ? DateTime.parse(json['pickupTimeEnd']) : null,
      photoURL: json['photoURL'],
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
