class AdminStats {
  final int totalUsers;
  final int totalMerchants;
  final int pendingMerchants;
  final int approvedMerchants;
  final int totalBaskets;
  final int availableBaskets;
  final int totalOrders;
  final int pendingPayments;
  final int paidOrders;
  final int pickedUpOrders;

  AdminStats({
    required this.totalUsers,
    required this.totalMerchants,
    required this.pendingMerchants,
    required this.approvedMerchants,
    required this.totalBaskets,
    required this.availableBaskets,
    required this.totalOrders,
    required this.pendingPayments,
    required this.paidOrders,
    required this.pickedUpOrders,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>? ?? {};
    final merchants = json['merchants'] as Map<String, dynamic>? ?? {};
    final baskets = json['baskets'] as Map<String, dynamic>? ?? {};
    final orders = json['orders'] as Map<String, dynamic>? ?? {};

    return AdminStats(
      totalUsers: _parseInt(users['total']),
      totalMerchants: _parseInt(merchants['total']),
      pendingMerchants: _parseInt(merchants['pending']),
      approvedMerchants: _parseInt(merchants['approved']),
      totalBaskets: _parseInt(baskets['total']),
      availableBaskets: _parseInt(baskets['available']),
      totalOrders: _parseInt(orders['total']),
      pendingPayments: _parseInt(orders['pendingPayment']),
      paidOrders: _parseInt(orders['paid']),
      pickedUpOrders: _parseInt(orders['pickedUp']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class AdminMerchant {
  final String id;
  final String businessName;
  final String? type;
  final String? address;
  final String? phoneNumber;
  final String status;
  final DateTime createdAt;
  final String? userEmail;
  final String? userName;
  final String? userPhone;

  AdminMerchant({
    required this.id,
    required this.businessName,
    this.type,
    this.address,
    this.phoneNumber,
    required this.status,
    required this.createdAt,
    this.userEmail,
    this.userName,
    this.userPhone,
  });

  factory AdminMerchant.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return AdminMerchant(
      id: json['id'],
      businessName: (json['businessName'] ?? '').toString(),
      type: json['type']?.toString(),
      address: json['address']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: DateTime.parse(json['createdAt']),
      userEmail: user?['email']?.toString(),
      userName: user?['displayName']?.toString(),
      userPhone: user?['phoneNumber']?.toString(),
    );
  }
}

class AdminUser {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String role;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      email: (json['email'] ?? '').toString(),
      displayName: json['displayName']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      role: (json['role'] ?? '').toString(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
