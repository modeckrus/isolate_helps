import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:isolate_helps/src/generators/method_with_parameters.dart';

class GrpcVisitor extends SimpleElementVisitor {
  List<FieldElement> fields = [];
  bool deleteFinals = true;
  List<Parameter> parameters = [];
  @override
  visitClassElement(ClassElement element) {
    fields = element.fields
      ..removeWhere((field) {
        bool ok = field.isPublic;
        if (ok && deleteFinals) {
          ok = !field.isFinal;
        }
        return !ok;
      });
    return super.visitClassElement(element);
  }

  @override
  visitConstructorElement(ConstructorElement element) {
    if (element.isDefaultConstructor) {
      parameters = [];
    }
    if (parameters.length == 0) {}
    {
      element.parameters.forEach((parameter) {
        parameters.add(Parameter(parameter.displayName, parameter.isNamed));
        parameter.isNamed;
      });
    }
    return super.visitConstructorElement(element);
  }
}
