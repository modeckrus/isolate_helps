// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test.dart';

// **************************************************************************
// GrpcClassGenerator
// **************************************************************************

/*
[String hello]
*/

extension TestGrpc on Test {
//TypeWithPrefix (prefix = String ('o'); type = Type (Other*))

  o.Other toOther() {
/*
[String hello]
*/

    return o.Other(
      hello: hello,
    );
  }

//TypeWithPrefix (prefix = String ('o'); type = Type (Other*))
  void fromOther(o.Other input) {
/*
[String hello]
*/

    hello = input.hello;
  }
}
