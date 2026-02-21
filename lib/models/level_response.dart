import 'pagination_model.dart';

class LevelResponse {
  Pagination? pagination;
  List<LevelModel>? data;

  LevelResponse({this.pagination, this.data});

  LevelResponse.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;

    if (json['data'] != null) {
      data = <LevelModel>[];
      json['data'].forEach((v) {
        data!.add(LevelModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (pagination != null) {
      data['pagination'] = pagination!.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class LevelModel {
  int? id;
  String? title;
  int? rate;
  String? status;
  String? levelImageUrl;   // <-- NEW FIELD ADDED
  String? levelImage;
  String? createdAt;
  String? updatedAt;

  /// UI selection flag
  bool select = false;

  LevelModel({
    this.id,
    this.title,
    this.rate,
    this.status,
    this.levelImageUrl,
    this.levelImage,
    this.createdAt,
    this.updatedAt,
  });

  LevelModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    rate = json['rate'];
    status = json['status'];
    levelImageUrl = json['level_image_url'];   // <-- NEW JSON KEY
    levelImage = json['level_image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];

    select = false; // always default
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['id'] = id;
    data['title'] = title;
    data['rate'] = rate;
    data['status'] = status;
    data['level_image_url'] = levelImageUrl;   // <-- NEW JSON KEY
    data['level_image'] = levelImage;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;

    return data;
  }
}
