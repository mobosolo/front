class Order {
  final String id;
  final String userId;
  final String basketId;
  final String merchantId;
  final int price;
  final String paymentMethod; // FLOOZ, TMONEY, CASH
  final String paymentStatus; // PENDING, PAID, FAILED
  final String orderStatus;   // RESERVED, PICKED_UP, CANCELLED
  final String qrCode;
  final String? transactionRef;
  final DateTime? paidAt;
  final DateTime? pickedUpAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrderBasketSummary? basket;
  final OrderMerchantSummary? merchant;
  final OrderUserSummary? user;

  Order({
    required this.id,
    required this.userId,
    required this.basketId,
    required this.merchantId,
    required this.price,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.qrCode,
    this.transactionRef,
    this.paidAt,
    this.pickedUpAt,
    required this.createdAt,
    required this.updatedAt,
    this.basket,
    this.merchant,
    this.user,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final basketJson = json['basket'];
    final merchantJson = json['merchant'];
    final userJson = json['user'];
    return Order(
      id: json['id'],
      userId: json['userId'],
      basketId: json['basketId'],
      merchantId: json['merchantId'],
      price: _parseInt(json['price']),
      paymentMethod: (json['paymentMethod'] ?? 'UNKNOWN').toString(),
      paymentStatus: (json['paymentStatus'] ?? 'PENDING').toString(),
      orderStatus: (json['orderStatus'] ?? 'RESERVED').toString(),
      qrCode: json['qrCode'],
      transactionRef: json['transactionRef'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      pickedUpAt: json['pickedUpAt'] != null ? DateTime.parse(json['pickedUpAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      basket: basketJson is Map<String, dynamic> ? OrderBasketSummary.fromJson(basketJson) : null,
      merchant: merchantJson is Map<String, dynamic> ? OrderMerchantSummary.fromJson(merchantJson) : null,
      user: userJson is Map<String, dynamic> ? OrderUserSummary.fromJson(userJson) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'basketId': basketId,
      'merchantId': merchantId,
      'price': price,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'qrCode': qrCode,
      'transactionRef': transactionRef,
      'paidAt': paidAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (basket != null) 'basket': basket!.toJson(),
      if (merchant != null) 'merchant': merchant!.toJson(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class OrderBasketSummary {
  final String? title;
  final String? photoURL;
  final DateTime? pickupTimeStart;
  final DateTime? pickupTimeEnd;
  final int? originalPrice;
  final int? discountedPrice;

  OrderBasketSummary({
    this.title,
    this.photoURL,
    this.pickupTimeStart,
    this.pickupTimeEnd,
    this.originalPrice,
    this.discountedPrice,
  });

  factory OrderBasketSummary.fromJson(Map<String, dynamic> json) {
    return OrderBasketSummary(
      title: json['title'],
      photoURL: json['photoURL'],
      pickupTimeStart: json['pickupTimeStart'] != null ? DateTime.parse(json['pickupTimeStart']) : null,
      pickupTimeEnd: json['pickupTimeEnd'] != null ? DateTime.parse(json['pickupTimeEnd']) : null,
      originalPrice: _parseIntNullable(json['originalPrice']),
      discountedPrice: _parseIntNullable(json['discountedPrice']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (photoURL != null) 'photoURL': photoURL,
      if (pickupTimeStart != null) 'pickupTimeStart': pickupTimeStart!.toIso8601String(),
      if (pickupTimeEnd != null) 'pickupTimeEnd': pickupTimeEnd!.toIso8601String(),
      if (originalPrice != null) 'originalPrice': originalPrice,
      if (discountedPrice != null) 'discountedPrice': discountedPrice,
    };
  }
}

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class OrderMerchantSummary {
  final String? businessName;
  final String? address;

  OrderMerchantSummary({this.businessName, this.address});

  factory OrderMerchantSummary.fromJson(Map<String, dynamic> json) {
    return OrderMerchantSummary(
      businessName: json['businessName'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (businessName != null) 'businessName': businessName,
      if (address != null) 'address': address,
    };
  }
}

class OrderUserSummary {
  final String? displayName;
  final String? phoneNumber;

  OrderUserSummary({this.displayName, this.phoneNumber});

  factory OrderUserSummary.fromJson(Map<String, dynamic> json) {
    return OrderUserSummary(
      displayName: json['displayName'],
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (displayName != null) 'displayName': displayName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
}
