import '../../utils/ios_product_id_utils.dart';

class SubscriptionDietPlan {
  Pagination? pagination;
  List<Data>? data;

  SubscriptionDietPlan({this.pagination, this.data});

  SubscriptionDietPlan.fromJson(Map<String, dynamic> json) {
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
  String? packageType;
  String? name;
  int? duration;
  String? durationUnit;
  int? price;
  String? description;
  String? status;
  String? createdAt;
  String? updatedAt;
  List<String>? iosProductIds;

  Data(
      {this.id,
      this.packageType,
      this.name,
      this.duration,
      this.durationUnit,
      this.price,
      this.description,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.iosProductIds});

  Data.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    packageType = json['package_type']?.toString();
    name = json['name']?.toString();
    duration = _asInt(json['duration']);
    durationUnit = json['duration_unit']?.toString();
    price = _asInt(json['price']);
    description = json['description']?.toString();
    status = json['status']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    iosProductIds = _extractIosProductIds(json);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['package_type'] = this.packageType;
    data['name'] = this.name;
    data['duration'] = this.duration;
    data['duration_unit'] = this.durationUnit;
    data['price'] = this.price;
    data['description'] = this.description;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['ios_product_ids'] = this.iosProductIds;
    return data;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static List<String>? _extractIosProductIds(Map<String, dynamic> json) =>
      extractIosProductIds(json);
}
