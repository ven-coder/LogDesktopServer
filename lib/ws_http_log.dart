// To parse this JSON data, do
//
//     final httpLog = httpLogFromJson(jsonString);

import 'dart:convert';

HttpLog httpLogFromJson(String str) => HttpLog.fromJson(json.decode(str));

String httpLogToJson(HttpLog data) => json.encode(data.toJson());

class HttpLog {
  String cmd;
  Data data;
  bool isExpandRequest = false;
  bool isExpandCurl = false;

  HttpLog({
    required this.cmd,
    required this.data,
  });

  factory HttpLog.fromJson(Map<String, dynamic> json) => HttpLog(
        cmd: json["cmd"],
        data: Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "cmd": cmd,
        "data": data.toJson(),
      };
}

class Data {
  String uuid;
  String? request;
  String? response;
  String? curl;
  String? url;

  Data({
    required this.uuid,
    this.request,
    this.response,
    this.curl,
    this.url,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        uuid: json["uuid"],
        request: json["request"],
        response: json["response"],
        curl: json["curl"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "uuid": uuid,
        "request": request,
        "response": response,
        "curl": curl,
        "url": url,
      };
}
