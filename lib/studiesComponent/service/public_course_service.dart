import 'package:campus_flutter/studiesComponent/model/public_course_details.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:html/parser.dart' as html;
import 'package:campus_flutter/studiesComponent/service/lecture_links.dart';

class PublicCourseService {
  PublicCourseService({Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );
  static final instance = PublicCourseService();
  final Dio _client;
  final _cache = <(String, String), (DateTime, PublicCourseDetails)>{};
  final _resolvedCourses = <String, String>{};

  Future<String?> resolveCourseId(String url) async {
    final direct = LectureLinks.courseId(calendarUrl: url);
    if (direct != null) return direct;
    final uri = LectureLinks.campusUri(url);
    if (uri == null) return null;
    final path = uri.path.toLowerCase();
    final isMeeting =
        path == '/tumonline/!wbtermin.wbedit' ||
        path == '/tumonline/wbtermin.wbedit';
    final isLegacyCourse = path == '/tumonline/wblv.wbshowlvdetail';
    if (!isMeeting && !isLegacyCourse) return null;
    final query = <String, String>{};
    for (final entry in uri.queryParameters.entries) {
      final key = entry.key.toLowerCase();
      if ((isMeeting
              ? key == 'pterminnr'
              : const ['lvnr', 'plvnr'].contains(key)) &&
          RegExp(r'^\d{1,12}$').hasMatch(entry.value)) {
        query[isMeeting ? 'pTerminNr' : entry.key] = entry.value;
      }
    }
    if (query.isEmpty) return null;
    var requestUri = Uri.https(
      'campus.tum.de',
      isMeeting ? '/tumonline/!wbTermin.wbEdit' : uri.path,
      query,
    );
    final cacheKey = requestUri.toString();
    if (_resolvedCourses.containsKey(cacheKey)) {
      return _resolvedCourses[cacheKey];
    }
    for (var redirect = 0; redirect < 5; redirect++) {
      final response = await _client.get<String>(
        requestUri.toString(),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (code) => code != null && code >= 200 && code < 400,
          headers: {'Accept': 'text/html'},
        ),
      );
      if (response.statusCode != 200) {
        final location = response.headers.value('location');
        if (location == null) return null;
        final target = LectureLinks.campusUri(
          requestUri.resolve(location).toString(),
        );
        if (target == null) return null;
        final id = LectureLinks.courseId(calendarUrl: target.toString());
        if (id != null) {
          _saveResolution(cacheKey, id);
          return id;
        }
        requestUri = target;
        continue;
      }
      if (response.data == null) return null;
      final document = html.parse(response.data!);
      final primary = document.querySelector('a#idLvTitel')?.attributes['href'];
      if (primary != null) {
        final id = LectureLinks.courseId(
          calendarUrl: requestUri.resolve(primary).toString(),
        );
        if (id != null) {
          _saveResolution(cacheKey, id);
          return id;
        }
      }
      final candidates = document
          .querySelectorAll('a[href]')
          .map(
            (node) => LectureLinks.courseId(
              calendarUrl: requestUri
                  .resolve(node.attributes['href']!)
                  .toString(),
            ),
          )
          .whereType<String>()
          .toSet();
      if (candidates.length == 1) {
        final id = candidates.single;
        _saveResolution(cacheKey, id);
        return id;
      }
      return null;
    }
    return null;
  }

  void _saveResolution(String key, String id) {
    if (_resolvedCourses.length >= 128) {
      _resolvedCourses.remove(_resolvedCourses.keys.first);
    }
    _resolvedCourses[key] = id;
  }

  Future<(DateTime, PublicCourseDetails)> fetch(
    String id,
    bool forcedRefresh, {
    String? languageCode,
  }) async {
    if (!RegExp(r'^\d{1,12}$').hasMatch(id)) {
      throw const FormatException('Invalid public course ID');
    }
    final language =
        languageCode ?? Intl.getCurrentLocale().split(RegExp('[_-]')).first;
    final key = (id, language);
    final cached = _cache[key];
    if (!forcedRefresh &&
        cached != null &&
        DateTime.now().difference(cached.$1) < const Duration(hours: 6)) {
      return cached;
    }
    final response = await _client.get<String>(
      'https://campus.tum.de/tumonline/ee/rest/slc.tm.cp/student/courses/$id',
      options: Options(
        responseType: ResponseType.plain,
        followRedirects: false,
        headers: {'Accept': 'application/xml', 'Accept-Language': language},
      ),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw const FormatException('Invalid public course response');
    }
    final details = PublicCourseDetails.fromXml(
      response.data!,
      expectedId: id,
      languageCode: language,
    );
    final result = (DateTime.now(), details);
    if (_cache.length >= 128) _cache.remove(_cache.keys.first);
    _cache[key] = result;
    return result;
  }
}
