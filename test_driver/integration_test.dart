import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final output =
        Platform.environment['COURSE_ANDROID_SCREENSHOTS'] ??
        'build/android-screenshots';
    await Directory(output).create(recursive: true);
    await File('$output/$name.png').writeAsBytes(bytes);
    return true;
  },
);
