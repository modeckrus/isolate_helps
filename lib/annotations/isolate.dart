class AbstractForIsolate {
  final String isolateName;
  final String instance;
  final bool isInitFunction;
  const AbstractForIsolate(
      {required this.isolateName,
      required this.isInitFunction,
      required this.instance});
}

class InitFunctionInIsolate {
  final String isolateName;
  const InitFunctionInIsolate({
    required this.isolateName,
  });
}
