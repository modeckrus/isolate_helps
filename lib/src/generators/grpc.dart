import 'package:analyzer/dart/constant/value.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:isolate_helps/annotations/grpc.dart';
import 'package:isolate_helps/src/generators/grpc_visitor.dart';
import 'package:source_gen/source_gen.dart';

class GrpcClassGenerator extends GeneratorForAnnotation<GrpcClass> {
  List<FieldElement> fields = [];
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    StringBuffer buffer = StringBuffer();
    GrpcVisitor visitor = GrpcVisitor();
    element.accept(visitor);
    fields = visitor.fields;
    buffer.writeln('\n/*\n$fields\n*/\n');
    visitor.deleteFinals = false;
    final name = element.displayName;
    buffer.writeln('extension ${name}Grpc on $name{');
    annotation.read('to').listValue.forEach((classElement) {
      buffer.writeln('//$classElement');
      buffer.writeln('/*\n');
      DartObject? typeField = classElement.getField('type');
      if (typeField == null) {
        return;
      }

      final type = typeField.toTypeValue();
      final prefixField = classElement.getField('prefix');
      String? prefix;
      if (prefixField != null) {
        prefix = prefixField.toStringValue();
      }
      if (type != null) {
        if (type.element != null) {
          final element = type.element!;
          String name = element.displayName;
          String prefixedName = name;
          if (prefix != null) {
            prefixedName = '$prefix.$prefixedName';
          }

          buffer.writeln('$prefixedName to$name(){');
          element.accept(visitor);
          element.visitChildren(visitor);
          buffer.writeln('\n/*\n${visitor.fields}\n*/\n');
          buffer.writeln('return $prefixedName(');
          visitor.parameters.forEach((parameter) {
            final name = parameter.name;
            if (parameter.isNamed) {
              buffer.writeln('$name: $name, ');
            } else {
              buffer.writeln('$name, ');
            }
          });
          buffer.writeln(');');
          buffer.writeln('}');
          buffer.writeln('\n*/');
        }
      }
    });
    annotation.read('from').listValue.forEach((classElement) {
      buffer.writeln('//$classElement');
      DartObject? typeField = classElement.getField('type');
      if (typeField == null) {
        return;
      }

      final type = typeField.toTypeValue();
      final prefixField = classElement.getField('prefix');
      String? prefix;
      if (prefixField != null) {
        prefix = prefixField.toStringValue();
      }
      if (type != null) {
        if (type.element != null) {
          final element = type.element!;
          String name = element.displayName;
          String prefixedName = name;
          if (prefix != null) {
            prefixedName = '$prefix.$prefixedName';
          }

          buffer.writeln('void from$name($prefixedName input){');
          element.accept(visitor);
          buffer.writeln('\n/*\n${visitor.fields}\n*/\n');
          visitor.fields.forEach((field) {
            for (var originalField in fields) {
              if (originalField.displayName == field.name) {
                buffer.writeln(
                    '${originalField.displayName} = input.${originalField.displayName};');
              }
            }
          });
          buffer.writeln('}');
        }
      }
    });
    buffer.writeln('}');
    return buffer.toString();
  }
}
