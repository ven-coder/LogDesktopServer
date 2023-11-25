import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_connector/socket_server.dart';
import 'package:app_connector/ws_http_log.dart';
import 'package:flutter/material.dart';

class ContentPage extends StatefulWidget {
  WebSocket webSocket;
  HttpRequest request;
  Function(ContentPage widget) wsClose;

  ContentPage({super.key, required this.request, required this.webSocket, required this.wsClose});

  @override
  State<StatefulWidget> createState() {
    return _ContentPage();
  }
}

class _ContentPage extends State<ContentPage> {
  List<HttpLog> _apiListData = [];
  List<Map<String, dynamic>> _socketListData = [];
  List<String> _topTabs = ["Api", "Socket"];
  int _pageIndex = 0;
  ScrollController _scrollController = ScrollController();
  ScrollController _apiScrollController = ScrollController();
  ScrollController _scScrollController = ScrollController();
  ScrollController _scSearchScrollController = ScrollController();
  bool _isApiScrolling = false;
  bool _isStopReceiveApiLog = false;
  bool _isStopReceiveSocketLog = false;
  bool _isStopScrollApiLog = false;
  final TextEditingController _apiSearchCtr = TextEditingController();
  String _apiSearchKey = "";
  String _socketSearchKey = "";
  List<HttpLog> _apiSearchData = [];
  List<Map<String, dynamic>> _socketSearchData = [];

  @override
  void dispose() {
    super.dispose();
    _apiSearchCtr.dispose();
  }

  @override
  void initState() {
    super.initState();
    var model = widget.request.headers["model"] ?? "";
    widget.webSocket.listen((dynamic message) {
      print("$model-message:" + message);
      receiveHttp(message);
      receiveSocket(message);
    }, onDone: () {
      print("$model-onDone");
      widget.wsClose.call(widget);
    }, onError: (error) {
      print("$model-error:$error");
    });
  }

  void receiveSocket(dynamic message) {
    if (_isStopReceiveSocketLog) return;
    var data = jsonDecode(message);
    var cmd = data["cmd"];
    if (cmd != "WS_SOCKET_LOG") return;
    setState(() {
      var messageData = jsonDecode(data["data"] ?? {});
      var command = messageData["command"];
      if (_socketListData.length >= 200) _socketListData.removeAt(0);
      if (command == null) {
        _socketListData.insert(0, {"command": "未知类型", "value": data["data"] ?? "None"});
      } else {
        _socketListData.insert(0, {"command": command, "value": data["data"] ?? "None"});
      }
      if (_socketSearchKey.isNotEmpty) socketSearch(_socketSearchKey);
    });
  }

  void receiveHttp(dynamic message) {
    if (!_isStopReceiveApiLog) {
      var data = jsonDecode(message);
      if (data["cmd"] != "WS_HTTP_LOG") return;
      var httpLog = HttpLog.fromJson(data);
      setState(() {
        for (var element in _apiListData) {
          if (element.data.uuid == httpLog.data.uuid) {
            element.data.request = httpLog.data.request;
            element.data.response = httpLog.data.response;
            if (_apiSearchKey.isNotEmpty) apiSearch(_apiSearchKey);
            return;
          }
        }
        if (_apiListData.length >= 200) _apiListData.removeAt(0);
        _apiListData.insert(0, httpLog);
        if (_apiSearchKey.isNotEmpty) apiSearch(_apiSearchKey);
      });
    }
  }

