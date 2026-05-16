class GetCoupons {
  bool? status;
  int? subscriptionId;
  List<CouponData>? data;

  GetCoupons({this.status, this.subscriptionId, this.data});

  GetCoupons.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    subscriptionId = json['subscription_id'];
    if (json['data'] != null) {
      data = <CouponData>[];
      json['data'].forEach((v) {
        data!.add(new CouponData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['subscription_id'] = this.subscriptionId;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CouponData {
  int? id;
  String? code;
  String? type;
  dynamic value;
  int? accessDays;
  int? maxRedemptions;
  int? redemptionsCount;
  int? remainingRedemptions;
  dynamic validFrom;
  dynamic validTo;
  String? status;
  String? description;

  CouponData({
    this.id,
    this.code,
    this.type,
    this.value,
    this.accessDays,
    this.maxRedemptions,
    this.redemptionsCount,
    this.remainingRedemptions,
    this.validFrom,
    this.validTo,
    this.status,
    this.description,
  });

  CouponData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    type = json['type'];
    value = json['value'];
    accessDays = json['access_days'];
    maxRedemptions = json['max_redemptions'];
    redemptionsCount = json['redemptions_count'];
    remainingRedemptions = json['remaining_redemptions'];
    validFrom = json['valid_from'];
    validTo = json['valid_to'];
    status = json['status'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['code'] = this.code;
    data['type'] = this.type;
    data['value'] = this.value;
    data['access_days'] = this.accessDays;
    data['max_redemptions'] = this.maxRedemptions;
    data['redemptions_count'] = this.redemptionsCount;
    data['remaining_redemptions'] = this.remainingRedemptions;
    data['valid_from'] = this.validFrom;
    data['valid_to'] = this.validTo;
    data['status'] = this.status;
    data['description'] = this.description;
    return data;
  }
}
