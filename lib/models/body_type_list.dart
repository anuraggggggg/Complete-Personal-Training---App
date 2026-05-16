class BodyPartTypeList {
  Pagination? pagination;
  List<BodyPartData> data;

  BodyPartTypeList({
    this.pagination,
    this.data = const [],
  });

  factory BodyPartTypeList.fromJson(Map<String, dynamic> json) {
    return BodyPartTypeList(
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      data: json['data'] != null
          ? List<BodyPartData>.from(
              json['data'].map((x) => BodyPartData.fromJson(x)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pagination': pagination?.toJson(),
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}
class Pagination {
  int? totalItems;
  int? perPage;
  int? currentPage;
  int? totalPages;

  Pagination({
    this.totalItems,
    this.perPage,
    this.currentPage,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalItems: json['total_items'],
      perPage: json['per_page'],
      currentPage: json['currentPage'],
      totalPages: json['totalPages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'per_page': perPage,
      'currentPage': currentPage,
      'totalPages': totalPages,
    };
  }
}
class BodyPartData {
  int? id;
  String? title;
  String? status;
  String? bodypartImage;
  String? createdAt;
  String? updatedAt;

  BodyPartData({
    this.id,
    this.title,
    this.status,
    this.bodypartImage,
    this.createdAt,
    this.updatedAt,
  });

  factory BodyPartData.fromJson(Map<String, dynamic> json) {
    return BodyPartData(
      id: json['id'],
      title: json['title'],
      status: json['status'],
      bodypartImage: json['bodypart_image'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'bodypart_image': bodypartImage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