  void scrollApiBottom() {
    // if (_isApiScrolling || _isStopScrollApiLog) return;
    if (_isStopScrollApiLog) return;
    _isApiScrolling = true;
    Timer(const Duration(milliseconds: 250), () {
      _isApiScrolling = false;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void apiSearch(String key) {
    _apiSearchData.clear();
    for (var element in _apiListData) {
      if (element.data.request != null) {
        if (element.data.request!.contains(key)) {
          _apiSearchData.add(element);
        }
      }
    }
  }

  void socketSearch(String key) {
    _socketSearchData.clear();
    for (var element in _socketListData) {
      if (element["value"] != null) {
        if (element["value"]!.contains(key)) {
          _socketSearchData.add(element);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.white,
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return InkWell(
                child: Container(
                  alignment: Alignment.center,
                  width: 100,
                  color: _pageIndex == index ? Colors.green : Colors.white70,
                  child: Text(
                    _topTabs[index],
                    style: TextStyle(color: _pageIndex == index ? Colors.white : Colors.black),
                  ),
                ),
                onTap: () {
                  setState(() {
                    _pageIndex = index;
                  });
                },
              );
            },
            itemCount: _topTabs.length,
          ),
        ),
        Expanded(
            child: Container(
          color: Colors.white70,
          alignment: Alignment.center,
          child: IndexedStack(
            index: _pageIndex,
            children: [
              //http
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _apiSearchCtr,
                          decoration: InputDecoration(labelText: "搜索"),
                          onChanged: (text) {
                            setState(() {
                              _apiSearchKey = text;
                              apiSearch(text);
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isStopScrollApiLog = !_isStopScrollApiLog;
                            });
                          },
                          child: Text(_isStopScrollApiLog ? "继续接收" : "停止接收")),
                      SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _apiListData.clear();
                              _apiSearchData.clear();
                            });
                          },
                          child: Text("清除")),
                      SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                  Expanded(
                      child: Stack(
                    children: [
                      Visibility(
                          visible: _apiSearchKey.isEmpty,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("共${_apiListData.length}条记录"),
                              Expanded(
                                  child: ListView.builder(
                                controller: _scrollController,
                                itemBuilder: (context, index) {
                                  return Container(
                                    padding: EdgeInsets.only(left: 10, right: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _apiListData[index].isExpandRequest = !_apiListData[index].isExpandRequest;
                                                  });
                                                },
                                                child: Text("${_apiListData.length - index}.${_apiListData[index].data.url}")),
                                            TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _apiListData[index].isExpandCurl = !_apiListData[index].isExpandCurl;
                                                  });
                                                },
                                                child: Text("curl")),
                                            SizedBox(
                                              height: 20,
                                            )
                                          ],
                                        ),
                                        Visibility(
                                            visible: _apiListData[index].isExpandCurl,
                                            child: SelectableText("CURL>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>CURL\n"
                                                "${_apiListData[index].data.curl}}\n"
                                                "CURL<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<CURL\n\n")),
                                        Visibility(
                                            visible: _apiListData[index].isExpandRequest,
                                            child: SelectableText("REQUEST>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>REQUEST\n"
                                                "${_apiListData[index].data.request}\n${_apiListData[index].data.response}"
                                                "RESPONSE<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<RESPONSE"))
                                      ],
                                    ),
                                  );
                                },
                                itemCount: _apiListData.length,
                              ))
                            ],
                          )),
                      Visibility(
                          visible: _apiSearchKey.isNotEmpty,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("搜索结果：${_apiSearchData.length}条"),
                              Expanded(
                                  child: ListView.builder(
                                controller: _apiScrollController,
                                itemBuilder: (context, index) {
                                  return Container(
                                    padding: EdgeInsets.only(left: 10, right: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _apiSearchData[index].isExpandRequest =
                                                        !_apiSearchData[index].isExpandRequest;
                                                  });
                                                },
                                                child:
                                                    Text("${_apiSearchData.length - index}.${_apiSearchData[index].data.url}")),
                                            TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _apiSearchData[index].isExpandCurl = !_apiSearchData[index].isExpandCurl;
                                                  });
                                                },
                                                child: Text("curl"))
                                          ],
                                        ),
                                        Visibility(
                                            visible: _apiSearchData[index].isExpandCurl,
                                            child: SelectableText("CURL>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>CURL\n"
                                                "${_apiSearchData[index].data.curl}}\n"
                                                "CURL<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<CURL\n\n")),
                                        Visibility(
                                            visible: _apiSearchData[index].isExpandRequest,
                                            child: SelectableText("REQUEST>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>REQUEST\n"
                                                "${_apiSearchData[index].data.request}\n${_apiSearchData[index].data.response}"
                                                "RESPONSE<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<RESPONSE"))
                                      ],
                                    ),
                                  );
                                },
                                itemCount: _apiSearchData.length,
                              ))
                            ],
                          ))
                    ],
                  ))
                ],
              ),
              //socket
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _apiSearchCtr,
                          decoration: InputDecoration(labelText: "搜索"),
                          onChanged: (text) {
                            setState(() {
                              _socketSearchKey = text;
                              socketSearch(text);
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isStopReceiveSocketLog = !_isStopReceiveSocketLog;
                            });
                          },
                          child: Text(_isStopReceiveSocketLog ? "继续接收" : "停止接收")),
                      SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _socketListData.clear();
                              _socketSearchData.clear();
                            });
                          },
                          child: Text("清除")),
                      SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                  Expanded(
                      child: Stack(
                    children: [
                      Visibility(
                          visible: _socketSearchKey.isEmpty,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("共${_socketListData.length}条记录"),
                              Expanded(
                                  child: ListView.builder(
                                controller: _scScrollController,
                                itemBuilder: (context, index) {
                                  return Container(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _socketListData[index]["isVisibleValue"] =
                                                    !(_socketListData[index]["isVisibleValue"] ?? false);
                                              });
                                            },
                                            child:
                                                Text("${_socketListData.length - index}.${_socketListData[index]["command"]}")),
                                        Visibility(
                                            visible: _socketListData[index]["isVisibleValue"] ?? false,
                                            child: SelectableText(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
                                                "${_socketListData[index]["value"]}\n"
                                                "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"))
                                      ],
                                    ),
                                  );
                                },
                                itemCount: _socketListData.length,
                              ))
                            ],
                          )),
                      Visibility(
                          visible: _socketSearchKey.isNotEmpty,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("搜索结果：${_socketSearchData.length}条"),
                              Expanded(
                                  child: ListView.builder(
                                controller: _scSearchScrollController,
                                itemBuilder: (context, index) {
                                  return Container(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _socketSearchData[index]["isVisibleValue"] =
                                                    !(_socketSearchData[index]["isVisibleValue"] ?? false);
                                              });
                                            },
                                            child: Text(
                                                "${_socketSearchData.length - index}.${_socketSearchData[index]["command"]}")),
                                        Visibility(
                                            visible: _socketSearchData[index]["isVisibleValue"] ?? false,
                                            child: SelectableText(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
                                                "${_socketSearchData[index]["value"]}\n"
                                                "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"))
                                      ],
                                    ),
                                  );
                                },
                                itemCount: _socketSearchData.length,
                              ))
                            ],
                          ))
                    ],
                  ))
                ],
              ),
            ],
          ),
        ))
      ],
    );
  }
}
