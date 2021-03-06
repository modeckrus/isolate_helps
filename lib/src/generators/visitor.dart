import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:isolate_helps/src/generators/helper.dart';

import 'method_with_parameters.dart';

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
      List<Parameter> parametrsNames = [Parameter('port', false)];

      for (var parameter in method.parameters) {
        final type = parameter.type.getDisplayString(withNullability: true);
        String parameterName = parameter.displayName;

        if (parameterName == port) {
          parameterName = '\$$port';
        }
        parametrsNames.add(Parameter(parameterName, parameter.isNamed));
        parameters += 'final $type $parameterName;\n';
      }
      String typeName = '\$${name}${className}Isolate';
      typeName =
          typeName.replaceRange(1, 2, typeName.substring(1, 2).toUpperCase());
      final methodDisplayString =
          method.returnType.getDisplayString(withNullability: true);
      bool isReturnTypeStream = false;
      if (methodDisplayString.contains('Stream<')) {
        isReturnTypeStream = true;
      }
      methods[method.getDisplayString(withNullability: true)] =
          MethodWithParameters(
              className: typeName,
              parameters: parametrsNames,
              methodName: method.name,
              returnType: method.returnType,
              isReturnTypeStream: isReturnTypeStream,
              methodType: MethodType.method);

      newTypes.add(typeName);

      String string = 'class $typeName{\nfinal SendPort $port;\n$parameters';

      string += 'const $typeName({\n';
      for (var parametrName in parametrsNames) {
        string += 'required this.${parametrName.name},\n';
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
      List<Parameter> parametrsNames = [Parameter('port', false)];

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
          parametrsNames.add(Parameter(parameterName, parameter.isNamed));
          parameters += 'final $type $parameterName;\n';
        }
        final methodDisplayString =
            method.returnType.getDisplayString(withNullability: true);
        bool isReturnTypeStream = false;
        if (methodDisplayString.contains('Stream<')) {
          isReturnTypeStream = true;
        }
        methods[method.getDisplayString(withNullability: true)] =
            MethodWithParameters(
                className: typeName,
                parameters: parametrsNames,
                methodName: method.name,
                returnType: method.returnType,
                setter: parametrsNames[1],
                isReturnTypeStream: isReturnTypeStream,
                methodType: MethodType.setter);
      } else {
        final methodDisplayString =
            method.returnType.getDisplayString(withNullability: true);
        bool isReturnTypeStream = false;
        if (methodDisplayString.contains('Stream<')) {
          isReturnTypeStream = true;
        }
        methods[method.getDisplayString(withNullability: true)] =
            MethodWithParameters(
                className: typeName,
                parameters: parametrsNames,
                methodName: method.name,
                returnType: method.returnType,
                isReturnTypeStream: isReturnTypeStream,
                methodType: MethodType.getter);
      }

      newTypes.add(typeName);
      String string = 'class $typeName{\nfinal SendPort $port;\n$parameters';
      string += 'const $typeName({\n';

      for (var parametrName in parametrsNames) {
        string += 'required this.${parametrName.name},\n';
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
        if (parameter.name == port) {
          parameters += '${parameter.name}: ${parameter.name}.sendPort, ';
        } else {
          parameters += '${parameter.name}: ${parameter.name}, ';
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
      final returnName =
          value.returnType.getDisplayString(withNullability: true);
      if (value.isReturnTypeStream) {
        string += '''@override\n$declaration async*{
        \tReceivePort port = ReceivePort();
        \tsendPort.send(${value.className}($parameters));
        \tyield* port.asBroadcastStream().map((_\$mapEvent) {
      switch (_\$mapEvent.runtimeType) {
        case IsolateException:
          _\$mapEvent = _\$mapEvent as IsolateException;
          throw _\$mapEvent.exception;
        default:
          return _\$mapEvent;
      }
    });
        }
        ''';
      } else {
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
        \tvar result = await port.first;
        \tswitch (result.runtimeType) {
        \t\tcase IsolateException:
        \t\t\tresult = result as IsolateException;
        \t\t\tthrow result.exception;
        \t\tdefault:
        \t\t\treturn result;
        \t\t}
        }
        ''';
        }
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
        if (parameter.name != port) {
          if (parameter.isNamed) {
            parameters += '${parameter.name}: object.${parameter.name}, ';
          } else {
            parameters += 'object.${parameter.name}, ';
          }
        }
      }
      if (parameters.length > 2) {
        parameters = parameters.substring(0, parameters.length - 2);
      }
      string += '''case ${value.className}:
            \tobject = object as ${value.className};
            \ttry{''';
      switch (value.methodType) {
        case MethodType.method:
          string += '''
            \tfinal result = await instance${className}.${value.methodName}($parameters);
          ''';
          if (value.returnType.isVoid ||
              value.returnType.getDisplayString(withNullability: true) ==
                  'Future<void>') {
            string += '\n object.port.send(true);\n break;';
          } else if (value.isReturnTypeStream) {
            string += '''\nresult.listen((_\$resultEvent) {
          object.port.send(_\$resultEvent);
        });''';
          } else {
            string += '\n object.port.send(result);\n';
          }
          break;
        default:
      }
      if (value.methodType == MethodType.method) {
      } else if (value.methodType == MethodType.getter) {
        string += '''
      \tfinal result = await instance${className}.${value.methodName};
      \tobject.port.send(result);
      ''';
      } else if (value.methodType == MethodType.setter) {
        string += '''
      \tinstance${className}.${value.methodName} object.${value.setter};
      ''';
      }
      string += '''}catch(e){
      \t  object.port.send(IsolateException(e));
      }
      break;''';
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
