import 'package:campus_flutter/calendarComponent/model/calendar_event.dart';
import 'package:campus_flutter/studiesComponent/service/lecture_links.dart';
import 'package:campus_flutter/studiesComponent/viewModel/lecture_details_viewmodel.dart';
import 'package:campus_flutter/studiesComponent/model/public_course_details.dart';
import 'package:campus_flutter/studiesComponent/model/course_details_state.dart';
import 'package:campus_flutter/base/networking/apis/tumOnlineApi/tum_online_api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CalendarEvent event(String url) => CalendarEvent(
    id: '1',
    status: 'CONFIRMED',
    url: url,
    title: 'Calendar title',
    startDate: DateTime(2026),
    endDate: DateTime(2026),
    locations: ['Room'],
  );
  test('legacy query parsing does not include following parameters', () {
    expect(LectureLinks.lvNumber('?pLvNr=9502&language=en'), '9502');
    expect(LectureLinks.lvNumber('?pStpSpNr=1234'), isNull);
    expect(LectureLinks.lvNumber(null), isNull);
  });
  test('browser course and legacy IDs remain distinct; tokens are omitted', () {
    final page = LectureLinks.coursePage(
      calendarUrl:
          'https://campus.tum.de/tumonline/wbLv.wbShowLVDetail?pStpSpNr=1234&LvNr=9501&pToken=SECRET',
    )!;
    expect(page.fragment, '/slc.tm.cp/student/courses/1234');
    expect(page.toString(), isNot(contains('SECRET')));
    expect(LectureLinks.courseId(calendarUrl: '?LvNr=9501'), isNull);
  });
  test('real calendar cLvNr links identify the current course directly', () {
    for (final url in [
      'https://campus.tum.de/tumonline/lv.detail?cLvNr=950944244',
      'lv.detail?cLvNr=950944244&language=en',
      '/tumonline/lv.detail?cLvNr=950944244',
    ]) {
      expect(LectureLinks.courseId(calendarUrl: url), '950944244');
      expect(LectureLinks.lvNumber(url), '950944244');
      expect(
        LectureLinks.coursePage(calendarUrl: url)!.fragment,
        '/slc.tm.cp/student/courses/950944244',
      );
    }
    expect(
      LectureLinks.courseId(calendarUrl: '/tumonline/other?cLvNr=950944244'),
      isNull,
    );
  });
  test('external hosts and executable links are not course links', () {
    for (final url in [
      'javascript:alert(1)',
      'https://campus.tum.de.evil.test/tumonline/course',
      'http://campus.tum.de/tumonline/course',
      'https://user@campus.tum.de/tumonline/course',
    ]) {
      expect(LectureLinks.coursePage(calendarUrl: url), isNull);
    }
  });
  test('service outage remains distinct from missing permission', () {
    expect(
      TumOnlineApiException(
        tumOnlineApiExceptionType: TumOnlineApiExceptionUnknown(
          message: 'Veranstaltungsabruf temporär nicht möglich!',
        ),
      ).isLectureServiceUnavailable,
      isTrue,
    );
    expect(
      TumOnlineApiException(
        tumOnlineApiExceptionType: TumOnlineApiExceptionNoPermission(),
      ).isLectureServiceUnavailable,
      isFalse,
    );
  });
  test(
    'unresolved link produces only an error state without a course',
    () async {
      var called = false;
      final model = LectureDetailsViewModel(
        event: event('https://campus.tum.de/tumonline/course'),
        resolvePublicCourseId: (_) async => null,
        fetchPublicDetails: (_, _) async {
          called = true;
          throw StateError('unexpected');
        },
      );
      await model.fetch(false);
      expect(called, isFalse);
      expect(model.state.value.status, CourseDetailsStatus.failed);
      expect(model.state.value.error!.messageKey, 'courseLinkError');
      expect(model.state.value.details, isNull);
      model.dispose();
    },
  );
  test(
    'HTTP error is preserved rather than hidden by the disabled legacy API',
    () async {
      final model = LectureDetailsViewModel(
        event: event('pages/slc.tm.cp/course/950944244'),
        fetchPublicDetails: (id, forced) async {
          expect(id, '950944244');
          expect(forced, isTrue);
          throw DioException(
            requestOptions: RequestOptions(path: '/courses/$id'),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 403,
            ),
          );
        },
      );
      await model.fetch(true);
      expect(model.state.value.error!.statusCode, 403);
      expect(model.state.value.error!.messageKey, 'courseAccessError');
      expect(model.state.value.details, isNull);
      model.dispose();
    },
  );
  test(
    'mismatched ID is an error and never appears as course information',
    () async {
      final model = LectureDetailsViewModel(
        event: event('pages/slc.tm.cp/course/950944244'),
        fetchPublicDetails: (_, _) async => (
          DateTime(2026),
          const PublicCourseDetails(
            id: '950945432',
            title: 'Wrong course',
            teachers: [],
          ),
        ),
      );
      await model.fetch(false);
      expect(model.state.value.status, CourseDetailsStatus.failed);
      expect(model.state.value.error!.messageKey, 'courseIdentityError');
      expect(model.state.value.details, isNull);
      model.dispose();
    },
  );
  test('failed refresh removes previously loaded course data', () async {
    var calls = 0;
    final model = LectureDetailsViewModel(
      event: event('pages/slc.tm.cp/course/950944244'),
      fetchPublicDetails: (_, _) async {
        if (calls++ == 0) {
          return (
            DateTime(2026),
            const PublicCourseDetails(
              id: '950944244',
              title: 'Deutsch B1.1',
              teachers: [],
            ),
          );
        }
        throw const FormatException('bad response');
      },
    );
    await model.fetch(false);
    expect(model.state.value.status, CourseDetailsStatus.loaded);
    await model.fetch(true);
    expect(model.state.value.status, CourseDetailsStatus.failed);
    expect(model.state.value.details, isNull);
    model.dispose();
  });
}
