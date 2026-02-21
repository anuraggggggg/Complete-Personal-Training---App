// ==============================
// Get Setting API Response Model
// ==============================

class GetSettingResponse {
  List<SettingList>? data;
  CurrencySetting? currencySetting;

  GetSettingResponse({
    this.data,
    this.currencySetting,
  });

  GetSettingResponse.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null && json['data'] is List) {
      data = <SettingList>[];
      for (var v in json['data']) {
        data!.add(SettingList.fromJson(v));
      }
    }

    currencySetting = json['currency_setting'] != null
        ? CurrencySetting.fromJson(json['currency_setting'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonData = {};
    if (data != null) {
      jsonData['data'] = data!.map((v) => v.toJson()).toList();
    }
    if (currencySetting != null) {
      jsonData['currency_setting'] = currencySetting!.toJson();
    }
    return jsonData;
  }
}

// ==============================
// Single Setting Item Model
// ==============================

class SettingList {
  int? id;
  String? key;
  String? type;
  String? value;

  SettingList({
    this.id,
    this.key,
    this.type,
    this.value,
  });

  SettingList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    key = json['key'];
    type = json['type'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonData = {};
    jsonData['id'] = id;
    jsonData['key'] = key;
    jsonData['type'] = type;
    jsonData['value'] = value;
    return jsonData;
  }
}

// ==============================
// Currency Setting Model
// ==============================

class CurrencySetting {
  String? name;
  String? symbol;
  String? code;
  String? position;

  CurrencySetting({
    this.name,
    this.symbol,
    this.code,
    this.position,
  });

  CurrencySetting.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    symbol = json['symbol'];
    code = json['code'];
    position = json['position'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonData = {};
    jsonData['name'] = name;
    jsonData['symbol'] = symbol;
    jsonData['code'] = code;
    jsonData['position'] = position;
    return jsonData;
  }
}
