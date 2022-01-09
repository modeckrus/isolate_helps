import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:merging_builder/merging_builder.dart';
import 'package:quote_buffer/src/quote.dart';
import 'package:source_gen/src/constants/reader.dart';

import '../../researcher_builder.dart';
import 'visitor.dart';

class IsolateGenerator extends MergingGenerator<String, AbstractForIsolate> {
  static String get header {
    return '/// Isolate Header.';
  }

  static String get footer {
    return '/// Isolate Footer';
  }

  String modifyOutput(String input) {
    // return "\n/*\n" + input + "\n*/\n";
    return input;
  }

  @override
  FutureOr<String> generateMergedContent(Stream<String> stream) async {
    print('generateMergedContent');
    final b = StringBuffer();
    b.writeln('import \'dart:async\';');
    b.writeln('import \'dart:isolate\';');
    await for (final string in stream) {
      b.write(modifyOutput(string));
    }
    initialiseAndCases.forEach((isolateName, value) {
      final initialise = value.initializer;
      final cases = value.cases;
      String name = isolateName;
      String parseFunc = '''
Future<void> ${name}IsolateParser(SendPort sendPort) async {
  \tReceivePort receivePort = ReceivePort();
  \tsendPort.send(receivePort.sendPort);
  \t$initFunction
  \t$initialise
  \tawait for (var object in receivePort) {
  \tswitch (object.runtimeType) {
  \t$cases
''';
      parseFunc += '''
    default:
    }
  }
}
    ''';
      b.writeln('\n\n$parseFunc\n\n');
    });

    return b.toString();
  }

  String initFunction = '';

  @override
  String generateStreamItemForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    return abstractForIsolate(element, annotation, buildStep);
  }

  Map<String, InitializerAndCases> initialiseAndCases = {};
  String abstractForIsolate(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    var buffer = StringBuffer();
    print('Called abstractForIsolate');
    final isolateName = annotation.read('isolateName').stringValue;
    final isInitFunction = annotation.read('isInitFunction').boolValue;
    final instance = annotation.read('instance').stringValue;
    if (isInitFunction == true) {
      initFunction += instance + ';\n';
    } else {
      final visitor = MethodToClassesVisitor(
          className: element.displayName, instance: instance);
      element.accept(visitor);
      initialiseAndCases[isolateName] = InitializerAndCases(
          initializer: visitor.inisiliser, cases: visitor.cases);
      buffer.write('\n//Classes\n${visitor.result}\n');
      // buffer.write('\n//Cases\n${visitor.cases}\n');
      // buffer.write('\n//Initializers\n${visitor.inisiliser}\n');
      // if (element.)
    }
    return buffer.toString();
  }
}

class InitializerAndCases {
  final String initializer;
  final String cases;
  InitializerAndCases({
    required this.initializer,
    required this.cases,
  });
}