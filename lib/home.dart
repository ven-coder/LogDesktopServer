import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:app_connector/socket_server.dart';
import 'package:app_connector/ws_ctrl_page.dart';
import 'package:app_connector/ws_http_log.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'content_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() {
    return _Home();
  }
}

class _Home extends State<Home> with SingleTickerProviderStateMixin {
  List<String> _leftTabs = ["连接"];
  List<Widget> _bodys = [WSCtrlPage()];
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    wsListeners.add((request, webSocket) {
      setState(() {
        _leftTabs.add("${request.headers["model"]}");
        _bodys.add(ContentPage(
          request: request,
          webSocket: webSocket,
          wsClose: (ContentPage contentPage) {
            var index = _bodys.indexOf(contentPage);
            setState(() {
              _leftTabs.removeAt(index);
              _bodys.removeAt(index);
              if (_pageIndex >= index) {
                _pageIndex--;
              }
            });
          },
        ));
        _pageIndex++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        color: Colors.grey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 250,
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return InkWell(
                    child: Container(
                      color: _pageIndex == index ? Colors.blue : Colors.white,
                      height: 50,
                      alignment: Alignment.center,
                      child: Text(
                        _leftTabs[index],
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
                itemCount: _leftTabs.length,
              ),
            ),
            Expanded(
                child: Container(
              alignment: Alignment.topLeft,
              color: Colors.grey,
              child: IndexedStack(
                index: _pageIndex,
                children: _bodys,
              ),
            ))
          ],
        ),
      ),
    );
  }
}
