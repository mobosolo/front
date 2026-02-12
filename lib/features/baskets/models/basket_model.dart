class Basket {
  final String id;
  final String merchantId;
  final String title;
  final String? description;
  final String? category; // SWEET, SAVORY, MIXED
  final int originalPrice;
  final int discountedPrice;
  final int quantity;
  final int availableQuantity;
  final DateTime pickupTimeStart;
  final DateTime pickupTimeEnd;
  final String? photoURL;
  final String status; // AVAILABLE, SOLD_OUT, EXPIRED
  final DateTime createdAt;
  final DateTime updatedAt;
  final BasketMerchantSummary? merchant;

  Basket({
    required this.id,
    required this.merchantId,
    required this.title,
    this.description,
    this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantity,
    required this.availableQuantity,
    required this.pickupTimeStart,
    required this.pickupTimeEnd,
    this.photoURL,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.merchant,
  });

  factory Basket.fromJson(Map<String, dynamic> json) {
    final merchantJson = json['merchant'];
    return Basket(
      id: json['id'],
      merchantId: json['merchantId'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      originalPrice: _parseInt(json['originalPrice']),
      discountedPrice: _parseInt(json['discountedPrice']),
      quantity: _parseInt(json['quantity']),
      availableQuantity: _parseInt(json['availableQuantity']),
      pickupTimeStart: DateTime.parse(json['pickupTimeStart']),
      pickupTimeEnd: DateTime.parse(json['pickupTimeEnd']),
      photoURL: json['photoURL'],
      status: (json['status'] ?? 'AVAILABLE').toString(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      merchant: merchantJson is Map<String, dynamic> ? BasketMerchantSummary.fromJson(merchantJson) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'title': title,
      'description': description,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'availableQuantity': availableQuantity,
      'pickupTimeStart': pickupTimeStart.toIso8601String(),
      'pickupTimeEnd': pickupTimeEnd.toIso8601String(),
      'photoURL': photoURL,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (merchant != null) 'merchant': merchant!.toJson(),
    };
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
  final String? address;
  final double? latitude;
  final double? longitude;

  BasketMerchantSummary({
    this.businessName,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory BasketMerchantSummary.fromJson(Map<String, dynamic> json) {
    return BasketMerchantSummary(
      businessName: json['businessName'],
      address: json['address'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (businessName != null) 'businessName': businessName,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
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
