class GameResponse {
  Pagination? pagination;
  List<GameResponseData>? data;

  GameResponse({this.pagination, this.data});

  GameResponse.fromJson(Map<String, dynamic> json) {
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
    if (json['data'] != null) {
      data = <GameResponseData>[];
      json['data'].forEach((v) {
        data!.add(new GameResponseData.fromJson(v));
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

class GameResponseData {
  int? userId;
  String? userName;
  int? score;
  String? countryCode;
  String? flagUrl;

  GameResponseData(
      {this.userId, this.userName, this.score, this.countryCode, this.flagUrl});

  GameResponseData.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    userName = json['user_name'];
    score = json['score'];
    countryCode = json['country_code'];
    flagUrl = json['flag_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['user_name'] = this.userName;
    data['score'] = this.score;
    data['country_code'] = this.countryCode;
    data['flag_url'] = this.flagUrl;
    return data;
  }
}
