import 'package:isolate_helps/annotations/grpc.dart';
import 'other.dart' as o;
part 'test.g.dart';

@GrpcClass(
    from: [TypeWithPrefix(type: o.Other, prefix: 'o')],
    to: [TypeWithPrefix(type: o.Other, prefix: 'o')])
class Test {
  String hello;

  Test(this.hello);
}

Test fromOther(o.Other other) {
  return Test(other.hello);
}

extension TestGrpc on Test {
  void fromOther(o.Other request) {
    hello = request.hello;
  }

  o.Other toOther() {
    return o.Other(hello: hello);
  }
}
