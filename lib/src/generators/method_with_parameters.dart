import 'package:analyzer/dart/element/type.dart';

enum MethodType {
  method,
  getter,
  setter,
}

class MethodWithParameters {
  final String className;
  final List<Parameter> parameters;
  final String methodName;
  final DartType returnType;
  final MethodType methodType;
  Parameter? setter;
  MethodWithParameters(
      {required this.className,
      required this.parameters,
      required this.methodName,
      required this.returnType,
      required this.methodType,
      this.setter});
}

class Parameter {
  final String name;
  final bool isNamed;

  Parameter(this.name, this.isNamed);
}
