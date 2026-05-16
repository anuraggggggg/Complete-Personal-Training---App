class InvoiceGeneratedModel {
  bool? status;
  String? message;
  Data? data;
  List<OfferCoupon>? offerCoupon;

  InvoiceGeneratedModel(
      {this.status, this.message, this.data, this.offerCoupon});

  InvoiceGeneratedModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    if (json['offer_coupon'] != null) {
      offerCoupon = <OfferCoupon>[];
      json['offer_coupon'].forEach((v) {
        offerCoupon!.add(new OfferCoupon.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    if (this.offerCoupon != null) {
      data['offer_coupon'] = this.offerCoupon!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? userId;
  int? subscriptionId;
  int? packageId;
  String? razorpayPaymentId;
  int? amount;
  String? status;
  String? currency;
  String? updatedAt;
  String? createdAt;
  int? id;

  Data(
      {this.userId,
      this.subscriptionId,
      this.packageId,
      this.razorpayPaymentId,
      this.amount,
      this.status,
      this.currency,
      this.updatedAt,
      this.createdAt,
      this.id});

  Data.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    subscriptionId = json['subscription_id'];
    packageId = json['package_id'];
    razorpayPaymentId = json['razorpay_payment_id'];
    amount = json['amount'];
    status = json['status'];
    currency = json['currency'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['subscription_id'] = this.subscriptionId;
    data['package_id'] = this.packageId;
    data['razorpay_payment_id'] = this.razorpayPaymentId;
    data['amount'] = this.amount;
    data['status'] = this.status;
    data['currency'] = this.currency;
    data['updated_at'] = this.updatedAt;
    data['created_at'] = this.createdAt;
    data['id'] = this.id;
    return data;
  }
}

class OfferCoupon {
  String? code;
  String? type;
  int? accessDays;
  int? maxRedemptions;

  OfferCoupon({this.code, this.type, this.accessDays, this.maxRedemptions});

  OfferCoupon.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    type = json['type'];
    accessDays = json['access_days'];
    maxRedemptions = json['max_redemptions'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    data['type'] = this.type;
    data['access_days'] = this.accessDays;
    data['max_redemptions'] = this.maxRedemptions;
    return data;
  }
}
