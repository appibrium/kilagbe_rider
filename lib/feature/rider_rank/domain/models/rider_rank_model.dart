class RiderRankModel {
  RiderRankTierModel? currentTier;
  RiderRankTierModel? nextTier;
  int? thisMonthOrderCount;
  int? thisMonthFastDeliveryCount;
  int? lifetimeRatingCount;
  int? fastDeliveryMinutes;
  List<RiderRankTierModel>? allTiers;

  RiderRankModel({
    this.currentTier,
    this.nextTier,
    this.thisMonthOrderCount,
    this.thisMonthFastDeliveryCount,
    this.lifetimeRatingCount,
    this.fastDeliveryMinutes,
    this.allTiers,
  });

  RiderRankModel.fromJson(Map<String, dynamic> json) {
    currentTier = json['current_tier'] != null ? RiderRankTierModel.fromJson(json['current_tier']) : null;
    nextTier = json['next_tier'] != null ? RiderRankTierModel.fromJson(json['next_tier']) : null;
    thisMonthOrderCount = json['this_month'] != null ? json['this_month']['order_count'] : 0;
    thisMonthFastDeliveryCount = json['this_month'] != null ? json['this_month']['fast_delivery_count'] : 0;
    lifetimeRatingCount = json['lifetime_rating_count'];
    fastDeliveryMinutes = json['fast_delivery_minutes'];
    if (json['all_tiers'] != null) {
      allTiers = <RiderRankTierModel>[];
      json['all_tiers'].forEach((v) {
        allTiers!.add(RiderRankTierModel.fromJson(v));
      });
    }
  }
}

class RiderRankTierModel {
  int? id;
  String? name;
  String? badge;
  int? sequence;
  int? monthlyOrderTarget;
  int? monthlyFastDeliveryTarget;
  int? ratingCountTarget;

  RiderRankTierModel({
    this.id,
    this.name,
    this.badge,
    this.sequence,
    this.monthlyOrderTarget,
    this.monthlyFastDeliveryTarget,
    this.ratingCountTarget,
  });

  RiderRankTierModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    badge = json['badge'];
    sequence = json['sequence'];
    monthlyOrderTarget = json['monthly_order_target'];
    monthlyFastDeliveryTarget = json['monthly_fast_delivery_target'];
    ratingCountTarget = json['rating_count_target'];
  }
}
