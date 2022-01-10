import 'package:analyzer/dart/element/type.dart';
import 'package:async/async.dart';

/// Converts [Future], [Iterable], and [Stream] implementations
/// containing [String] to a single [Stream] while ensuring all thrown
/// exceptions are forwarded through the return value.
Stream<String> normalizeGeneratorOutput(Object? value) {
  if (value == null) {
    return const Stream.empty();
  } else if (value is Future) {
    return StreamCompleter.fromFuture(value.then(normalizeGeneratorOutput));
  } else if (value is String) {
    value = [value];
  }

  if (value is Iterable) {
    value = Stream.fromIterable(value);
  }

  if (value is Stream) {
    return value.where((e) => e != null).map((e) {
      if (e is String) {
        return e.trim();
      }

      throw _argError(e as Object);
    }).where((e) => e.isNotEmpty);
  }
  throw _argError(value);
}

ArgumentError _argError(Object value) => ArgumentError(
    'Must be a String or be an Iterable/Stream containing String values. '
    'Found `${Error.safeToString(value)}` (${value.runtimeType}).');

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
