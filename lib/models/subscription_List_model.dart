class SubscriptionList {
  Pagination? pagination;
  List<Data>? data;

  SubscriptionList({this.pagination, this.data});

  SubscriptionList.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Pagination {
  int? totalItems;
  int? perPage;
  int? currentPage;
  int? totalPages;

  Pagination(
      {this.totalItems, this.perPage, this.currentPage, this.totalPages});

  Pagination.fromJson(Map<String, dynamic> json) {
    totalItems = json['total_items'];
    perPage = json['per_page'];
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_items'] = this.totalItems;
    data['per_page'] = this.perPage;
    data['currentPage'] = this.currentPage;
    data['totalPages'] = this.totalPages;
    return data;
  }
}

class Data {
  int? id;
  int? userId;
  String? userName;
  int? packageId;
  String? packageName;
  int? totalAmount;
  String? paymentType;
  Null? txnId;
  Null? transactionDetail;
  String? paymentStatus;
  String? status;
  PackageData? packageData;
  String? subscriptionStartDate;
  String? subscriptionEndDate;
  String? createdAt;
  String? updatedAt;

  Data(
      {this.id,
      this.userId,
      this.userName,
      this.packageId,
      this.packageName,
      this.totalAmount,
      this.paymentType,
      this.txnId,
      this.transactionDetail,
      this.paymentStatus,
      this.status,
      this.packageData,
      this.subscriptionStartDate,
      this.subscriptionEndDate,
      this.createdAt,
      this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    userName = json['user_name'];
    packageId = json['package_id'];
    packageName = json['package_name'];
    totalAmount = json['total_amount'];
    paymentType = json['payment_type'];
    txnId = json['txn_id'];
    transactionDetail = json['transaction_detail'];
    paymentStatus = json['payment_status'];
    status = json['status'];
    packageData = json['package_data'] != null
        ? new PackageData.fromJson(json['package_data'])
        : null;
    subscriptionStartDate = json['subscription_start_date'];
    subscriptionEndDate = json['subscription_end_date'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['user_name'] = this.userName;
    data['package_id'] = this.packageId;
    data['package_name'] = this.packageName;
    data['total_amount'] = this.totalAmount;
    data['payment_type'] = this.paymentType;
    data['txn_id'] = this.txnId;
    data['transaction_detail'] = this.transactionDetail;
    data['payment_status'] = this.paymentStatus;
    data['status'] = this.status;
    if (this.packageData != null) {
      data['package_data'] = this.packageData!.toJson();
    }
    data['subscription_start_date'] = this.subscriptionStartDate;
    data['subscription_end_date'] = this.subscriptionEndDate;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
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
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
