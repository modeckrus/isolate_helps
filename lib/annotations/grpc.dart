class GrpcClass {
  final List<TypeWithPrefix> from;
  final List<TypeWithPrefix> to;
  final String prefix;
  const GrpcClass({
    required this.from,
    required this.to,
    this.prefix = '',
  });
}

class TypeWithPrefix {
  final Type type;
  final String? prefix;

  const TypeWithPrefix({required this.type, this.prefix});
}
