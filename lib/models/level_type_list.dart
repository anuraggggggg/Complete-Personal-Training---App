class LevelTypeList {
  Pagination? pagination;
  List<LevelData>? data;

  LevelTypeList({this.pagination, this.data});

  LevelTypeList.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;

    if (json['data'] != null) {
      data = <LevelData>[];
      json['data'].forEach((v) {
        data!.add(LevelData.fromJson(v));
      });
    }
  }
}

class Pagination {
  int? totalItems;
  int? perPage;
  int? currentPage;
  int? totalPages;

  Pagination.fromJson(Map<String, dynamic> json) {
    totalItems = json['total_items'];
    perPage = json['per_page'];
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
  }
}

class LevelData {
  int? id;
  String? title;
  int? rate;
  String? status;
  String? levelImage;
  String? createdAt;
  String? updatedAt;

  LevelData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    rate = json['rate'];
    status = json['status'];
    levelImage = json['level_image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
}
