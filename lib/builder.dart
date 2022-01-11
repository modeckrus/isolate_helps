import 'package:build/build.dart';
import 'package:isolate_helps/src/generators/grpc.dart';
import 'package:isolate_helps/src/generators/isolate_generator.dart';
import 'package:merging_builder/merging_builder.dart';
import 'package:source_gen/source_gen.dart';

Builder grpcBuilder(BuilderOptions options) {
  return SharedPartBuilder([GrpcClassGenerator()], 'grpcclass');
}

Builder isolateBuilder(BuilderOptions options) {
  final defaultOptions = BuilderOptions({
    'input_files': 'lib/*.dart',
    'output_files': 'lib/output/isolate_(*).dart',
    'header': IsolateGenerator.header,
    'footer': IsolateGenerator.footer,
    'root': ''
  });
  options = defaultOptions.overrideWith(options);
  return MergingBuilder<String, LibDir>(
    generator: IsolateGenerator(),
    inputFiles: options.config['input_files'],
    outputFile: options.config['output_file'],
    header: options.config['header'],
    footer: options.config['footer'],
    sortAssets: options.config['sort_assets'],
  );
}
