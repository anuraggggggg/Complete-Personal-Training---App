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
      this.id});

  Data.fromJson(Map<String, dynamic> json) {
    packageId = json['package_id'];
    userId = json['user_id'];
    status = json['status'];
    subscriptionStartDate = json['subscription_start_date'];
    totalAmount = json['total_amount'];
    subscriptionEndDate = json['subscription_end_date'];
    packageData = json['package_data'] != null
        ? new PackageData.fromJson(json['package_data'])
        : null;
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    id = json['id'];
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
      this.updatedAt});

  PackageData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    packageType = json['package_type'];
    name = json['name'];
    durationUnit = json['duration_unit'];
    duration = json['duration'];
    price = json['price'];
    description = json['description'];
    status = json['status'];
    offerEnabled = json['offer_enabled'];
    offerType = json['offer_type'];
    offerAccessDays = json['offer_access_days'];
    offerMaxRedemptions = json['offer_max_redemptions'];
    offerSameAccessCount = json['offer_same_access_count'];
    offerFreeAccessCount = json['offer_free_access_count'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
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
    return data;
  }
}
