import 'dart:io';
import 'package:campus_flutter/calendarComponent/model/calendar_event.dart';
import 'package:campus_flutter/studiesComponent/model/public_course_details.dart';
import 'package:campus_flutter/studiesComponent/model/course_details_state.dart';
import 'package:campus_flutter/studiesComponent/service/lecture_links.dart';
import 'package:campus_flutter/studiesComponent/service/navigatum_links.dart';
import 'package:campus_flutter/studiesComponent/service/public_course_service.dart';
import 'package:campus_flutter/studiesComponent/viewModel/lecture_details_viewmodel.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/xml_decoder.dart';

void main() {
  test(
    'calendar XML cLvNr reaches public details without the removed legacy page',
    () async {
      final events = CalendarEvents.fromJson(
        tumXmlToJson(
          File('test/fixtures/calendar_clvnr.xml').readAsStringSync(),
        ),
      ).events;
      for (final event in events) {
        final id = LectureLinks.courseId(calendarUrl: event.url)!;
        var requests = 0;
        final client = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests++;
                expect(
                  options.uri.path,
                  '/tumonline/ee/rest/slc.tm.cp/student/courses/$id',
                );
                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: File(
                      'test/fixtures/public_course_$id.xml',
                    ).readAsStringSync(),
                  ),
                );
              },
            ),
          );
        final service = PublicCourseService(client: client);
        final model = LectureDetailsViewModel(
          event: event,
          fetchPublicDetails: (id, forced) => service.fetch(id, forced),
          resolvePublicCourseId: (_) =>
              throw StateError('cLvNr needs no HTML fetch'),
        );
        await model.fetch(true);
        expect(model.state.value.status, CourseDetailsStatus.loaded);
        expect(model.state.value.details!.id, id);
        expect(model.state.value.details!.contents, isNotEmpty);
        expect(requests, 1);
        model.dispose();
      }
    },
  );
  test(
    'B1.1 course preserves the actual semester, teaching team and syllabus',
    () {
      final d = PublicCourseDetails.fromXml(
        File('test/fixtures/public_course_950944244.xml').readAsStringSync(),
        expectedId: '950944244',
      );
      expect(d.id, '950944244');
      expect(d.title, contains('B1.1'));
      expect(d.semester, contains('2026/27'));
      expect(d.teachers, [
        'Terezija Grgic',
        'Claudia Hanke',
        'Matthias Heiligensetzer',
        'Maria Karsten-Ott',
        'Inese Keza',
      ]);
      expect(d.requirements, contains('A2.2'));
      expect(d.contents, isNotEmpty);
      expect(d.ects, isNull);
      expect(
        LectureLinks.courseId(
          calendarUrl:
              'https://campus.tum.de/tumonline/ee/ui/ca2/app/desktop/#/slc.tm.cp/student/courses/950944244?\$scrollTo=toc_overview',
        ),
        '950944244',
      );
      expect(
        LectureLinks.courseId(calendarUrl: 'pages/slc.tm.cp/course/950944244'),
        '950944244',
      );
    },
  );
  test(
    'legacy link is resolved by an explicit official redirect, not by assuming an ID',
    () async {
      final client = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(options.method, 'GET');
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 302,
                  headers: Headers.fromMap({
                    'location': [
                      'https://campus.tum.de/tumonline/ee/ui/ca2/app/desktop/#/slc.tm.cp/student/courses/950944244',
                    ],
                  }),
                ),
              );
            },
          ),
        );
      expect(
        await PublicCourseService(
          client: client,
        ).resolveCourseId('wbLv.wbShowLVDetail?LvNr=123'),
        '950944244',
      );
    },
  );
  test(
    'NavigaTUM searches use the full room code and encode free text safely',
    () {
      final uri = NavigaTumLinks.search(
        '1639, Vortragsraum/Seminarraum (5506.01.639)',
      );
      expect(uri.toString(), 'https://nav.tum.de/search?q=5506.01.639');
      expect(
        NavigaTumLinks.search(
          'Boltzmannstraße 15 & room 1639',
        ).queryParameters['q'],
        'Boltzmannstraße 15 & room 1639',
      );
      expect(NavigaTumLinks.search('Online').host, 'nav.tum.de');
    },
  );
  test('user meeting maps to its actual course without submitting a form', () async {
    var requests = 0;
    final client = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests++;
            expect(options.method, 'GET');
            expect(options.uri.queryParameters, {'pTerminNr': '893029371'});
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data:
                    '<a href="pages/slc.tm.cp/course/950945432" id="idLvTitel">Hyperschallströmungen</a>'
                    '<a href="pages/slc.tm.cp/course/999">Other unrelated link</a>',
              ),
            );
          },
        ),
      );
    final service = PublicCourseService(client: client);
    expect(
      await service.resolveCourseId(
        'https://campus.tum.de/tumonline/!wbTermin.wbEdit?pTerminNr=893029371&pToken=ignored',
      ),
      '950945432',
    );
    expect(
      await service.resolveCourseId(
        'https://campus.tum.de/tumonline/!wbTermin.wbEdit?pTerminNr=893029371',
      ),
      '950945432',
    );
    expect(
      await service.resolveCourseId(
        'https://evil.test/tumonline/!wbTermin.wbEdit?pTerminNr=1',
      ),
      isNull,
    );
    expect(requests, 1);
  });
  test('actual user course restores German syllabus when English is empty', () {
    final d = PublicCourseDetails.fromXml(
      File('test/fixtures/public_course_950945432.xml').readAsStringSync(),
      expectedId: '950945432',
    );
    expect(d.title, contains('Hypersonic'));
    expect(d.contents, contains('Boltzmann'));
    expect(d.objective, contains('Gaskinetik'));
    expect(d.requirements, contains('Thermodynamik'));
    expect(d.teachingMethod, contains('Vorlesung'));
    expect(d.teachers, ['Christian Stemmer']);
    expect(d.ects, isNull);
  });
  final body = File(
    'test/fixtures/public_course_950940213.xml',
  ).readAsStringSync();
  test(
    'real public response maps English title, contents, teachers and SWS',
    () {
      final details = PublicCourseDetails.fromXml(
        body,
        expectedId: '950940213',
      );
      expect(details.title, 'Basics of silvicultural planning');
      expect(details.semester, 'Winter semester 2026/27');
      expect(details.teachers, ['Thomas Knoke', 'Bernhard Felbermeier']);
      expect(details.sws, '1');
      expect(details.ects, isNull); // SWS must never be relabeled as credits.
      expect(details.contents, contains('Analysis of stands'));
      expect(
        details.objective,
        contains('operational and strategical planning'),
      );
      expect(details.requirements, isNull);
    },
  );
  test(
    'requested language and missing course content are handled explicitly',
    () {
      expect(
        PublicCourseDetails.fromXml(
          body,
          expectedId: '950940213',
          languageCode: 'de',
        ).title,
        startsWith('Grundlagen der waldbaulichen'),
      );
      final sparse = PublicCourseDetails.fromXml(
        File('test/fixtures/public_course_950940221.xml').readAsStringSync(),
        expectedId: '950940221',
      );
      expect(sparse.contents, isNull);
      expect(sparse.id, '950940221');
    },
  );
  test('wrong ID, HTML login page and XML error do not become a course', () {
    for (final invalid in [
      body,
      '<html>Sign in</html>',
      '<error>Unavailable</error>',
    ]) {
      expect(
        () => PublicCourseDetails.fromXml(invalid, expectedId: '999'),
        throwsFormatException,
      );
    }
  });
  test('public course IDs use validated website links, never the legacy LvNr', () {
    expect(
      LectureLinks.courseId(
        calendarUrl:
            'https://campus.tum.de/tumonline/wbLv.wbShowLVDetail?pStpSpNr=950940213&LvNr=123',
      ),
      '950940213',
    );
    expect(
      LectureLinks.courseId(
        calendarUrl:
            'https://campus.tum.de/tumonline/ee/ui/ca2/app/desktop/#/slc.tm.cp/student/courses/950940213?x=y',
      ),
      '950940213',
    );
    expect(
      LectureLinks.courseId(
        calendarUrl:
            'https://campus.tum.de/tumonline/ee/rest/slc.tm.cp/student/courses/950940213',
      ),
      '950940213',
    );
    expect(
      LectureLinks.courseId(
        calendarUrl: 'https://campus.tum.de/tumonline/course?LvNr=950940213',
      ),
      isNull,
    );
    expect(
      LectureLinks.courseId(
        calendarUrl: 'https://evil.test/tumonline/course?pStpSpNr=950940213',
      ),
      isNull,
    );
  });
  test(
    'public requests send no app token and cache per language; refresh bypasses cache',
    () async {
      var requests = 0;
      final client = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests++;
              expect(options.uri.host, 'campus.tum.de');
              expect(options.uri.queryParameters, isEmpty);
              expect(
                options.headers.keys.map((key) => key.toLowerCase()),
                isNot(contains('authorization')),
              );
              expect(options.followRedirects, isFalse);
              handler.resolve(
                Response(requestOptions: options, data: body, statusCode: 200),
              );
            },
          ),
        );
      final service = PublicCourseService(client: client);
      final first = await service.fetch('950940213', false, languageCode: 'en');
      expect(
        (await service.fetch('950940213', false, languageCode: 'en')).$1,
        first.$1,
      );
      expect(requests, 1);
      await service.fetch('950940213', false, languageCode: 'de');
      await service.fetch('950940213', true, languageCode: 'en');
      expect(requests, 3);
      await expectLater(
        service.fetch('../secret', false),
        throwsFormatException,
      );
      expect(requests, 3);
    },
  );
  test(
    'viewmodel loads public details without calling the disabled legacy API',
    () async {
      final model = LectureDetailsViewModel(
        event: CalendarEvent(
          id: '1',
          status: 'CONFIRMED',
          url:
              'https://campus.tum.de/tumonline/wbLv.wbShowLVDetail?pStpSpNr=950940213&LvNr=123',
          startDate: DateTime(2026),
          endDate: DateTime(2026),
          locations: [],
        ),
        fetchPublicDetails: (id, forced) async {
          expect(id, '950940213');
          expect(forced, isTrue);
          return (
            DateTime(2026, 10, 19),
            PublicCourseDetails.fromXml(body, expectedId: id),
          );
        },
      );
      await model.fetch(true);
      expect(
        model.state.value.details!.contents,
        contains('Analysis of stands'),
      );
      expect(model.state.value.status, CourseDetailsStatus.loaded);
      expect(model.state.value.fetchedAt, DateTime(2026, 10, 19));
      model.dispose();
    },
  );
}
