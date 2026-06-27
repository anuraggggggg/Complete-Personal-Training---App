import '../utils/ios_product_id_utils.dart';

class SubscriptionIDModel {
  bool? status;
  String? message;
  Data? data;

  SubscriptionIDModel({this.status, this.message, this.data});

  SubscriptionIDModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

class Data {
  int? packageId;
  int? userId;
  String? status;
  String? subscriptionStartDate;
  int? totalAmount;
  String? subscriptionEndDate;
  PackageData? packageData;
  String? updatedAt;
  String? createdAt;
  int? id;
  List<String>? iosProductIds;

  Data(
      {this.packageId,
      this.userId,
      this.status,
      this.subscriptionStartDate,
      this.totalAmount,
      this.subscriptionEndDate,
      this.packageData,
      this.updatedAt,
      this.createdAt,
      this.id,
      this.iosProductIds});

  Data.fromJson(Map<String, dynamic> json) {
    packageId = _asInt(json['package_id']);
    userId = _asInt(json['user_id']);
    status = json['status']?.toString();
    subscriptionStartDate = json['subscription_start_date']?.toString();
    totalAmount = _asInt(json['total_amount']);
    subscriptionEndDate = json['subscription_end_date']?.toString();
    packageData = json['package_data'] != null
        ? new PackageData.fromJson(json['package_data'])
        : null;
    updatedAt = json['updated_at']?.toString();
    createdAt = json['created_at']?.toString();
    id = _asInt(json['id']);
    iosProductIds = _extractIosProductIds(json);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['package_id'] = this.packageId;
    data['user_id'] = this.userId;
    data['status'] = this.status;
    data['subscription_start_date'] = this.subscriptionStartDate;
    data['total_amount'] = this.totalAmount;
    data['subscription_end_date'] = this.subscriptionEndDate;
    if (this.packageData != null) {
      data['package_data'] = this.packageData!.toJson();
    }
    data['updated_at'] = this.updatedAt;
    data['created_at'] = this.createdAt;
    data['id'] = this.id;
    data['ios_product_ids'] = this.iosProductIds;
    return data;
  }
}

class PackageData {
  int? id;
  String? packageType;
  String? name;
  String? durationUnit;
  int? duration;
  int? price;
  String? description;
  String? status;
  bool? offerEnabled;
  String? offerType;
  int? offerAccessDays;
  Null? offerMaxRedemptions;
  int? offerSameAccessCount;
  int? offerFreeAccessCount;
  String? createdAt;
  String? updatedAt;
  List<String>? iosProductIds;
  String? razorpayPlanId;

  PackageData(
      {this.id,
      this.packageType,
      this.name,
      this.durationUnit,
      this.duration,
      this.price,
      this.description,
      this.status,
      this.offerEnabled,
      this.offerType,
      this.offerAccessDays,
      this.offerMaxRedemptions,
      this.offerSameAccessCount,
      this.offerFreeAccessCount,
      this.createdAt,
      this.updatedAt,
      this.iosProductIds,
      this.razorpayPlanId});

  PackageData.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    packageType = json['package_type']?.toString();
    name = json['name']?.toString();
    durationUnit = json['duration_unit']?.toString();
    duration = _asInt(json['duration']);
    price = _asInt(json['price']);
    description = json['description']?.toString();
    status = json['status']?.toString();
    offerEnabled = json['offer_enabled'];
    offerType = json['offer_type']?.toString();
    offerAccessDays = _asInt(json['offer_access_days']);
    offerMaxRedemptions = json['offer_max_redemptions'];
    offerSameAccessCount = _asInt(json['offer_same_access_count']);
    offerFreeAccessCount = _asInt(json['offer_free_access_count']);
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    iosProductIds = _extractIosProductIds(json);
    razorpayPlanId = _extractRazorpayPlanId(json);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['package_type'] = this.packageType;
    data['name'] = this.name;
    data['duration_unit'] = this.durationUnit;
    data['duration'] = this.duration;
    data['price'] = this.price;
    data['description'] = this.description;
    data['status'] = this.status;
    data['offer_enabled'] = this.offerEnabled;
    data['offer_type'] = this.offerType;
    data['offer_access_days'] = this.offerAccessDays;
    data['offer_max_redemptions'] = this.offerMaxRedemptions;
    data['offer_same_access_count'] = this.offerSameAccessCount;
    data['offer_free_access_count'] = this.offerFreeAccessCount;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['ios_product_ids'] = this.iosProductIds;
    data['razorpay_plan_id'] = this.razorpayPlanId;
    return data;
  }
}

List<String>? _extractIosProductIds(Map<String, dynamic> json) =>
    extractIosProductIds(json);

String? _extractRazorpayPlanId(Map<String, dynamic> json) {
  const keys = <String>[
    'razorpay_plan_id',
    'razorpay_subscription_plan_id',
    'razorpay_product_id',
    'android_product_id',
    'product_id',
    'plan_id',
  ];

  for (final key in keys) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }

  final packageData = json['package_data'];
  if (packageData is Map<String, dynamic>) {
    return _extractRazorpayPlanId(packageData);
  }

  return null;
}
