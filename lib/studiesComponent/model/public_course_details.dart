import 'package:html/parser.dart' as html;
import 'package:xml/xml.dart';

/// Public website DTO; its course ID is not a legacy API LvNr.
class PublicCourseDetails {
  const PublicCourseDetails({
    required this.id,
    required this.title,
    required this.teachers,
    this.courseCode,
    this.semester,
    this.organisation,
    this.courseType,
    this.language,
    this.sws,
    this.ects,
    this.contents,
    this.objective,
    this.requirements,
    this.teachingMethod,
    this.assessment,
    this.note,
  });

  final String id;
  final String title;
  final List<String> teachers;
  final String? courseCode, semester, organisation, courseType, language;
  final String? sws, ects, contents, objective, requirements;
  final String? teachingMethod, assessment, note;

  factory PublicCourseDetails.fromXml(
    String body, {
    required String expectedId,
    String languageCode = 'en',
  }) {
    final document = XmlDocument.parse(body);
    final detail = document.descendants
        .whereType<XmlElement>()
        .where((node) => node.name.local == 'cpCourseDetailDto')
        .firstOrNull;
    final course = detail?.getElement('cpCourseDto');
    final id = course?.getElement('id')?.innerText.trim();
    if (course == null || id != expectedId) {
      throw const FormatException('Missing or mismatched public course ID');
    }
    String? text(XmlElement? node) {
      if (node == null) return null;
      final value = node.innerText.trim();
      if (value.isEmpty) return null;
      return html
          .parseFragment(
            value
                .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                .replaceAll(
                  RegExp(r'</(p|div|li)>', caseSensitive: false),
                  '\n',
                ),
          )
          .text
          ?.trim();
    }

    String? localized(XmlElement? node) {
      if (node == null) return null;
      final translations = node
          .getElement('translations')
          ?.findElements('translation');
      final preferred = translations
          ?.where((value) => value.getAttribute('lang') == languageCode)
          .firstOrNull;
      return text(preferred) ??
          text(node.getElement('value')) ??
          translations?.map(text).whereType<String>().firstOrNull;
    }

    String? norm(String key) => course
        .findElements('courseNormConfigs')
        .where((node) => node.getElement('key')?.innerText == key)
        .map((node) => text(node.getElement('value')))
        .whereType<String>()
        .firstOrNull;
    final title = localized(course.getElement('courseTitle'));
    if (title == null || title.isEmpty) {
      throw const FormatException('Missing public course title');
    }
    final description = detail!.getElement('cpCourseDescriptionDto');
    final teachers = course
        .findElements('lectureships')
        .map((node) {
          final identity = node.getElement('identityLibDto');
          return [
            text(identity?.getElement('firstName')),
            text(identity?.getElement('lastName')),
          ].whereType<String>().join(' ');
        })
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    return PublicCourseDetails(
      id: id!,
      title: title,
      teachers: List.unmodifiable(teachers),
      courseCode: text(
        course.getElement('courseNumber')?.getElement('courseNumber'),
      ),
      semester: localized(
        course.getElement('semesterDto')?.getElement('semesterDesignation'),
      ),
      organisation: localized(
        course.getElement('organisationResponsibleDto')?.getElement('name'),
      ),
      courseType: localized(
        course.getElement('courseTypeDto')?.getElement('courseTypeName'),
      ),
      language: course
          .findElements('courseLanguageDtos')
          .map(
            (node) =>
                localized(node.getElement('languageDto')?.getElement('name')),
          )
          .whereType<String>()
          .toSet()
          .join(', ')
          .nullIfEmpty,
      sws: norm('SST'),
      ects: norm('ECTS'),
      contents: localized(description?.getElement('courseContent')),
      objective: localized(description?.getElement('courseObjective')),
      requirements: localized(description?.getElement('previousKnowledge')),
      teachingMethod: localized(description?.getElement('teachingMethod')),
      assessment: localized(description?.getElement('assessmentScheme')),
      note: localized(description?.getElement('additionalInformation')),
    );
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
