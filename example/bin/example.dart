import 'dart:io';
import 'dart:isolate';

import 'package:example/isolate_output/output.dart';

class CachePort {
  final SendPort port;

  CachePort(this.port);
}

class StartTest {}

void main() async {
  final Stopwatch timer = Stopwatch()..start();
  ReceivePort isolatedPort = ReceivePort();
  await Isolate.spawn<SendPort>(testIsolateParser, isolatedPort.sendPort);
  SendPort cachePort = await isolatedPort.first;
  ReceivePort testReceivePort = ReceivePort();
  await Isolate.spawn(testCache, testReceivePort.sendPort);
  SendPort testSendPort = await testReceivePort.first;
  testSendPort.send(CachePort(cachePort));
  testSendPort.send(StartTest());
  IsolateIInterface cache = IsolateIInterface(cachePort);
  await cache.helloWorld('Main');
  print('Exiting... ${timer.elapsed}');
}

void testCache(SendPort sendPort) async {
  ReceivePort port = ReceivePort();
  sendPort.send(port.sendPort);
  late IsolateIInterface cache;
  await for (var object in port) {
    switch (object.runtimeType) {
      case CachePort:
        SendPort cachePort = (object as CachePort).port;
        cache = IsolateIInterface(cachePort);
        break;
      case StartTest:
        cache.helloWorld('Isolate');
        break;
      default:
    }
  }
}
