import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

List<Function(HttpRequest request, WebSocket webSocket)> wsListeners = [];

Future<void> runSocketServer() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 7658);
  print('WebSocket server is listening on port 7658');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
// 获取请求的方法、URI、HTTP 版本以及所有头部信息
      final method = request.method;
      final uri = request.uri;
      final httpVersion = request.protocolVersion;
      final headers = request.headers;

      print('Received\n${method} request for ${uri} (HTTP/${httpVersion}):');
      headers.forEach((name, values) {
        values.forEach((value) {
          print('$name: $value');
        });
      });

      // 升级HTTP连接为WebSocket连接
      WebSocket webSocket = await WebSocketTransformer.upgrade(request, compression: CompressionOptions.compressionOff);
      webSocket.pingInterval=const Duration(seconds: 5);
      // 处理WebSocket连接
      for (var element in wsListeners) {
        element.call(request, webSocket);
      }
    } else {
      // 处理普通HTTP请求
      handleHttpRequest(request);
    }
  }
}

void handleHttpRequest(HttpRequest request) {
  request.response
    ..statusCode = HttpStatus.notFound
    ..write('Not Found')
    ..close();
}

void shelfWS() {
  var handler = webSocketHandler((webSocket) {
    webSocket.stream.listen((message) {
      webSocket.sink.add("echo $message");
    });
  });

  shelf_io.serve(handler, 'localhost', 8080).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}
