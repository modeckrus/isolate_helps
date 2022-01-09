import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:async/async.dart';
import 'helper.dart';

const String port = 'port';

class MethodToClassesVisitor extends SimpleElementVisitor {
  String result = '';
  String inisiliser = '';
  String cases = '';
  final String className;
  final String instance;
  List<String> newTypes = [];
  Map<String, MethodWithParameters> methods = {};
  MethodToClassesVisitor({required this.className, required this.instance});
  void generateClassesForMethods(List<MethodElement> elementMethods) {
    for (var method in elementMethods) {
      //Generate Class for Method with SendPort in Argument
      final name = method.name;
      String parameters = '';
      List<String> parametrsNames = ['port'];

      for (var parameter in method.parameters) {
        final type = parameter.type.getDisplayString(withNullability: true);
        String parameterName = parameter.displayName;

        if (parameterName == port) {
          parameterName = '\$$port';
        }
        parametrsNames.add(parameterName);
        parameters += 'final $type $parameterName;\n';
      }
      String typeName = '\$${name}${className}Isolate';
      typeName =
          typeName.replaceRange(1, 2, typeName.substring(1, 2).toUpperCase());
      methods[method.getDisplayString(withNullability: true)] =
          MethodWithParameters(
              className: typeName,
              parameters: parametrsNames,
              methodName: method.name,
              returnType: method.returnType,
              methodType: MethodType.method);

      newTypes.add(typeName);

      String string = 'class $typeName{\nfinal SendPort $port;\n$parameters';

      string += 'const $typeName({\n';
      for (var parametrName in parametrsNames) {
        string += 'required this.$parametrName,\n';
      }
      string += '});\n}\n';
      result += string;
    }
  }

  void generateClassesForAccesses(List<PropertyAccessorElement> accessors) {
    for (var method in accessors) {
      //Generate Class for Method with SendPort in Argument
      String name = method.name;
      name = name.replaceAll('=', '');
      String parameters = '';
      List<String> parametrsNames = ['port'];

      String typeName = '\$$name${className}Isolate';
      typeName =
          typeName.replaceRange(1, 2, typeName.substring(1, 2).toUpperCase());
      if (method.isSetter) {
        for (var parameter in method.parameters) {
          final type = parameter.type.getDisplayString(withNullability: true);
          String parameterName = parameter.displayName.replaceAll('=', '');
          if (parameterName == port) {
            parameterName = '\$$port';
          }
          parametrsNames.add(parameterName);
          parameters += 'final $type $parameterName;\n';
        }
        methods[method.getDisplayString(withNullability: true)] =
            MethodWithParameters(
                className: typeName,
                parameters: parametrsNames,
                methodName: method.name,
                returnType: method.returnType,
                setter: parametrsNames[1],
                methodType: MethodType.setter);
      } else {
        methods[method.getDisplayString(withNullability: true)] =
            MethodWithParameters(
                className: typeName,
                parameters: parametrsNames,
                methodName: method.name,
                returnType: method.returnType,
                methodType: MethodType.getter);
      }

      newTypes.add(typeName);
      String string = 'class $typeName{\nfinal SendPort $port;\n$parameters';
      string += 'const $typeName({\n';

      for (var parametrName in parametrsNames) {
        string += 'required this.$parametrName,\n';
      }

      string += '});\n}\n';
      result += string;
    }
  }

  void generateInterface() {
    String string = '';
    string =
        'class ${className}Interface extends ${className}{\nSendPort sendPort;\n${className}Interface(this.sendPort);\n';
    methods.forEach((declaration, value) {
      String parameters = '';
      for (var parameter in value.parameters) {
        if (parameter == port) {
          parameters += '$parameter: $parameter.sendPort, ';
        } else {
          parameters += '$parameter: $parameter, ';
        }
      }
      parameters = parameters.substring(0, parameters.length - 2);
      var declarationStr = declaration.split('(');
      if (declarationStr.length >= 2) {
        var declarationParameters = declarationStr[1];

        declarationParameters =
            declarationParameters.replaceAll(' $port', ' \$$port');
        declarationStr[1] = declarationParameters;
        declaration = declarationStr.join('(');
      }
      if (value.methodType == MethodType.setter) {
        string += '''@override\n$declaration{
        \tReceivePort port = ReceivePort();
        \tsendPort.send(${value.className}($parameters));
        }
        ''';
      } else {
        string += '''@override\n$declaration async{
        \tReceivePort port = ReceivePort();
        \tsendPort.send(${value.className}($parameters));
        \treturn await port.first;
        }
        ''';
      }
    });
    string += '}\n';
    result += string;
  }

  void generateCases() {
    String string = '';
    inisiliser = '''
    final $className instance${className} = $instance;
    ''';
    methods.forEach((declaration, value) {
      String parameters = '';
      for (var parameter in value.parameters) {
        if (parameter != port) {
          parameters += 'object.$parameter, ';
        }
      }
      if (parameters.length > 2) {
        parameters = parameters.substring(0, parameters.length - 2);
      }
      switch (value.methodType) {
        case MethodType.method:
          string += '''case ${value.className}:
            \tobject = object as ${value.className};
            \tfinal result = await instance${className}.${value.methodName}($parameters);
          ''';
          if (value.returnType.isVoid ||
              value.returnType.getDisplayString(withNullability: true) ==
                  'Future<void>') {
            string += '\n object.port.send(true);\n break;';
          } else {
            string += '\n object.port.send(result);\n break;';
          }
          break;
        default:
      }
      if (value.methodType == MethodType.method) {
      } else if (value.methodType == MethodType.getter) {
        string += '''case ${value.className}:
      \tobject = object as ${value.className};
      \tfinal result = await instance${className}.${value.methodName};
      \tobject.port.send(result);
      \tbreak;
      ''';
      } else if (value.methodType == MethodType.setter) {
        string += '''case ${value.className}:
      \tobject = object as ${value.className};
      \tinstance${className}.${value.methodName} object.${value.setter};
      \tbreak;
      ''';
      }
    });
    cases += string;
  }

  @override
  ClassElement? visitClassElement(ClassElement element) {
    final elementMethods = element.methods;
    generateClassesForMethods(elementMethods);
    final accessors = element.accessors;
    generateClassesForAccesses(accessors);
    generateCases();
    generateInterface();
    return super.visitClassElement(element);
  }
}
