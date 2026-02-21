class SubscribedPackageId {
  bool? status;
  String? message;
  Data? data;

  SubscribedPackageId({
    this.status,
    this.message,
    this.data,
  });

  SubscribedPackageId.fromJson(Map<String, dynamic> json) {
    status = json['status'] as bool?;
    message = json['message'] as String?;
    data = json['data'] != null
        ? Data.fromJson(json['data'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    json['status'] = status;
    json['message'] = message;
    if (data != null) {
      json['data'] = data!.toJson();
    }
    return json;
  }
}

/* ---------------- DATA (SUBSCRIBED PACKAGE) ---------------- */

class Data {
  int? packageId;
  String? paymentStatus;
  int? userId;
  String? status;
  String? subscriptionStartDate;
  int? totalAmount;
  String? subscriptionEndDate;
  PackageData? packageData;
  String? updatedAt;
  String? createdAt;
  int? id; // 👈 subscription_id (IMPORTANT)

  Data({
    this.packageId,
    this.paymentStatus,
    this.userId,
    this.status,
    this.subscriptionStartDate,
    this.totalAmount,
    this.subscriptionEndDate,
    this.packageData,
    this.updatedAt,
    this.createdAt,
    this.id,
  });

  Data.fromJson(Map<String, dynamic> json) {
    packageId = json['package_id'] as int?;
    paymentStatus = json['payment_status'] as String?;
    userId = json['user_id'] as int?;
    status = json['status'] as String?;
    subscriptionStartDate = json['subscription_start_date'] as String?;
    totalAmount = json['total_amount'] as int?;
    subscriptionEndDate = json['subscription_end_date'] as String?;
    packageData = json['package_data'] != null
        ? PackageData.fromJson(
            json['package_data'] as Map<String, dynamic>)
        : null;
    updatedAt = json['updated_at'] as String?;
    createdAt = json['created_at'] as String?;
    id = json['id'] as int?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    json['package_id'] = packageId;
    json['payment_status'] = paymentStatus;
    json['user_id'] = userId;
    json['status'] = status;
    json['subscription_start_date'] = subscriptionStartDate;
    json['total_amount'] = totalAmount;
    json['subscription_end_date'] = subscriptionEndDate;
    if (packageData != null) {
      json['package_data'] = packageData!.toJson();
    }
    json['updated_at'] = updatedAt;
    json['created_at'] = createdAt;
    json['id'] = id;
    return json;
  }
}

/* ---------------- PACKAGE DATA ---------------- */

class PackageData {
  int? id;
  String? packageType;
  String? name;
  String? durationUnit;
  int? duration;
  int? price;
  String? description;
  String? status;
  String? createdAt;
  String? updatedAt;

  PackageData({
    this.id,
    this.packageType,
    this.name,
    this.durationUnit,
    this.duration,
    this.price,
    this.description,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  PackageData.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    packageType = json['package_type'] as String?;
    name = json['name'] as String?;
    durationUnit = json['duration_unit'] as String?;
    duration = json['duration'] as int?;
    price = json['price'] as int?;
    description = json['description'] as String?;
    status = json['status'] as String?;
    createdAt = json['created_at'] as String?;
    updatedAt = json['updated_at'] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    json['id'] = id;
    json['package_type'] = packageType;
    json['name'] = name;
    json['duration_unit'] = durationUnit;
    json['duration'] = duration;
    json['price'] = price;
    json['description'] = description;
    json['status'] = status;
    json['created_at'] = createdAt;
    json['updated_at'] = updatedAt;
    return json;
  }
}
