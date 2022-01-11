import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:isolate_helps/annotations/isolate.dart';
import 'package:isolate_helps/src/generators/visitor.dart';
import 'package:merging_builder/merging_builder.dart';
import 'package:source_gen/src/constants/reader.dart';

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

    final after = b.toString();
    b.clear();
    for (var importStr in imports) {
      b.writeln('import \'package:$importStr\';');
    }
    b.write(after);
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
  List<String> imports = [];

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
    if (element.source?.uri.path != null) {
      final path = element.source!.uri.path;
      bool needAdd = true;
      imports.forEach((element) {
        if (element == path) {
          needAdd = false;
        }
      });
      if (needAdd) {
        imports.add(path);
      }
    }
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
