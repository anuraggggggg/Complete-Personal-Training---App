import '../utils/ios_product_id_utils.dart';

import '../models/pagination_model.dart';

class SubscriptionResponse {
  Pagination? pagination;
  List<SubscriptionModel>? data;

  SubscriptionResponse({this.pagination, this.data});

  SubscriptionResponse.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
    if (json['data'] != null) {
      data = <SubscriptionModel>[];
      json['data'].forEach((v) {
        data!.add(new SubscriptionModel.fromJson(v));
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

class SubscriptionModel {
  int? id;
  String? packageType;
  String? name;
  int? duration;
  String? durationUnit;
  num? price;
  String? description;
  String? status;
  String? createdAt;
  String? updatedAt;
  List<String>? iosProductIds;

  SubscriptionModel(
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

  SubscriptionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    packageType = json['package_type'];
    name = json['name'];
    duration = json['duration'];
    durationUnit = json['duration_unit'];
    price = json['price'];
    description = json['description'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
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

  static List<String>? _extractIosProductIds(Map<String, dynamic> json) =>
      extractIosProductIds(json);
}
