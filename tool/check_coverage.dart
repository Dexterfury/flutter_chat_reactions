import 'dart:io';

/// Fails (exit code 1) when line coverage in an lcov file is below a minimum.
///
/// Usage: dart run tool/check_coverage.dart `<minPercent>` [path/to/lcov.info]
void main(List<String> args) {
  final minimum = args.isEmpty ? 0.0 : double.parse(args[0]);
  final file = File(args.length > 1 ? args[1] : 'coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln('Coverage file not found: ${file.path}');
    exit(1);
  }

  var found = 0;
  var hit = 0;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('LF:')) {
      found += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit += int.parse(line.substring(3));
    }
  }

  final percent = found == 0 ? 100.0 : hit * 100 / found;
  stdout.writeln(
    'Line coverage: ${percent.toStringAsFixed(1)}% ($hit/$found lines), '
    'minimum ${minimum.toStringAsFixed(1)}%',
  );
  if (percent < minimum) {
    stderr.writeln('Coverage is below the minimum.');
    exit(1);
  }
}
