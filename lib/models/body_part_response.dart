import 'pagination_model.dart';

class BodyPartResponse {
  Pagination? pagination;
  List<BodyPartModel>? data;

  BodyPartResponse({this.pagination, this.data});

  BodyPartResponse.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;

    if (json['data'] != null) {
      data = <BodyPartModel>[];
      json['data'].forEach((v) {
        data!.add(BodyPartModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    if (pagination != null) {
      map['pagination'] = pagination!.toJson();
    }
    if (data != null) {
      map['data'] = data!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class BodyPartModel {
  int? id;
  String? title;
  String? status;
  String? description;       
  String? bodypartImage;
  String? createdAt;
  String? updatedAt;
  bool? select;

  BodyPartModel({
    this.id,
    this.title,
    this.status,
    this.description,
    this.bodypartImage,
    this.createdAt,
    this.updatedAt,
    this.select = false,
  });

  BodyPartModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    status = json['status'];
    description = json['description'];     
    bodypartImage = json['bodypart_image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    select = false; 
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['id'] = id;
    map['title'] = title;
    map['status'] = status;
    map['description'] = description;
    map['bodypart_image'] = bodypartImage;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['select'] = select;
    return map;
  }
}
