import 'dart:convert';
import 'dart:io';
import 'package:campus_flutter/studiesComponent/service/public_course_service.dart';

Future<void> main(List<String> ids) async {
  if (ids.isEmpty) throw ArgumentError('Provide public TUMonline course IDs');
  final service = PublicCourseService();
  for (final input in ids) {
    final id = RegExp(r'^\d+$').hasMatch(input)
        ? input
        : await service.resolveCourseId(input);
    if (id == null) throw StateError('Could not resolve supplied course link');
    final result = await service.fetch(id, true, languageCode: 'en');
    final d = result.$2;
    stdout.writeln(
      jsonEncode({
        'id': d.id,
        'title': d.title,
        'semester': d.semester,
        'teachers': d.teachers,
        'sws': d.sws,
        'ects': d.ects,
        'hasContents': d.contents != null,
        'hasObjective': d.objective != null,
        'fetchedAt': result.$1.toIso8601String(),
      }),
    );
  }
}
