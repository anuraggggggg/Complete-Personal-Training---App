import '../../models/pagination_model.dart';

class EquipmentResponse {
  Pagination? pagination;
  List<EquipmentModel>? data;

  EquipmentResponse({this.pagination, this.data});

  EquipmentResponse.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null ? new Pagination.fromJson(json['pagination']) : null;
    if (json['data'] != null) {
      data = <EquipmentModel>[];
      json['data'].forEach((v) {
        data!.add(new EquipmentModel.fromJson(v));
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

class EquipmentModel {
  int? id;
  String? title;
  String? status;
  String? description; // json me nahi hai, future ke liye rehne do
  String? equipmentImage;
  String? createdAt;
  String? updatedAt;
  List<String>? workoutModes; // 👈 added field
  bool? isSelected = false;

  EquipmentModel({
    this.id,
    this.title,
    this.status,
    this.description,
    this.equipmentImage,
    this.createdAt,
    this.updatedAt,
    this.workoutModes,
  });

  EquipmentModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    status = json['status'];
    description = json['description'];
    equipmentImage = json['equipment_image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['workout_modes'] != null) {
      workoutModes = List<String>.from(json['workout_modes']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['status'] = status;
    data['description'] = description;
    data['equipment_image'] = equipmentImage;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (workoutModes != null) {
      data['workout_modes'] = workoutModes;
    }
    return data;
  }
}
