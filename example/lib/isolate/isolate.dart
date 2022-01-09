import 'package:isolate_helps/annotations/isolate.dart';

@AbstractForIsolate(
    isolateName: 'test', isInitFunction: false, instance: 'IsolateImpl()')
abstract class IsolateI {
  Future<void> helloWorld(String from);
}

@AbstractForIsolate(
    isolateName: 'test', isInitFunction: true, instance: 'initFunction()')
void initFunction() {}

class IsolateImpl extends IsolateI {
  @override
  Future<void> helloWorld(String from) async {
    print('Helo world from $from');
  }
}
