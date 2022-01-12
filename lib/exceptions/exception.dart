class IsolateException {
  final Object exception;

  IsolateException(this.exception);
}

class UnkownMessageType implements Exception {
  const UnkownMessageType() : super();
}
