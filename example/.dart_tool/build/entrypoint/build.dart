// ignore_for_file: directives_ordering
import 'package:build_runner_core/build_runner_core.dart' as _i1;
import 'package:build_test/builder.dart' as _i2;
import 'package:build_config/build_config.dart' as _i3;
import 'package:isolate_helps/builder.dart' as _i4;
import 'package:source_gen/builder.dart' as _i5;
import 'dart:isolate' as _i6;
import 'package:build_runner/build_runner.dart' as _i7;
import 'dart:io' as _i8;

final _builders = <_i1.BuilderApplication>[
  _i1.apply(
      r'build_test:test_bootstrap',
      [_i2.debugIndexBuilder, _i2.debugTestBuilder, _i2.testBootstrapBuilder],
      _i1.toRoot(),
      hideOutput: true,
      defaultGenerateFor:
          const _i3.InputSet(include: [r'$package$', r'test/**'])),
  _i1.apply(
      r'isolate_helps:isolate_builder', [_i4.isolateBuilder], _i1.toRoot(),
      hideOutput: false),
  _i1.apply(r'source_gen:combining_builder', [_i5.combiningBuilder],
      _i1.toNoneByDefault(),
      hideOutput: false, appliesBuilders: const [r'source_gen:part_cleanup']),
  _i1.applyPostProcess(r'source_gen:part_cleanup', _i5.partCleanup)
];
void main(List<String> args, [_i6.SendPort? sendPort]) async {
  var result = await _i7.run(args, _builders);
  sendPort?.send(result);
  _i8.exitCode = result;
}