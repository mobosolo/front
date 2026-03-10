class MerchantDailyStats {
  final int basketsSoldToday;
  final int revenueToday;
  final int foodSavedKg;

  MerchantDailyStats({
    required this.basketsSoldToday,
    required this.revenueToday,
    required this.foodSavedKg,
  });

  factory MerchantDailyStats.fromJson(Map<String, dynamic> json) {
    return MerchantDailyStats(
      basketsSoldToday: _parseInt(json['basketsSoldToday']),
      revenueToday: _parseInt(json['revenueToday']),
      foodSavedKg: _parseInt(json['foodSavedKg']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
