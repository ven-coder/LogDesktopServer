import 'dart:io';

import 'package:app_connector/home.dart';
import 'package:app_connector/socket_server.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WSCtrlPage extends StatefulWidget {
  const WSCtrlPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _WSCtrlPage();
  }
}

class _WSCtrlPage extends State<WSCtrlPage> {
  String _ipAddress = "";

  @override
  void initState() {
    super.initState();
    getIpAddress();
  }

  void getIpAddress() {
    NetworkInterface.list().then((List<NetworkInterface> interfaces) {
      interfaces.forEach((interface) {
        print('接口名称: ${interface.name}');
        if (interface.name == "WLAN") {
          interface.addresses.forEach((address) {
            print('IP 地址: ${address.address}');
            setState(() {
              _ipAddress = address.address;
            });
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "扫码或输入IP进行连接",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 50,
            ),
            QrImageView(
              data: _ipAddress,
              version: QrVersions.auto,
              size: 300,
            ),
            const SizedBox(
              height: 50,
            ),
            Text("IP:$_ipAddress", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}
