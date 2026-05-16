class LanguageModel {
  String? status;
  String? message;
  List<Data>? data;

  LanguageModel({this.status, this.message, this.data});

  LanguageModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? id;
  int? languageId;
  String? languageName;
  String? languageCode;
  String? countryCode;
  Null? languageFlag;
  int? isRtl;
  int? isDefault;
  int? status;
  String? createdAt;
  String? updatedAt;

  Data(
      {this.id,
      this.languageId,
      this.languageName,
      this.languageCode,
      this.countryCode,
      this.languageFlag,
      this.isRtl,
      this.isDefault,
      this.status,
      this.createdAt,
      this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    languageId = json['language_id'];
    languageName = json['language_name'];
    languageCode = json['language_code'];
    countryCode = json['country_code'];
    languageFlag = json['language_flag'];
    isRtl = json['is_rtl'];
    isDefault = json['is_default'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['language_id'] = this.languageId;
    data['language_name'] = this.languageName;
    data['language_code'] = this.languageCode;
    data['country_code'] = this.countryCode;
    data['language_flag'] = this.languageFlag;
    data['is_rtl'] = this.isRtl;
    data['is_default'] = this.isDefault;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
