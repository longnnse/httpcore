library base_response;

class BaseResponse<T> {
  int? code;
  String? message;
  String? error;
  T? data;

  BaseResponse({this.code = 0, this.message = '', this.error = '', this.data});

  BaseResponse.fromJson(Map<String, dynamic> json,
      {String nameOfData = 'data'}) {
    code = json['code'];
    message = json['message'];
    error = json['error'];
    data = json[nameOfData];
  }
}

class BaseObjectResponse<T> {
  int? code;
  String? message;
  String? error;
  T? data;

  BaseObjectResponse(
      {this.code = 0, this.message = '', this.error = '', this.data});

  BaseObjectResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic> map) creator,
      {String nameOfData = 'data'}) {
    code = json['code'];
    message = json['message'];
    error = json['error'];
    data = json[nameOfData] == null ? null : creator(json[nameOfData]);
  }
}

class BaseListResponse<T> {
  int? code;
  String? message;
  String? error;
  List<T>? data;

  BaseListResponse(
      {this.code = 0, this.message = '', this.error = '', this.data});

  BaseListResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic> map) creator,
      {String nameOfData = 'data'}) {
    code = json['code'];
    message = json['message'];
    error = json['error'];
    if (json[nameOfData] == null) {
      data = null;
    } else {
      data = json[nameOfData].map<T>((e) => creator(e)).toList();
    }
  }
}
